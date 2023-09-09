variable "vpcs" {
  description = "Map of regions to VPCs to create"
  type        = any
  default     = {}
}

variable "route_tables" {
  type = map(object({
    associations     = list(string)
    propagations     = list(string)
    static_routes    = map(string)
    blackhole_routes = list(string)
  }))
}

variable "ec2" {
  description = "Configuration for EC2 instances"
  type = map(object({
    vpc = string
    az  = string
    os  = string
    ud  = string
  }))
}

variable "public_key" {
  description = "Public key for EC2 instances"
  type        = string
  default     = ""
}

variable "create_cgw" {
  type    = bool
  default = false
}

variable "deploy_ssm" {
  description = "Whether to deploy SSM related resources"
  type        = bool
  default     = false
}

variable "deploy_ep" {
  description = "Toggle to deploy the VPC endpoints"
  type        = bool
  default     = false
}

variable "my_ip" {
  type = string
}

variable "deploy_vpn" {
  type    = bool
  default = false
}

variable "deploy_ovp" {
  type    = bool
  default = false
}

variable "ssh_user" {
  type        = string
  description = "user ssh"
  default     = "ec2-user"
}

variable "ssh_port" {
  type        = number
  description = "port ssh"
  default     = 22
}

# Unused
#variable "instance_type" {
#  type        = string
#  description = "type instance"
#  default     = "t2.micro"
#}

variable "admin_user" {
  type        = string
  description = "admin user"
  default     = "openvpn"
}

variable "storage_path" {
  type        = string
  description = "storage path keys to local"
  default     = "./openvpn"
}

variable "private_key_path" {
  type    = string
  default = "./key.pub" # Update to the actual path
}

variable "deploy_dns" {
  type    = bool
  default = false
}

variable "os_user" {
  description = "Username you wish to pass into userdata"
  type        = string
}

variable "os_pass" {
  description = "Password you wish to pass into userdata"
  type        = string
}

variable "ftg_ami" {
  description = "Value of FTG AMI to use"
  type        = string
}

variable "ftg_instance" {
  description = "Value of Instance Type for FTG"
  type        = string
}

variable "deploy_obi" {
  description = "Toggle to deploy or not deploy the OBI VPC"
  type        = bool
  default     = false
}

variable "deploy_oig" {
  description = "Toggle to deploy or not deploy the OBI VPC"
  type        = bool
  default     = false
}

variable "deploy_cfg" {
  description = "Toggle to deploy or not configure the OBI Forti"
  type        = bool
  default     = false
}

variable "forti_token" {
  description = "Token generated from FortiOS for API User"
  type        = string
  default     = ""
}

variable "obi" {
  description = "The CIDRs for OBI setup"
  type = object({
    cidr       = string
    intra      = list(string)
    mgmt       = list(string)
    inspection = list(string)
    nat        = list(string)
    gwlb       = list(string)
    tgw        = list(string)
  })
}

variable "ftg" {
  description = "Defines number of FTGs to deploy, which az, and if they should be placed into target group"
  type = map(object({
    az = string # Availability Zone index as a string
    tg = string # Whether to add to target group: 'y' or 'n'
  }))
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "x_zone_lb" {
  description = "Toggles Cross Zone LB on GWLB"
  type        = bool
  default     = false
}

variable "dns_name" {
  description = "DNS name to use for the DNS zone"
  type        = string
  default     = "your-own"
}