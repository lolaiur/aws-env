##################
##              ##
##  VPC         ##
##              ##
##################

module "OBI" {
  count   = var.deploy_oig ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "vpc.OBI"
  cidr = var.obi.cidr

  azs           = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  intra_subnets = var.obi.intra

  create_egress_only_igw          = false
  enable_nat_gateway              = false
  enable_vpn_gateway              = false
  create_elasticache_subnet_group = false
  create_igw                      = false
  manage_default_route_table      = false
  manage_default_security_group   = false

  tags = {
    "Env" = "prd"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "obi-tgw_attch" {
  count                  = var.deploy_oig ? 1 : 0
  subnet_ids             = [for s in aws_subnet.obi-tgw : s.id]
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id                 = module.OBI[0].vpc_id
  appliance_mode_support = "enable"
  tags = {
    "Name" = "OBI.tgw-attachment"
  }
}

##################
##              ##
##  Subnets     ##
##              ##
##################

resource "aws_subnet" "mgmt" {
  for_each          = var.deploy_oig ? { for idx, cidr in var.obi.mgmt : idx => cidr } : {}
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[each.key]
  cidr_block        = each.value

  tags = {
    "Name" = "OBI.sub.mgmt.${each.key}"
  }
}


resource "aws_subnet" "inspection" {
  for_each          = var.deploy_oig ? { for idx, cidr in var.obi.inspection : idx => cidr } : {}
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[each.key]
  cidr_block        = each.value

  tags = {
    "Name" = "OBI.sub.inspection.${each.key}"
  }
}

resource "aws_subnet" "gwlb" {
  for_each          = var.deploy_oig ? { for idx, cidr in var.obi.gwlb : idx => cidr } : {}
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[each.key]
  cidr_block        = each.value

  tags = {
    "Name" = "OBI.sub.gwlb.${each.key}"
  }
}

resource "aws_subnet" "nat" {
  for_each          = var.deploy_oig ? { for idx, cidr in var.obi.nat : idx => cidr } : {}
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[each.key]
  cidr_block        = each.value

  tags = {
    "Name" = "OBI.sub.nat.${each.key}"
  }
}

resource "aws_subnet" "obi-tgw" {
  for_each          = var.deploy_oig ? { for idx, cidr in var.obi.tgw : idx => cidr } : {}
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[each.key]
  cidr_block        = each.value

  tags = {
    "Name" = "OBI.sub.tgw.${each.key}"
  }
}
##################
##              ##
##  RTBs        ##
##              ##
##################

resource "aws_route_table" "mgmt" {
  for_each = var.deploy_oig ? toset(values(local.azs)) : toset([])
  vpc_id   = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.mgmt.${each.value}.rtb"
  }
}

resource "aws_route_table" "inspection" {
  for_each = var.deploy_oig ? toset(values(local.azs)) : toset([])
  vpc_id   = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.inspection.${each.value}.rtb"
  }
}

resource "aws_route_table" "gwlb" {
  for_each = var.deploy_oig ? toset(values(local.azs)) : toset([])
  vpc_id   = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.gwlb.${each.value}.rtb"
  }
}

resource "aws_route_table" "nat" {
  for_each = var.deploy_oig ? toset(values(local.azs)) : toset([])
  vpc_id   = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.nat.${each.value}.rtb"
  }
}

resource "aws_route_table" "igw" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.igw.rtb"
  }
}

resource "aws_route_table" "obi-tgw" {
  for_each = var.deploy_oig ? toset(values(local.azs)) : toset([])
  vpc_id   = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.tgw.${each.value}.rtb"
  }
}

##################
##              ##
##  RTBs Assoc  ##
##              ##
##################

resource "aws_route_table_association" "mgmt" {
  for_each       = var.deploy_oig ? { for s in aws_subnet.mgmt : s.availability_zone => s.id } : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.mgmt[each.key].id
}

