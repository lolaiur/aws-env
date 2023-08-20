data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# data "aws_subnet_ids" "selected" {
#   vpc_id = module.vpc["${each.value.vpc}"].vpc_id
# }

#Unused
#data "aws_ami" "amazon_linux" {
#  most_recent = true
#
#  filter {
#    name   = "name"
#    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#  }
#
#  filter {
#    name   = "block-device-mapping.volume-type"
#    values = ["gp2"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#
#  owners = ["099720109477"] # Canonical
#}
