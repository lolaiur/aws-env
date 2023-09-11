# Deploy DMZ VPC
module "dmz_vpc" {
  count = var.deploy_dmz ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "DMZ-CIA-vpc" # DMZ Centralized Inspection Architecture (convenient )
  cidr = var.dmz_inspection_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  create_egress_only_igw          = false
  enable_nat_gateway              = false
  enable_vpn_gateway              = false
  create_elasticache_subnet_group = false
  create_igw                      = false
  manage_default_route_table      = false
  manage_default_security_group   = false

  tags = {
    "Env" = "DMZ-CIA-VPC"
  }
}

##################################
#### IGW and Routes 
##################################

# Create IGW for DMZ
resource "aws_internet_gateway" "dmz_vpc_igw" {
  count  = var.deploy_dmz ? 1 : 0
  vpc_id = module.dmz_vpc[0].vpc_id

  tags = {
    Name = "DMZ-CIA-IGW"
  }
}

# Create IGW route table
resource "aws_route_table" "dmz_vpc_igw" {
  count  = var.deploy_dmz ? 1 : 0
  vpc_id = module.dmz_vpc[0].vpc_id

  tags = {
    Name = "dmz-vpc.igw.rt"
  }
}

# Assocation IGW route table
resource "aws_route_table_association" "dmz_vpc_igw" {
  count          = var.deploy_dmz ? 1 : 0
  gateway_id     = aws_internet_gateway.dmz_vpc_igw[0].id
  route_table_id = aws_route_table.dmz_vpc_igw[0].id
}

##################################
#### TGW Subnets and Routes
##################################

resource "aws_subnet" "dmz_vpc_tgw" {
  for_each          = var.deploy_dmz ? { for k, v in var.dmz_management_subnets : k => v.tgw_subnet } : {}
  vpc_id            = module.dmz_vpc[0].vpc_id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    "Name" = "tgw.${each.key}.subnet"
  }
}

# Create TGW Route table for each AZ
resource "aws_route_table" "dmz_vpc_tgw" {
  for_each = var.deploy_dmz ? { for k, v in var.dmz_management_subnets : k => v.tgw_subnet } : {}
  vpc_id   = module.dmz_vpc[0].vpc_id
  tags = {
    "Name" = "tgw.${each.key}.rt"
  }
}

# TGW route table associations
resource "aws_route_table_association" "dmz_vpc_tgw" {
  for_each       = var.deploy_dmz ? { for k, v in var.dmz_management_subnets : k => v.tgw_subnet } : {}
  subnet_id      = aws_subnet.dmz_vpc_tgw[each.key].id
  route_table_id = aws_route_table.dmz_vpc_tgw[each.key].id
}

# TGW Attachments
resource "aws_ec2_transit_gateway_vpc_attachment" "dmz_vpc_tgw_subnets" {
  count                  = var.deploy_dmz ? 1 : 0
  subnet_ids             = values(aws_subnet.dmz_vpc_tgw)[*].id
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id                 = module.dmz_vpc[0].vpc_id
  appliance_mode_support = "enable"

  tags = merge(
    {
      "Name" = "dmz-vpc.tgw-attachment"
    }
  )
}

####################
# GWLB 
####################

# Loadbalancer Subnets & Routes 
resource "aws_subnet" "dmz_vpc_loadbalancer" {
  for_each          = var.deploy_dmz ? local.gwlb_subnets : {}
  vpc_id            = module.dmz_vpc[0].vpc_id
  cidr_block        = each.value.loadbalancer_subnet
  availability_zone = each.value.az

  tags = {
    "Name" = "replace-this-name.lb.${each.key}.subnet"
  }
}

# Create a route table for the North and South 
resource "aws_route_table" "dmz_vpc_loadbalancer" {
  for_each = var.deploy_dmz != false ? var.dmz_zones : {}
  vpc_id   = module.dmz_vpc[0].vpc_id
  tags = {
    "Name" = "${each.key}-gwlb.lb.rt"
  }
}

# GWLB route table associations
resource "aws_route_table_association" "dmz_vpc_loadbalancer" {
  for_each       = var.deploy_dmz ? local.gwlb_subnets : {}
  subnet_id      = aws_subnet.dmz_vpc_loadbalancer[each.key].id
  route_table_id = aws_route_table.dmz_vpc_loadbalancer[each.value.zone].id
}

# North and South GWLB 
resource "aws_lb" "dmz_vpc_gwlb" {
  for_each                         = var.deploy_dmz ? local.gwlb_mappings : {}
  name                             = replace("${each.key}.gwlb.lb", ".", "-")
  enable_cross_zone_load_balancing = var.x_zone_lb
  load_balancer_type               = "gateway"

  
  # depends_on = [aws_subnet.dmz_vpc_loadbalancer]

  dynamic "subnet_mapping" {
    for_each = toset(each.value)
    content {
      subnet_id = (aws_subnet.dmz_vpc_loadbalancer)[subnet_mapping.key].id 
    }
  }
  tags = {
    "Name" = "replace-this-name.gwlb.lb"
  }
}

# Target group 
resource "aws_lb_target_group" "dmz_vpc_gwlb" {
  for_each    = var.deploy_dmz ? local.gwlb_mappings : {}
  name        = replace("${each.key}.gwlb.lb.tg", ".", "-")
  port        = "6081"
  target_type = "ip"
  protocol    = "GENEVE"
  vpc_id      = module.dmz_vpc[0].vpc_id
  health_check {
    protocol            = "HTTP"
    port                = "8008"
    interval            = "10"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
  }
  tags = {
    "Name" = replace("${each.key}.gwlb.lb.tg", ".", "-")
  }
}

# Create a Listener for the Gateway Load Balancer
resource "aws_lb_listener" "dmz_gwlb_listener" {
  for_each = var.deploy_dmz_ftgs ? local.gwlb_mappings : {}
  load_balancer_arn = aws_lb.dmz_vpc_gwlb[each.key].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dmz_vpc_gwlb[each.key].arn
  }
}

resource "aws_lb_target_group_attachment" "north_dmz_vpc_gwlb" {
  for_each         = var.deploy_dmz_ftgs ?  merge([ for k, v in var.dmz_ftg_devices : { "${k}_north_${v.az}" = { device = k, inspection_address = v.north_inspection_address, zone = "north" } }]...) : {}
  target_group_arn = aws_lb_target_group.dmz_vpc_gwlb[each.value.zone].arn
  target_id        = aws_network_interface.north_inspection_ftg["${each.value.device}"].private_ip
}

resource "aws_lb_target_group_attachment" "south_dmz_vpc_gwlb" {
  for_each         = var.deploy_dmz_ftgs ?  merge([ for k, v in var.dmz_ftg_devices : { "${k}_south_${v.az}" = { device = k, inspection_address = v.south_inspection_address, zone = "south" } }]...) : {}
  target_group_arn = aws_lb_target_group.dmz_vpc_gwlb[each.value.zone].arn
  target_id        = aws_network_interface.south_inspection_ftg["${each.value.device}"].private_ip
}


# VPC Endpoint Service for each Zone (North/South)
resource "aws_vpc_endpoint_service" "dmz_vpc_gwlb" {
  for_each                   = var.deploy_dmz ? local.gwlb_mappings : {}
  acceptance_required        = false
  allowed_principals         = [var.vpce_allowed_accounts]
  gateway_load_balancer_arns = [aws_lb.dmz_vpc_gwlb[each.key].arn]
  tags = {
    Name = "${each.key}.gwlb.vpc_endpoint_service"
  }
}