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

  #all_vpcs = merge(
  #  { for k, v in module.vpc : k => v.vpc_id },
  #  { "vpcVPN" = module.vpcVPN[0].vpc_id }
  #)


  #vpc_ids = { for v in local.vpc_references : v => module[v].vpc_id }

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

  ## Forti Route Calculations
  # Split the CIDR into IP and Prefix Length
  gwlb_subnet_ip_parts   = var.deploy_oig ? split(".", split("/", aws_subnet.gwlb[0].cidr_block)[0]) : []
  gwlb_subnet_prefix_len = var.deploy_oig ? split("/", aws_subnet.gwlb[0].cidr_block)[1] : ""

  # Convert prefix length to dotted decimal netmask
  gwlb_subnet_mask_decimal = var.deploy_oig ? cidrnetmask(aws_subnet.gwlb[0].cidr_block) : ""

  # Increment the last octet of the IP address by 1 to get the first usable IP
  gwlb_first_usable_ip = var.deploy_oig ? "${local.gwlb_subnet_ip_parts[0]}.${local.gwlb_subnet_ip_parts[1]}.${local.gwlb_subnet_ip_parts[2]}.${tonumber(local.gwlb_subnet_ip_parts[3]) + 1}" : ""

  # Final formatted string
  gwlb_dst_value = var.deploy_oig ? "${local.gwlb_first_usable_ip} ${local.gwlb_subnet_mask_decimal}" : ""

  # Determines VPC Router for Forti Static Routes
  inspection_subnet_ip_parts = var.deploy_oig ? split(".", cidrhost(aws_subnet.inspection[0].cidr_block, 1)) : []
  inspection_first_usable_ip = var.deploy_oig ? "${local.inspection_subnet_ip_parts[0]}.${local.inspection_subnet_ip_parts[1]}.${local.inspection_subnet_ip_parts[2]}.${local.inspection_subnet_ip_parts[3]}" : ""


  # Derives GWIB from data source query 
  gwlb_ip = var.deploy_oig ? data.aws_network_interface.gwlb_eni[0].private_ips[0] : ""

  ##### FORTI CONFIG #####
  config_script = <<-EOT
config system admin
  edit ${var.os_user}
    set password ${var.os_pass}
    set accprofile super_admin
    end
  exit
end    
config system global
    set alias "FTG01"
    set allow-traffic-redirect disable
    set hostname "FTG01"
    set ipv6-allow-traffic-redirect disable
    set timezone 04
end
config system accprofile
    edit "api"
        set secfabgrp read-write
        set ftviewgrp read-write
        set authgrp read-write
        set sysgrp read-write
        set netgrp read-write
        set loggrp read-write
        set fwgrp read-write
        set vpngrp read-write
        set utmgrp read-write
        set wanoptgrp read-write
        set wifi read-write
    next
end
config system geneve
    edit "gwlbe-gen"
      set interface "port2"
      set type ppp
      set remote-ip ${local.gwlb_ip}
    next
end
config system interface
    edit "gwlbe-gen"
        set vdom "root"
        set vrf 2
        set type geneve
        set snmp-index 8
        set interface "port2"
    next
    edit "port1"
        set vdom "root"
        set vrf 1
        set mode dhcp
        set allowaccess ping https ssh http fgfm
        set type physical
        set snmp-index 1
        set mtu-override enable
        set mtu 9001
    next
    edit "port2"
        set vdom "root"
        set vrf 2
        set mode dhcp
        set allowaccess https http probe-response
        set type physical
        set snmp-index 2
        set defaultgw disable
        set mtu-override enable
        set mtu 9001
    next
    edit "port3"
        set vdom "root"
        set mode dhcp
        set type physical
        set snmp-index 3
        set defaultgw disable
        set mtu-override enable
        set mtu 9001
    next
end
config system api-user
    edit "api-admin"
        set api-key ENC SH2KG/ZD9yUHkemXhLydqeZ6fgzNX7UXZ2x8n53S6fUtWLKxo2T3BaE79ky37g=
        set accprofile "api"
        set vdom "root"
    next
end
config system probe-response
    set port 8008
    set http-probe-value "OK"
    set mode http-probe
end
config firewall policy
    edit 1
        set name "Main"
        set srcintf "gwlbe-gen"
        set dstintf "gwlbe-gen"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "HTTPS" "HTTP" "ALL_ICMP"
        set utm-status enable
        set logtraffic all
    next
end
    config router static
        edit 1
            set dst ${local.gwlb_ip} ${local.gwlb_subnet_mask_decimal}
            set gateway ${local.inspection_first_usable_ip}
            set device "port2"
        next
    edit 2
        set device "gwlbe-gen"
    next
end
config router policy
    edit 1
        set input-device "gwlbe-gen"
        set src "0.0.0.0/0.0.0.0"
        set dst "0.0.0.0/0.0.0.0"
        set output-device "gwlbe-gen"
    next
end
  EOT


}
