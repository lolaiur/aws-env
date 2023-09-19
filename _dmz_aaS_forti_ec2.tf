# ######## Fortigate Configuration ######
module "dmz_ftg_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = var.deploy_dmz_ftgs ? var.dmz_ftg_devices : {}
  name     = "dmz-${each.key}.ftg-vm"

  ami           = var.dmz_ftg_ami_id
  instance_type = var.dmz_ftg_instance_type
  #   key_name      = aws_key_pair.this.key_name
  monitoring = true

  network_interface = [
    {
      device_index         = 0
      network_interface_id = aws_network_interface.dmz_mgmt_ftg[each.key].id
    },
    {
      device_index         = 1
      network_interface_id = aws_network_interface.north_inspection_ftg[each.key].id
    },
    {
      device_index         = 2
      network_interface_id = aws_network_interface.south_inspection_ftg[each.key].id
    }
  ]

  user_data = data.template_file.dmz_ftg_config[each.key].rendered
}

resource "aws_network_interface" "dmz_mgmt_ftg" {
  for_each          = var.deploy_dmz_ftgs ? var.dmz_ftg_devices : {}
  subnet_id         = aws_subnet.dmz_vpc_management[each.value.az].id
  security_groups   = [aws_security_group.ftg_passthrough[0].id]
  source_dest_check = true
  private_ips       = [each.value.management_ip_address]

  tags = {
    "Name" = "dmz-${each.key}.ftg_mgmt.eni"
  }
}

resource "aws_network_interface" "north_inspection_ftg" {
  for_each          = var.deploy_dmz_ftgs ? var.dmz_ftg_devices : {}
  subnet_id         = aws_subnet.dmz_vpc_fw_inspection["north_${each.value.az}"].id
  security_groups   = [aws_security_group.ftg_passthrough[0].id]
  source_dest_check = false
  private_ips       = [each.value.north_inspection_address]

  tags = {
    "Name" = "north.ftg_inspection.${each.value.az}.eni"
  }
}

resource "aws_network_interface" "south_inspection_ftg" {
  for_each          = var.deploy_dmz_ftgs ? var.dmz_ftg_devices : {}
  subnet_id         = aws_subnet.dmz_vpc_fw_inspection["south_${each.value.az}"].id
  security_groups   = [aws_security_group.ftg_passthrough[0].id]
  source_dest_check = false
  private_ips       = [each.value.south_inspection_address]

  tags = {
    "Name" = "south.ftg_inspection.${each.value.az}.eni"
  }
}

### Security Groups ######
# Passthrough SG
resource "aws_security_group" "ftg_passthrough" {
  count       = var.deploy_dmz_ftgs ? 1 : 0
  name        = "dmz_vpc.ftg.passthrough"
  description = "Allow all traffic to transit FTG"
  vpc_id      = module.dmz_vpc[0].vpc_id

  tags = {
    "Name" = "dmz_vpc.ftg.passthrough.sg"
  }
}

resource "aws_security_group_rule" "ftg_passthrough_ingress" {
  count             = var.deploy_dmz_ftgs ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all traffic to transit FTG."
  security_group_id = aws_security_group.ftg_passthrough[0].id
}

resource "aws_security_group_rule" "ftg_passthrough_egress" {
  count             = var.deploy_dmz_ftgs ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all traffic to transit FTG."
  security_group_id = aws_security_group.ftg_passthrough[0].id
}

#########################################
#### Management Subnets & Routes
#########################################
resource "aws_subnet" "dmz_vpc_management" {
  for_each          = var.deploy_dmz ? { for k, v in var.dmz_management_subnets : k => v.management_subnet } : {}
  vpc_id            = module.dmz_vpc[0].vpc_id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    "Name" = "dmz-vpc.mgmt.${each.key}.subnet"
  }
}

# Create DMZ Management network
resource "aws_route_table" "dmz_vpc_management" {
  count  = var.deploy_dmz ? 1 : 0
  vpc_id = module.dmz_vpc[0].vpc_id

  tags = {
    "Name" = "dmz-vpc.mgmt.rt"
  }
}

# Associate mangement route tables with their subnets
resource "aws_route_table_association" "dmz_vpc_management" {
  for_each       = var.deploy_dmz ? { for k, v in var.dmz_management_subnets : k => v.management_subnet } : {}
  subnet_id      = aws_subnet.dmz_vpc_management[each.key].id
  route_table_id = aws_route_table.dmz_vpc_management[0].id
}

# Management to TGW bypass inspection, control access with SG on managment interfaces.
resource "aws_route" "dmz_vpc_management_to_tgw" {
  count                  = var.deploy_dmz ? 1 : 0
  route_table_id         = aws_route_table.dmz_vpc_management[0].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id
}

#########################################
#### Inspection Subnets & Route tables
#########################################
resource "aws_subnet" "dmz_vpc_fw_inspection" {
  for_each          = var.deploy_dmz ? local.dmz_inspection_all_subnets_key : {}
  vpc_id            = module.dmz_vpc[0].vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.subnet_az

  tags = {
    "Name" = "dmz-vpc.${each.value.zone}_ftg_inspection.${each.value.subnet_az}.subnet"
  }
}

# Create DMZ Management network
resource "aws_route_table" "dmz_vpc_fw_inspection" {
  for_each = var.deploy_dmz ? var.dmz_zones : {}
  vpc_id   = module.dmz_vpc[0].vpc_id

  tags = {
    "Name" = "dmz-vpc.mgmt.rt"
  }
}

# Associate mangement route tables with their subnets
resource "aws_route_table_association" "dmz_vpc_fw_inspection" {
  for_each       = var.deploy_dmz ? local.dmz_inspection_all_subnets_key : {}
  subnet_id      = aws_subnet.dmz_vpc_fw_inspection[each.key].id
  route_table_id = aws_route_table.dmz_vpc_fw_inspection[each.value.zone].id
}