#!/bin/bash

set -eux

BASE_PATH=~
KAYOBE_BRANCH=${kayobe_branch}
KAYOBE_CONFIG_BRANCH=${kayobe_config_branch}
KAYOBE_AIO_LVM=${use_lvm}
KAYOBE_CONFIG_EDIT_PAUSE=${allow_config_edit}
AIO_RUN_TEMPEST=${run_tempest}

if [[ ! -f $BASE_PATH/vault-pw ]]; then
    echo "Vault password file not found at $BASE_PATH/vault-pw"
    exit 1
fi

if sudo vgdisplay | grep -q lvm2; then
   sudo pvresize $(sudo pvs --noheadings | head -n 1 | awk '{print $1}')
   sudo lvextend -L 4G /dev/rootvg/lv_home -r || true
   sudo lvextend -L 4G /dev/rootvg/lv_tmp -r || true
elif $KAYOBE_AIO_LVM; then
   echo "This environment is only designed for LVM images. If possible, switch to an LVM image.
   To ignore this warning, set KAYOBE_AIO_LVM to false in this script."
   exit 1
fi

if type dnf; then
    sudo dnf -y install git
else
    sudo apt update
    sudo apt -y install gcc git libffi-dev python3-dev python-is-python3 python3-venv
fi

curl https://raw.githubusercontent.com/stackhpc/beokay/master/beokay.py | python3 - create --base-path $BASE_PATH/deployment \
    --kayobe-repo https://github.com/stackhpc/kayobe.git \
    --kayobe-branch $KAYOBE_BRANCH \
    --kayobe-config-repo https://github.com/stackhpc/stackhpc-kayobe-config.git \
    --kayobe-config-env-name ci-aio \
    --kayobe-config-branch $KAYOBE_CONFIG_BRANCH \
    --vault-password-file $BASE_PATH/vault-pw

if $KAYOBE_CONFIG_EDIT_PAUSE; then
   echo "Deployment is paused, edit configuration in another terminal"
   echo "Press enter to continue"
   read -s
fi

if ! sudo vgdisplay | grep -q lvm2; then
   rm $BASE_PATH/deployment/src/kayobe-config/etc/kayobe/environments/ci-aio/inventory/group_vars/controllers/lvm.yml
   sed -i -e '/controller_lvm_groups/,+2d' $BASE_PATH/deployment/src/kayobe-config/etc/kayobe/environments/ci-aio/controllers.yml
fi

if ! ip l show breth1 >/dev/null 2>&1; then
    sudo ip l add breth1 type bridge
fi
sudo ip l set breth1 up
if ! ip a show breth1 | grep 192.168.33.3/24; then
    sudo ip a add 192.168.33.3/24 dev breth1
fi
if ! ip l show dummy1 >/dev/null 2>&1; then
    sudo ip l add dummy1 type dummy
fi
sudo ip l set dummy1 up
sudo ip l set dummy1 master breth1

set +u
source $BASE_PATH/deployment/venvs/kayobe/bin/activate
set -u

export KAYOBE_VAULT_PASSWORD=$(cat $BASE_PATH/vault-pw)
pushd $BASE_PATH/deployment/src/kayobe-config
source kayobe-env --environment ci-aio

kayobe control host bootstrap

kayobe playbook run etc/kayobe/ansible/growroot.yml etc/kayobe/ansible/purge-command-not-found.yml

kayobe overcloud host configure

kayobe overcloud service deploy

if $AIO_RUN_TEMPEST; then
    pushd $BASE_PATH/deployment/src/kayobe-config
    git submodule init
    git submodule update
    sudo DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=rockylinux:9 --file .automation/docker/kayobe/Dockerfile --tag kayobe:latest --network host .
    export KAYOBE_AUTOMATION_SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa)
    mkdir -p tempest-artifacts
    sudo -E docker run --name kayobe-automation --detach -it --rm --network host \
    -v $(pwd):/stack/kayobe-automation-env/src/kayobe-config -v $(pwd)/tempest-artifacts:/stack/tempest-artifacts \
    -e KAYOBE_ENVIRONMENT -e KAYOBE_VAULT_PASSWORD -e KAYOBE_AUTOMATION_SSH_PRIVATE_KEY kayobe:latest \
    /stack/kayobe-automation-env/src/kayobe-config/.automation/pipeline/tempest.sh -e ansible_user=stack
    sleep 300
    sudo docker logs -f tempest
else
    export KAYOBE_CONFIG_SOURCE_PATH=$BASE_PATH/deployment/src/kayobe-config/src/kayobe-config
    export KAYOBE_VENV_PATH=$BASE_PATH/deployment/venvs/kayobe
    pushd $BASE_PATH/src/kayobe
    ./dev/overcloud-test-vm.sh
fi
