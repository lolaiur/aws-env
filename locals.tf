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
  # vpc_subnets = flatten([
  #   for vpc_key, vpc in module.vpc : [
  #     for subnet in vpc.intra_subnets : {
  #       vpc_key   = vpc_key
  #       subnet_id = subnet
  #     }
  #   ]
  # ])

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

  local_path = replace("${var.storage_path}", "/", "\\")

  defaults = {
    rules_ingress = [
      {
        type        = "ingress"
        from_port   = var.ssh_port
        to_port     = var.ssh_port
        protocol    = "tcp"
        cidr_blocks = [var.ssh_cidr]
      },
      {
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        type        = "ingress"
        from_port   = 943
        to_port     = 943
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        type        = "ingress"
        from_port   = 1194
        to_port     = 1194
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }

  input = {
    rules_ingress = try(var.rules_ingress, [])
  }

  generated = {
    rules_ingress = concat(local.defaults.rules_ingress, local.input.rules_ingress)
  }

  #all_vpcs = merge(
  #  { for k, v in module.vpc : k => v.vpc_id },
  #  { "vpcVPN" = module.vpcVPN[0].vpc_id }
  #)

  all_vpcs = var.deploy_ovp ? merge(
    { for k, v in module.vpc : k => v.vpc_id },
    { "vpcVPN" = module.vpcVPN[0].vpc_id }
  ) : { for k, v in module.vpc : k => v.vpc_id }

  vpc_references = toset([for server in values(var.ec2) : server.vpc])
  #vpc_ids = { for v in local.vpc_references : v => module[v].vpc_id }

  ### USER DATA LOCALS ###
  # Windows User Data
  windows_userdata = <<-EOT
    <powershell>
    $username = "aiur"
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
    username="aiur"
    password="${var.os_pass}"
    sudo useradd -m $username
    echo "$username:$password" | sudo chpasswd
    sudo usermod -aG wheel $username
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
  EOT

  # outputs = {
  #   rules_ingress = local.generated.rules_ingress
  # }

  # ec2_names = [for instance in aws_instance.server : instance.tags["Name"]]
  #first_zone_id = values(aws_route53_zone.private_zone)[0].zone_id

  #zone_vpc_associations = var.deploy_dns ? { for k, v in aws_route53_zone.private_zone : k => {
  #    zone_id = v.zone_id
  #    vpc_id  = tolist(v.vpc)[0].vpc_id
  #  }
  #} : {}

  # Flattening subnets to make it easier to reference them individually. 
  #flattened_subnets = flatten([
  #  for region, vpcs in var.vpcs : [
  #    for vpc_name, vpc_data in vpcs : [
  #      for index in range(length(vpc_data.subnet)) : {
  #        region   = region
  #        vpc_name = vpc_name
  #        vpc_data = vpc_data
  #        subnet   = vpc_data.subnet[index]
  #        index    = index
  #      }
  #    ]
  #  ]
  #])
}
