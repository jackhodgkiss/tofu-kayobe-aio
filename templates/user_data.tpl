#cloud-config

package_update: true
package_upgrade: true

packages:
  - python3-pip
  - ansible

users:
  - name: cloud-user
    gecos: Cloud User
    groups:
      - sudo
    sudo: "ALL=(ALL) NOPASSWD: ALL"
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${user_ssh_key}

ansible:
  package_name: ansible
  install_method: pip
  run_user: cloud-user
  pull:
    url: "https://github.com/jackhodgkiss/bootstrap-node.git"
    playbook_name: site.yml
