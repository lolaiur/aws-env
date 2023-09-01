# 10.253.225.0/24   VPC
# 10.253.225.0/27	Intra  
# 10.253.225.32/27  Mgmt
# 10.253.225.64/27  South
# 10.253.225.96/27  North
# 10.253.225.128/27 GWLB
# 10.253.225.160/27 NAT
# 10.253.225.192/27
# 10.253.225.224/27 TGW

##################
##              ##
##  VPC         ##
##              ##
##################

module "OBI" {
  count = var.deploy_oig ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "vpc.OBI"
  cidr = "10.253.225.0/24"

  azs           = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  intra_subnets = ["10.253.225.0/27"]

  #private_subnet_ipv6_prefixes    = [0, 1, 2]
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
  count              = var.deploy_oig ? 1 : 0
  subnet_ids         = [aws_subnet.obi-tgw[0].id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = module.OBI[0].vpc_id

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
  count             = var.deploy_oig ? 1 : 0
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[0]
  cidr_block        = "10.253.225.32/27"

  tags = {
    "Name" = "OBI.mgmt.sub"
  }
}

resource "aws_subnet" "inspection" {
  count             = var.deploy_oig ? 1 : 0
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[0]
  cidr_block        = "10.253.225.64/27"

  tags = {
    "Name" = "OBI.inspection.sub"
  }
}

resource "aws_subnet" "gwlb" {
  count             = var.deploy_oig ? 1 : 0
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[0]
  cidr_block        = "10.253.225.96/27"

  tags = {
    "Name" = "OBI.gwlb.sub"
  }
}

resource "aws_subnet" "nat" {
  count             = var.deploy_oig ? 1 : 0
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[0]
  cidr_block        = "10.253.225.128/27"

  tags = {
    "Name" = "OBI.nat.sub"
  }
}

resource "aws_subnet" "obi-tgw" {
  count             = var.deploy_oig ? 1 : 0
  vpc_id            = module.OBI[0].vpc_id
  availability_zone = module.OBI[0].azs[0]
  cidr_block        = "10.253.225.224/27"

  tags = {
    "Name" = "OBI.tgw.sub"
  }
}
##################
##              ##
##  RTBs        ##
##              ##
##################

resource "aws_route_table" "mgmt" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.mgmt.rtb"
  }
}

resource "aws_route_table" "inspection" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.inspection.rtb"
  }
}

resource "aws_route_table" "gwlb" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.gwlb.rtb"
  }
}

resource "aws_route_table" "nat" {
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.nat.rtb"
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
  count  = var.deploy_oig ? 1 : 0
  vpc_id = module.OBI[0].vpc_id

  tags = {
    "Name" = "OBI.tgw.rtb"
  }
}



##################
##              ##
##  RTBs Assoc  ##
##              ##
##################

resource "aws_route_table_association" "mgmt" {
  count          = var.deploy_oig ? 1 : 0
  subnet_id      = aws_subnet.mgmt[0].id
  route_table_id = aws_route_table.mgmt[0].id
}

resource "aws_route_table_association" "inspection" {
  count          = var.deploy_oig ? 1 : 0
  subnet_id      = aws_subnet.inspection[0].id
  route_table_id = aws_route_table.inspection[0].id
}


resource "aws_route_table_association" "gwlb" {
  count          = var.deploy_oig ? 1 : 0
  subnet_id      = aws_subnet.gwlb[0].id
  route_table_id = aws_route_table.gwlb[0].id
}

resource "aws_route_table_association" "nat" {
  count          = var.deploy_oig ? 1 : 0
  subnet_id      = aws_subnet.nat[0].id
  route_table_id = aws_route_table.nat[0].id
}


resource "aws_route_table_association" "obi-tgw" {
  count          = var.deploy_oig ? 1 : 0
  subnet_id      = aws_subnet.obi-tgw[0].id
  route_table_id = aws_route_table.obi-tgw[0].id
}

##################
##              ##
##  Routes      ##
##              ##
##################

# IGW to something??

########## TGW RTB ##########
## -> TGW to GWLBe
resource "aws_route" "tgw_to_gwlbe" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.obi-tgw[0].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbe[0].id

}


########## NAT RTB ##########
## 0/0 -> IGW
resource "aws_route" "tgw-def_to_igw" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.nat[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.obi-igw[0].id

}

