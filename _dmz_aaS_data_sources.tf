data "aws_subnet" "tgw" {
  for_each   = var.deploy_dmz ? merge([for k, v in local.tgw_subnets_keys : { "${v.vpc_name}" = v }]...) : {}
  vpc_id     = module.vpc[each.value.vpc_name].vpc_id
  cidr_block = each.value.cidr

  depends_on = [module.vpc, aws_subnet.tgw]
}

data "aws_route_table" "tgw" {
  for_each  = var.deploy_dmz ? { for subnet, subnet_value in data.aws_subnet.tgw : "${subnet}" => subnet_value.id } : {}
  subnet_id = each.value
}

# Creates a template for DMZ Fortigate configuration used in User Data
data "template_file" "dmz_ftg_config" {
  for_each = var.deploy_dmz_ftgs ? var.dmz_ftg_devices : {}

  template = file("./dmz_forti.tpl")

  vars = {
    gwlb_ip_2                    = data.aws_network_interface.dmz_gwlb_eni["north_${each.value.az}"].private_ip,
    gwlb_subnet_mask_decimal_2   = cidrnetmask(aws_subnet.dmz_vpc_loadbalancer["north_${each.value.az}"].cidr_block),
    inspection_subnet_2          = aws_subnet.dmz_vpc_fw_inspection["north_${each.value.az}"].cidr_block,
    inspection_first_usable_ip_2 = cidrhost(aws_subnet.dmz_vpc_fw_inspection["north_${each.value.az}"].cidr_block, 1)
    gwlb_ip_3                    = data.aws_network_interface.dmz_gwlb_eni["south_${each.value.az}"].private_ip,
    gwlb_subnet_mask_decimal_3   = cidrnetmask(aws_subnet.dmz_vpc_loadbalancer["south_${each.value.az}"].cidr_block),
    inspection_subnet_3          = aws_subnet.dmz_vpc_fw_inspection["south_${each.value.az}"].cidr_block,
    inspection_first_usable_ip_3 = cidrhost(aws_subnet.dmz_vpc_fw_inspection["south_${each.value.az}"].cidr_block, 1)
    hostname                     = "dmz-${each.key}"
    user                         = var.os_user
    pass                         = var.os_pass
  }
}

data "aws_network_interfaces" "dmz_gwlb_enis" {
  for_each = var.deploy_dmz_ftgs ? { for k, v in local.gwlb_subnets : k => v } : {}

  filter {
    name   = "description"
    values = ["ELB gwy/${aws_lb.dmz_vpc_gwlb[each.value.zone].name}/*"]
  }

}

data "aws_network_interface" "dmz_gwlb_eni" {
  for_each = var.deploy_dmz_ftgs ? { for k, v in local.gwlb_subnets : k => v } : {}

  filter {
    name   = "description"
    values = ["ELB gwy/${aws_lb.dmz_vpc_gwlb[each.value.zone].name}/*"]
  }
  filter {
    name   = "subnet-id"
    values = [aws_subnet.dmz_vpc_loadbalancer[each.key].id]
  }
}
