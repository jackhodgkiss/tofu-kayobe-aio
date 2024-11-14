variable "dns_zone_name" {
  description = "The name of the DNS zone to use for creating DNS records. Leave empty or null to skip DNS record creation."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = var.dns_zone_name == null || can(regex(".*\\.$", var.dns_zone_name))
    error_message = "The DNS Zone name must end with a `.`."
  }
}

variable "instance_flavor_id" {
  description = "The flavor ID used to create the instance."
  type        = string
  nullable    = false
}

variable "instance_keypair_name" {
  description = "Name of SSH key use to authenticate with instance via SSH."
  type        = string
  nullable    = false
}

variable "instance_security_groups" {
  description = "List of security groups to apply to instance."
  type        = list(string)
  default     = ["default"]
}

variable "instance_network_name" {
  description = "Name of the network to attach the instance to."
  type        = string
  default     = "stackhpc-ipv4-geneve"
}

variable "instance_volume_size" {
  description = "Size of the root volume used by the instance."
  type        = number
  default     = 64
  validation {
    condition     = var.instance_volume_size >= 16 && var.instance_volume_size <= 512
    error_message = "The root volume size must be between 16G and 512G"
  }
}

variable "instance_image_name" {
  description = "Name of the image used to boot the instance."
  type        = string
}

variable "vault_password" {
  description = "Vault password used to decrypt the vault and any secrets within StackHPC Kayobe Config."
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}

variable "kayobe_branch" {
  description = "Branch of StackHPC Kayobe should be used to provision OpenStack."
  type        = string
  default     = "stackhpc/2024.1"
}

variable "kayobe_config_branch" {
  description = "Branch of StackHPC Kayobe Config should be used to provision OpenStack."
  type        = string
  default     = "stackhpc/2024.1"
}

variable "use_lvm" {
  description = "If using LVM based image this should be true in order to ensure the host is configured with appropriate LVM layout."
  type        = bool
  default     = true
}

variable "allow_config_edit" {
  description = "Control if the script should pause allowing for config changes before proceeding on with deployment."
  type        = bool
  default     = false
}

variable "run_tempest" {
  description = "Run Tempest after OpenStack services have been deployed."
  type        = bool
  default     = false
}
