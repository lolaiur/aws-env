module "vpcVPN" {
  count = var.deploy_ovp ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "openVPN-vpc"
  cidr = "10.255.255.0/24"

  azs           = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  intra_subnets = ["10.255.255.0/27"]

  #private_subnet_ipv6_prefixes    = [0, 1, 2]
  create_egress_only_igw          = false
  enable_nat_gateway              = false
  enable_vpn_gateway              = false
  create_elasticache_subnet_group = false
  create_igw                      = false
  manage_default_route_table      = false
  manage_default_security_group   = false

  tags = {
    "Env" = "OpenVPN-VPC"
  }
}

resource "aws_route" "intraVPN" {
  count                  = var.deploy_ovp ? 1 : 0
  route_table_id         = module.vpcVPN[0].intra_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

resource "aws_route" "vpn_vpc_to_my_ip" {
  count          = var.deploy_ovp ? 1 : 0
  route_table_id = module.vpcVPN[0].intra_route_table_ids[0]
  #  destination_cidr_block = "${var.my_ip}/32"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpn_vpc_igw[0].id
}

resource "aws_subnet" "vpntgw" {
  count             = var.deploy_ovp ? 1 : 0
  vpc_id            = module.vpcVPN[0].vpc_id
  availability_zone = module.vpcVPN[0].azs[0]
  cidr_block        = "10.255.255.224/27"

  tags = {
    "Name" = "OpenVPN TGW Subnet"
  }
}

resource "aws_route_table" "vpntgw" {
  count  = var.deploy_ovp ? 1 : 0
  vpc_id = module.vpcVPN[0].vpc_id

  tags = {
    "Name" = "OpenVPN TGW RTB"
  }
}

resource "aws_route_table_association" "vpntgw" {
  count          = var.deploy_ovp ? 1 : 0
  subnet_id      = aws_subnet.vpntgw[0].id
  route_table_id = aws_route_table.vpntgw[0].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpntgw_attch" {
  count              = var.deploy_ovp ? 1 : 0
  subnet_ids         = [aws_subnet.vpntgw[0].id]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = module.vpcVPN[0].vpc_id
}

resource "aws_instance" "vpnserver" {
  count = var.deploy_ovp ? 1 : 0
  #ami                   = "ami-0f95ee6f985388d58" # OpenVPN
  ami                    = "ami-0e13330257b20a8e4" # Amazon Linux 2
  instance_type          = "t2.small"
  subnet_id              = module.vpcVPN[0].intra_subnets[0]
  vpc_security_group_ids = [aws_security_group.vpnec2[0].id]
  key_name               = aws_key_pair.vpn_ec2_key.key_name

  tags = {
    Name = "OpenVPN-Server"
  }
  depends_on = [module.vpcVPN]
}

resource "aws_eip" "vpnserver_eip" {
  count = var.deploy_ovp ? 1 : 0
  tags = {
    Name = "OpenVPN-Server-EIP"
  }
}

resource "aws_internet_gateway" "vpn_vpc_igw" {
  count = var.deploy_ovp ? 1 : 0

  vpc_id = module.vpcVPN[0].vpc_id

  tags = {
    Name = "OpenVPN-VPC-IGW"
  }
}

# Associate the EIP with the EC2 instance
resource "aws_eip_association" "vpnserver_eip_association" {
  count         = var.deploy_ovp ? 1 : 0
  instance_id   = aws_instance.vpnserver[0].id
  allocation_id = aws_eip.vpnserver_eip[0].id
}

### SG

resource "aws_security_group" "vpnec2" {
  count       = var.deploy_ovp ? 1 : 0
  name        = "OpenVPN EC2 SG"
  description = "Security group for OpenVPN EC2"
  vpc_id      = module.vpcVPN[0].vpc_id


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

  tags = {
    Name = "openvpn-sg"
  }
}

resource "aws_key_pair" "vpn_ec2_key" {
  key_name   = "openVPN_key"
  public_key = var.public_key

  tags = {
    Name = "OpenVPN Key"
  }
}
