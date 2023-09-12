data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Collects GWLBe IP for FortiOS remote_ip
data "aws_network_interface" "endpoint" {
  count = var.deploy_obi ? 1 : 0
  id    = tolist(aws_vpc_endpoint.gwlbe[0].network_interface_ids)[0]
}

data "aws_network_interfaces" "gwlb_enis" {
  count = var.deploy_obi ? 1 : 0
  filter {
    name   = "description"
    values = ["ELB gwy/${aws_lb.gwlb[0].name}/*"]
  }
}

data "aws_network_interface" "gwlb_eni" {
  for_each = var.deploy_obi ? var.ftg : {}

  filter {
    name   = "description"
    values = ["ELB gwy/${aws_lb.gwlb[0].name}/*"]
  }

  filter {
    name   = "subnet-id"
    values = [aws_subnet.gwlb[tonumber(each.value.az)].id]
  }
}

data "template_file" "ftg_config" {
  for_each = var.deploy_obi ? var.ftg : {}

  template = file("./forti.tpl")

  vars = {
    gwlb_ip                    = data.aws_network_interface.gwlb_eni[each.key].private_ips[0],
    gwlb_subnet_mask_decimal   = cidrnetmask(aws_subnet.gwlb[0].cidr_block),
    inspection_subnet          = var.obi["inspection"][tonumber(var.ftg[each.key]["az"])],
    inspection_first_usable_ip = "${split(".", cidrhost(var.obi["inspection"][tonumber(var.ftg[each.key]["az"])], 1))[0]}.${split(".", cidrhost(var.obi["inspection"][tonumber(var.ftg[each.key]["az"])], 1))[1]}.${split(".", cidrhost(var.obi["inspection"][tonumber(var.ftg[each.key]["az"])], 1))[2]}.${split(".", cidrhost(var.obi["inspection"][tonumber(var.ftg[each.key]["az"])], 1))[3]}",
    hostname                   = each.key
    user                       = var.os_user
    pass                       = var.os_pass
  }
}