resource "aws_route_table_association" "inspection" {
  for_each       = var.deploy_oig ? { for s in aws_subnet.inspection : s.availability_zone => s.id } : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.inspection[each.key].id
}

resource "aws_route_table_association" "gwlb" {
  for_each       = var.deploy_oig ? { for s in aws_subnet.gwlb : s.availability_zone => s.id } : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.gwlb[each.key].id
}

resource "aws_route_table_association" "nat" {
  for_each       = var.deploy_oig ? { for s in aws_subnet.nat : s.availability_zone => s.id } : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.nat[each.key].id
}

resource "aws_route_table_association" "obi-tgw" {
  for_each       = var.deploy_oig ? { for s in aws_subnet.obi-tgw : s.availability_zone => s.id } : {}
  subnet_id      = each.value
  route_table_id = aws_route_table.obi-tgw[each.key].id
}

##################
##              ##
##  Routes      ##
##              ##
##################
########## TGW RTB ##########
## -> TGW to GWLBe
resource "aws_route" "tgw_to_gwlbe" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.obi-tgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  #vpc_endpoint_id        = aws_vpc_endpoint.gwlbe[each.key].id
  vpc_endpoint_id = aws_vpc_endpoint.gwlbe[index(values(local.azs), each.key)].id
}

########## NAT RTB ##########
## 0/0 -> IGW
resource "aws_route" "tgw-def_to_igw" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.nat[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.obi-igw[0].id
}

## Env -> VPCe
resource "aws_route" "tgw-env_to_vpce" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.nat[each.key].id
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbe[index(values(local.azs), each.key)].id
}

########## MGT RTB ##########
## 0/0 -> NAT
resource "aws_route" "mgmt-def_to_nat" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.mgmt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[index(values(local.azs), each.key)].id

}

## Env -> TGW
resource "aws_route" "mgmt-env_to_tgw" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.mgmt[each.key].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

########## GWLB RTB ##########
## 0/0 -> NAT
resource "aws_route" "gwlb-def_to_nat" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.gwlb[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[index(values(local.azs), each.key)].id

}