## Env -> VPCe
resource "aws_route" "tgw-env_to_vpce" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.nat[0].id
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlbe[0].id

}

########## MGT RTB ##########
## 0/0 -> NAT
resource "aws_route" "mgmt-def_to_nat" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.mgmt[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[0].id
}
## Env -> TGW
resource "aws_route" "mgmt-env_to_tgw" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.mgmt[0].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

########## GWLB RTB ##########
## 0/0 -> NAT
resource "aws_route" "gwlb-def_to_nat" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.gwlb[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[0].id
}

## Env -> TGW
resource "aws_route" "gwlb-env_to_tgw" { # Need to confirm
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.gwlb[0].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

########## Inspection RTB ##########
## 0/0 -> NAT
resource "aws_route" "inspect-def_to_nat" {
  count                  = var.deploy_oig ? 1 : 0
  route_table_id         = aws_route_table.inspection[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat[0].id
}

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
  count         = var.deploy_oig ? 1 : 0
  ami           = var.ftg_ami
  instance_type = var.ftg_instance
  #subnet_id     = aws_subnet.public_subnet[0].id

  # Attach ENIs to the Fortigate instance
  network_interface {
    network_interface_id = aws_network_interface.mgmt_eni[0].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.south_eni[0].id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.tap_eni[0].id
    device_index         = 2
  }

  tags = {
    Name = "OBI.FTG"
  }
}

resource "aws_network_interface" "tap_eni" {
  count           = var.deploy_oig ? 1 : 0
  subnet_id       = module.OBI[0].intra_subnets[0]
  security_groups = [aws_security_group.sg[0].id] # Replace with your security group

  tags = {
    Name = "FTG-North.eni"
  }
}

resource "aws_network_interface" "south_eni" {
  count           = var.deploy_oig ? 1 : 0
  subnet_id       = aws_subnet.inspection[0].id
  security_groups = [aws_security_group.sg[0].id] # Replace with your security group

  tags = {
    Name = "FTG-South.eni"
  }
}

resource "aws_network_interface" "mgmt_eni" {
  count           = var.deploy_oig ? 1 : 0
  subnet_id       = aws_subnet.mgmt[0].id
  security_groups = [aws_security_group.sg[0].id] # Replace with your security group

  tags = {
    Name = "FTG-MGMT.eni"
  }
}

##################
##              ##
##  IGW         ##
##              ##
##################

resource "aws_eip" "obi-eip" {
  count = var.deploy_oig ? 1 : 0
  tags = {
    Name = "OBI.eip"
  }
}

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

resource "aws_nat_gateway" "obi_nat" {
  count         = var.deploy_oig ? 1 : 0
  subnet_id     = aws_subnet.nat[0].id
  allocation_id = aws_eip.obi-eip[0].id

  tags = {
    Name = "OBI.NAT-GWY"
  }
}

##################
##              ##
##  GWLB        ##
##              ##
##################

resource "aws_lb" "gwlb" {
  count = var.deploy_oig ? 1 : 0
  name  = "OBI-gwlb"
  #  internal                   = true
  load_balancer_type         = "gateway"
  enable_deletion_protection = false
  subnets                    = [aws_subnet.gwlb[0].id]

  enable_cross_zone_load_balancing = false

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
  count             = var.deploy_oig ? 1 : 0
  service_name      = aws_vpc_endpoint_service.gwlb[0].service_name
  subnet_ids        = [aws_subnet.gwlb[0].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb[0].service_type
  vpc_id            = module.OBI[0].vpc_id
}

# Create a Target Group for the Gateway Load Balancer
resource "aws_lb_target_group" "gwlb_tg" {
  count       = var.deploy_oig ? 1 : 0
  name        = "OBI-gwlb-tg"
  port        = "6081"
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = module.OBI[0].vpc_id

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
  # port              = "80"
  # protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb_tg[0].arn
  }
}

# Register Fortigate instance with the target group
resource "aws_lb_target_group_attachment" "ftg_tg_attachment" {
  count            = var.deploy_oig ? 1 : 0
  target_group_arn = aws_lb_target_group.gwlb_tg[0].arn
  target_id        = aws_network_interface.south_eni[0].private_ip
  #  port             = "6081"
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







##################
##              ##
##    ForiOS    ##
##              ##
##################