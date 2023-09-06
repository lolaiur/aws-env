data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# Collects GWLBe IP for FortiOS remote_ip
data "aws_network_interface" "endpoint" {
  count = var.deploy_oig ? 1 : 0
  id    = tolist(aws_vpc_endpoint.gwlbe[0].network_interface_ids)[0]
}


# Gets GWLB IP for Forti Routing
data "aws_network_interface" "gwlb_eni" {
  count = var.deploy_oig ? 1 : 0
  filter {
    name   = "description"
    values = ["ELB gwy/${aws_lb.gwlb[0].name}/*"]
  }
}

# Generates FortiOS Config
data "template_file" "ftg01" {
  count    = var.deploy_oig ? 1 : 0
  template = local.config_script
}