## Env -> TGW
resource "aws_route" "gwlb-env_to_tgw" { # Need to confirm
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.gwlb[each.key].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

########## Inspection RTB ##########
## 0/0 -> NAT
resource "aws_route" "inspect-def_to_nat" {
  for_each               = var.deploy_oig ? toset(values(local.azs)) : toset([])
  route_table_id         = aws_route_table.inspection[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[index(values(local.azs), each.key)].id

}

############ TGW ROUTE #############
resource "aws_ec2_transit_gateway_route" "obirt" {
  count                          = var.deploy_oig ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.obi-tgw_attch[0].id

  depends_on = [aws_ec2_transit_gateway.transit_gateway]
}

##################
##              ##
##  Forti       ##
##              ##
##################


resource "aws_instance" "ftg_instance" {
  for_each      = var.deploy_oig ? var.ftg : {}
  ami           = var.ftg_ami
  instance_type = var.ftg_instance
  #subnet_id     = module.OBI[var.ftg[each.key]["az"]].intra_subnets[0]

  # Attach ENIs to the Fortigate instance
  network_interface {
    network_interface_id = aws_network_interface.mgmt_eni[each.key].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.south_eni[each.key].id
    device_index         = 1
  }
  ## Commented out because port 3 is not required, this is primarily a TAP interface
  #network_interface {
  #  network_interface_id = aws_network_interface.tap_eni[each.key].id
  #  device_index         = 2
  #}

  user_data = data.template_file.ftg_config[each.key].rendered

  tags = {
    Name = "OBI.FTG.${each.key}"
  }
}

resource "aws_network_interface" "south_eni" {
  for_each        = var.deploy_oig ? var.ftg : {}
  subnet_id       = aws_subnet.inspection[var.ftg[each.key]["az"]].id
  security_groups = [aws_security_group.sg[0].id]

  tags = {
    Name = "FTG-South.eni.${each.key}"
  }
}

resource "aws_network_interface" "mgmt_eni" {
  for_each        = var.deploy_oig ? var.ftg : {}
  subnet_id       = aws_subnet.mgmt[var.ftg[each.key]["az"]].id
  security_groups = [aws_security_group.sg[0].id]

  tags = {
    Name = "FTG-MGMT.eni.${each.key}"
  }
}


##################
##              ##
##  IGW         ##
##              ##
##################

resource "aws_internet_gateway" "obi-igw" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id
  tags = {
    Name = "OBI.igw"
  }
}

##################
##              ##
##  NAT GW      ##
##              ##
##################

resource "aws_eip" "obi-eip" {
  # Create an EIP for each AZ if deploy_oig is true
  count = var.deploy_oig ? length(var.obi["nat"]) : 0
  tags = {
    Name = "OBI.eip"
  }
}

resource "aws_nat_gateway" "obi_nat" {
  # Create a NAT Gateway for each AZ if deploy_oig is true
  count         = var.deploy_oig ? length(var.obi["nat"]) : 0
  subnet_id     = aws_subnet.nat[count.index].id
  allocation_id = aws_eip.obi-eip[count.index].id

  tags = {
    Name = "OBI.nat-gwy.${count.index}"
  }
}

##################
##              ##
##  GWLB        ##
##              ##
##################

resource "aws_lb" "gwlb" {
  count                            = var.deploy_oig ? 1 : 0
  name                             = "OBI-gwlb"
  load_balancer_type               = "gateway"
  enable_deletion_protection       = false
  subnets                          = [for s in aws_subnet.gwlb : s.id]
  enable_cross_zone_load_balancing = var.x_zone_lb

  tags = {
    Name = "OBI gwlb"
  }
}

resource "aws_vpc_endpoint_service" "gwlb" {
  count                      = var.deploy_oig ? 1 : 0
  acceptance_required        = false
  allowed_principals         = [data.aws_caller_identity.current.arn]
  gateway_load_balancer_arns = [aws_lb.gwlb[0].arn]
}

resource "aws_vpc_endpoint" "gwlbe" {
  count             = var.deploy_oig ? length(var.obi.gwlb) : 0
  service_name      = aws_vpc_endpoint_service.gwlb[0].service_name # Referencing the single VPC endpoint service
  subnet_ids        = [aws_subnet.gwlb[count.index].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb[0].service_type # Referencing the single VPC endpoint service
  vpc_id            = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.vpc-endpoint-${count.index}"
  }
}

# Create a Target Group for the Gateway Load Balancer
resource "aws_lb_target_group" "gwlb_tg" {
  count                = var.deploy_oig ? 1 : 0
  name                 = "OBI-gwlb-tg"
  port                 = "6081"
  protocol             = "GENEVE"
  target_type          = "ip"
  vpc_id               = module.OBI[0].vpc_id
  deregistration_delay = "30"


  target_failover {
    on_deregistration = "rebalance"
    on_unhealthy      = "rebalance"
  }

  health_check {
    protocol            = "HTTP"
    port                = "8008"
    interval            = "10"
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "OBI gwlb tg"
  }
}

# Create a Listener for the Gateway Load Balancer
resource "aws_lb_listener" "gwlb_listener" {
  count             = var.deploy_oig ? 1 : 0
  load_balancer_arn = aws_lb.gwlb[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb_tg[0].arn
  }
}

# Register Fortigate instance with the target group
resource "aws_lb_target_group_attachment" "ftg_tg_attachment" {
  for_each         = var.deploy_oig ? { for k, v in var.ftg : k => v if v.tg == "y" } : {}
  target_group_arn = aws_lb_target_group.gwlb_tg[0].arn
  target_id        = aws_network_interface.south_eni[each.key].private_ip
}

##################
##              ##
##  SGs         ##
##              ##
##################

resource "aws_security_group" "sg" {
  count       = var.deploy_oig ? 1 : 0
  name        = "ftg-sg"
  description = "Security group for FTG"
  vpc_id      = module.OBI[0].vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}