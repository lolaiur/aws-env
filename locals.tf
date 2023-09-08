locals {
  # Flattening the VPCs to a list for easier iteration.
  flattened_vpcs = flatten([
    for region, vpcs in var.vpcs : [
      for vpc_name, vpc_data in vpcs : {
        region   = region
        vpc_name = vpc_name
        vpc_data = vpc_data
      }
    ]
  ])

  # Flattening the VPCs and Transit Gateway (TGW) configuration into a list for easier iteration.
  flattened_vpcs_tgw = flatten([
    for region, vpcs in var.vpcs : [
      for vpc_name, vpc_data in vpcs : [
        for index, tgw in vpc_data.tgw : {
          region   = region
          vpc_name = vpc_name
          vpc_data = vpc_data
          tgw      = tgw
          index    = index
          subnet   = vpc_data.subnet
        }
      ]
    ]
  ])

  # Collecting VPC subnets into a list for easy reference.
  vpc_subnets = flatten([
    for region, vpcs in var.vpcs : [
      for vpc_key, vpc in vpcs : [
        for subnet_cidr in vpc.subnet : {
          subnet_id = subnet_cidr
          vpc_key   = "${region}-${vpc_key}"
        }
      ]
    ]
  ])
  #

  # Flattening VPCs for TGW attachment.
  flattened_vpcs_for_tgw_attachment = flatten([
    for region, vpcs in var.vpcs : [
      for vpc_name, vpc_data in vpcs : {
        region      = region
        vpc_name    = vpc_name
        vpc_data    = vpc_data
        tgw_subnets = vpc_data.tgw
      }
    ]
  ])

  # Collecting route table associations from the configuration.
  route_table_associations = flatten([
    for rt_key, rt_value in var.route_tables : [
      for attch_num in range(length(try(rt_value.associations, []))) : {
        unique_key                     = "${rt_key}-${rt_value.associations[attch_num]}"
        route_table_key                = rt_key
        attch_index                    = attch_num
        tgw_attachment_id              = rt_value.associations[attch_num]
        transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
        tgw_route_table_id             = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
      }
    ]
  ])

  # Collecting route table propagations.
  route_table_propagations = flatten([
    for rt_key, rt_value in var.route_tables : [
      for attch_num in range(length(try(rt_value.propagations, []))) : {
        unique_key                     = "${rt_key}-${rt_value.propagations[attch_num]}"
        route_table_key                = rt_key
        attch_index                    = attch_num
        tgw_attachment_id              = rt_value.propagations[attch_num]
        transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
        tgw_route_table_id             = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
      }
    ]
  ])

  # Static routes to be applied to the TGW route table.
  static_routes = flatten([
    for rt_key, rt_value in var.route_tables : [
      for cidr, attach_id in try(rt_value.static_routes, {}) : {
        unique_key                     = "${rt_key}-${cidr}"
        route_table_key                = rt_key
        destination_cidr_block         = cidr
        transit_gateway_attachment_id  = attach_id
        transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
      }
    ]
  ])

  # Blackhole routes for the TGW route table (used to drop traffic to specific CIDRs).
  blackhole_routes = flatten([
    for rt_key, rt_value in try(var.route_tables, []) : [
      for cidr in try(rt_value.blackhole_routes, []) : {
        unique_key                     = "${rt_key}-${cidr}"
        route_table_key                = rt_key
        destination_cidr_block         = cidr
        transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.route_table[rt_key].id
      }
    ]
  ])


  # Dynamically handling obi-plus RT creation
  obi_rt_associations = {
    "mgmt"       = var.obi.mgmt,
    "inspection" = var.obi.inspection,
    "gwlb"       = var.obi.gwlb,
    "nat"        = var.obi.nat,
    "obi-tgw"    = var.obi.tgw
    "igw"        = ""
  }


  #### EC2 CREATION

  # Mapping of OS aliases to their respective AMI IDs.
  amis = {
    win = "ami-04132f301c3e4f138" # Microsoft Windows Server 2022 Full Locale English AMI provided by Amazon
    lnx = "ami-06ca3ca175f37dd66" # Amazon Linux 2023 AMI 2023.1.20230705.0 x86_64 HVM kernel-6.1
  }
  templates_path = format("%s/%s", "/var/tmp/scripts", "openvpn")
  templates = {
    vpn = {
      install = {
        template = format("%s/%s", path.module, "scripts/openvpn/install.tpl.sh")
        file     = format("%s/%s", local.templates_path, "/install.sh")
        vars = {
          #  public_ip = aws_eip.vpnserver_eip[0].public_ip
          public_ip = length(aws_eip.vpnserver_eip) > 0 ? aws_eip.vpnserver_eip[0].public_ip : null # Conditionally handles OpenVPN Toggle
          client    = var.admin_user
        }
      }
      update_user = {
        template = format("%s/%s", path.module, "scripts/openvpn/update_user.tpl.sh")
        file     = format("%s/%s", local.templates_path, "/update_user.sh")
        vars = {
          client = var.admin_user
        }
      }
    }
  }

  local_path = replace(var.storage_path, "/", "\\")

  ### USER DATA LOCALS ###
  # Windows User Data
  windows_userdata = <<-EOT
    <powershell>
    $username = "${var.os_user}"
    $password = "${var.os_pass}"
    $passwordPlainText = $password
    $computer = [ADSI]"WinNT://$env:COMPUTERNAME,Computer"
    $securePassword = ConvertTo-SecureString -String $passwordPlainText -AsPlainText -Force
    New-LocalUser -Name $username -Password $securePassword
    # Add the user to the local Administrators group
    net localgroup Administrators /add $username
    # Disable the Windows Firewall for all profiles
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    </powershell>
  EOT

  # Linux User Data
  linux_userdata = <<-EOT
    #!/bin/bash
    username="${var.os_user}"
    password="${var.os_pass}"
    sudo useradd -m $username
    echo "$username:$password" | sudo chpasswd
    sudo usermod -aG wheel $username
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
  EOT

  eni_map = { for idx, key in sort(keys(var.ftg)) : key => data.aws_network_interfaces.gwlb_enis[0].ids[idx] }

  az_mapping = {
    "0" = "us-east-1a",
    "1" = "us-east-1b",
    "2" = "us-east-1c"
  }

  azs_raw = [for val in var.ftg : local.az_mapping[val.az]]
  azs     = { for idx, az in local.azs_raw : idx => az }
}
