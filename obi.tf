module "vpcOBI" {
  count = var.deploy_obi ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "OBI-vpc"
  cidr = "10.254.255.0/24"

  azs           = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  intra_subnets = ["10.254.255.0/27"]

  #private_subnet_ipv6_prefixes    = [0, 1, 2]
  create_egress_only_igw          = false
  enable_nat_gateway              = false
  enable_vpn_gateway              = false
  create_elasticache_subnet_group = false
  create_igw                      = false
  manage_default_route_table      = false
  manage_default_security_group   = false

  tags = {
    "Env" = "OBI-VPC"
  }
}
# Create EIP for OBI
resource "aws_eip" "obi_eip" {
  count = var.deploy_obi ? 1 : 0
  tags = {
    Name = "OBI-EIP"
  }
}

# Associate EIP to OBI IGW
resource "aws_internet_gateway" "obi_vpc_igw" {
  count  = var.deploy_obi ? 1 : 0
  vpc_id = module.vpcOBI[0].vpc_id
  tags = {
    Name = "OBI-IGW"
  }
}

# Create a public subnet for the OBI NAT Gateway in AZ1
resource "aws_subnet" "public_subnet" {
  count             = var.deploy_obi ? 1 : 0
  vpc_id            = module.vpcOBI[0].vpc_id
  availability_zone = module.vpcOBI[0].azs[0]
  cidr_block        = "10.254.255.32/27" # Adjust this CIDR as required

  tags = {
    "Name" = "OBI-Pub-Sub"
  }
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "obi_nat_gw" {
  count         = var.deploy_obi ? 1 : 0
  subnet_id     = aws_subnet.public_subnet[0].id
  allocation_id = aws_eip.obi_eip[0].id

  tags = {
    Name = "OBI-NAT-GW"
  }
}

# Create Public RTB
resource "aws_route_table" "public_subnet_route_table" {
  count  = var.deploy_obi ? 1 : 0
  vpc_id = module.vpcOBI[0].vpc_id

  tags = {
    "Name" = "OBI-Public-RTB"
  }
}

# Associate Public Subnet to Public RTB
resource "aws_route_table_association" "public_subnet_rtb_assoc" {
  count          = var.deploy_obi ? 1 : 0
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public_subnet_route_table[0].id
}

# Route 0/0 to OBI IGW in Public RTB
resource "aws_route" "public_to_igw" {
  count                  = var.deploy_obi ? 1 : 0
  route_table_id         = aws_route_table.public_subnet_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.obi_vpc_igw[0].id
}

# Route to environment in Public RTB 
resource "aws_route" "public_return" {
  count                  = var.deploy_obi ? 1 : 0
  route_table_id         = aws_route_table.public_subnet_route_table[0].id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id

  depends_on = [aws_ec2_transit_gateway.transit_gateway]
}

# Route to environment from intra RTB
resource "aws_route" "intraOBI" {
  count                  = var.deploy_obi ? 1 : 0
  route_table_id         = module.vpcOBI[0].intra_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id

  depends_on = [aws_ec2_transit_gateway.transit_gateway]

}

# Route 0/0 to IGW in intra RTB
resource "aws_route" "obivpc_to_my_ip" {
  count                  = var.deploy_obi ? 1 : 0
  route_table_id         = module.vpcOBI[0].intra_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.obi_vpc_igw[0].id
}

# Create TGW Subnet in OBI
resource "aws_subnet" "obitgw" {
  count             = var.deploy_obi ? 1 : 0
  vpc_id            = module.vpcOBI[0].vpc_id
  availability_zone = module.vpcOBI[0].azs[0]
  cidr_block        = "10.254.255.224/27"

  tags = {
    "Name" = "OBI TGW Subnet"
  }
}

# Create TGW RTB in OBI
resource "aws_route_table" "obitgw" {
  count  = var.deploy_obi ? 1 : 0
  vpc_id = module.vpcOBI[0].vpc_id

  tags = {
    "Name" = "OBI TGW RTB"
  }
}

# Create 0/0 to NAT GW in TGW RTB
resource "aws_route" "tgw_sub_to_nat" {
  count                  = var.deploy_obi ? 1 : 0
  route_table_id         = aws_route_table.obitgw[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.obi_nat_gw[0].id

}

# Associate OBI TGW Subnet to OBI TGW RTB
resource "aws_route_table_association" "obitgw" {
  count          = var.deploy_obi ? 1 : 0
  subnet_id      = aws_subnet.obitgw[0].id
  route_table_id = aws_route_table.obitgw[0].id
}

# Create OBI TGW Attachment to Main TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "obitgw_attch" {
  count              = var.deploy_obi ? 1 : 0
  subnet_ids         = [aws_subnet.obitgw[0].id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = module.vpcOBI[0].vpc_id

  depends_on = [aws_ec2_transit_gateway.transit_gateway]
}

# Drop in 0/0 to OBI VPC in TGW Main RTB
#resource "aws_ec2_transit_gateway_route" "obi" {
#  count                          = var.deploy_obi ? 1 : 0
#  destination_cidr_block         = "0.0.0.0/0"
#  transit_gateway_route_table_id = aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id
#  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.obitgw_attch[0].id
#
#  depends_on = [aws_ec2_transit_gateway.transit_gateway]
#
#}

resource "aws_ec2_transit_gateway_route" "obi" {
  count                          = var.deploy_obi ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.obitgw_attch[0].id

  depends_on = [aws_ec2_transit_gateway.transit_gateway]
}
