#######################################
#### DMZ Variables 
#######################################
variable "dmz_zones" {
  description = "stuff"
  type        = map(any)
}

variable "deploy_dmz" {
  description = "stuff"
  type        = bool
}

variable "deploy_dmz_ftgs" {
  description = "stuff"
  type        = bool
}

variable "dmz_ftg_ami_id" {
  description = "A variable"
  type        = string
}

variable "dmz_ftg_instance_type" {
  description = "A variable"
  type        = string
}

variable "dmz_ftg_devices" {
  description = "A variable"
  type        = map(any)
}

variable "vpce_allowed_accounts" {
  description = "A list of vpce_allowed_accounts"
  type        = any
}

variable "dmz_management_subnets" {
  description = "A map of DMZ management subnets"
  type        = map(any)
}

variable "dmz_partitions" {
  description = "A map of DMZ partition subnets to create"
  type        = map(any)
}

variable "dmz_inspection_vpc_cidr" {
  description = "CIDR for DMZ Inspection VPC"
}
