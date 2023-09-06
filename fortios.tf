#### NOT READY / NOT WORKING !!! but it could work...

#provider "fortios" {
#
#  hostname = "ftg01"
#  token    = var.forti_token # So far, unable to conditionalize any of this. 
#  insecure = true
#}
/*
provider "fortios" {
  hostname = var.deploy_cfg ? "10.253.225.46" : null
  token    = "G184Nhwjdn88sGfHsrGtd6H5k6qfNy"
  insecure = true
}

# Set FortiOS VDOM -- Appears to note be needed
#resource "fortios_system_vdom" "ftgos-vdom" {
#  count = var.deploy_cfg ? 1 : 0
#  
#  name       = "root"
#  short_name = "root"
#  temporary  = 0
#}

## Routes
resource "fortios_router_static" "ftgos-rtr-static-1" {
  count   = var.deploy_cfg ? 1 : 0
  vrf     = 2
  seq_num = 1
  device  = fortios_system_interface.ftgos-sys-int-2[0].name
  gateway = local.inspection_first_usable_ip
  dst     = local.gwlb_ip # Needs to point to GWLB IP for AZ
}

#resource "fortios_router_static" "ftgos-rtr-static-1a" { # Maybe Fixed
#  count   = var.deploy_cfg ? 1 : 0
#  vrf     = 2
#  seq_num = 2
#  device  = fortios_system_geneve.ftgos-sys-gen[0].name
#  dst     = "0.0.0.0/0.0.0.0"
#  gateway = "0.0.0.0"
#}

resource "fortios_system_zone" "ftgos-sys-zone" {
  count = var.deploy_cfg ? 1 : 0
  name  = "gwlb-tunnels"

  interface {
    interface_name = fortios_system_geneve.ftgos-sys-gen[0].name
  }
}


# Sets up Probe 
resource "fortios_system_proberesponse" "ftgos-sys-probe" {
  http_probe_value = "OK"
  mode             = "none"
  port             = 8008
  security_mode    = "none"
  timeout          = 300
  ttl_mode         = "retain"
  
}

# Configures interfaces
resource "fortios_system_interface" "ftgos-sys-int-1" { # Mgmt Interface
  count       = var.deploy_cfg ? 1 : 0
  name        = "port1"
  vdom        = "root"
  vrf         = 1
  mode        = "dhcp"
  type        = "physical"
  allowaccess = "ping https ssh http fgfm"
  interface   = "port1"
}

resource "fortios_system_interface" "ftgos-sys-int-2" { # Inspection Interface
  count       = var.deploy_cfg ? 1 : 0
  name        = "port2"
  interface   = "port2"
  vdom        = "root"
  vrf         = 2
  mode        = "dhcp"
  type        = "physical"
  allowaccess = "probe-response geneve http https"
  defaultgw   = "disable"
}

#resource "fortios_system_interface" "ftgos-sys-int-3" { # Tunnel Interface
#  count     = var.deploy_cfg ? 1 : 0
#  name      = fortios_system_geneve.ftgos-sys-gen[0].name
#  vdom      = "root"
#  vrf       = 2
#  mode      = "dhcp" # not needed?
#  type      = "geneve"
#  interface = "port3"
#  defaultgw = "disable"
#}

# Configure FortiOS GENEVE
resource "fortios_system_geneve" "ftgos-sys-gen" {
  count      = var.deploy_cfg ? 1 : 0
  name       = "gwlbe-gen"
  interface  = "port2"
  ip_version = "ipv4-unicast"
  vni        = 0
  remote_ip  = data.aws_network_interface.endpoint[0].private_ip
  type       = "ppp"
}

# Configure Router Policy
resource "fortios_router_policy" "ftgos-rtr-policy-1" {
  count   = var.deploy_cfg ? 1 : 0
  seq_num = 1
  gateway = "0.0.0.0"

  dst {
    subnet = "0.0.0.0/0.0.0.0"
  }
  src {
    subnet = "0.0.0.0/0.0.0.0"
  }

  input_device {
    name = fortios_system_geneve.ftgos-sys-gen[0].name
  }

  output_device = fortios_system_geneve.ftgos-sys-gen[0].name
}


# FW Policy Configuration Below
resource "fortios_firewall_policy" "ftgos-fw-policy-1" {
  count      = var.deploy_cfg ? 1 : 0
  name       = "Main"
  policyid   = 1
  utm_status = "enable"
  logtraffic = "all"
  action     = "accept"
  schedule   = "always"
  nat        = "disable"

  srcintf {
    name = fortios_system_zone.ftgos-sys-zone[0].name
  }

  dstintf {
    name = fortios_system_zone.ftgos-sys-zone[0].name
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = "all"
  }

  service {
    name = "HTTPS"
  }
  service {
    name = "HTTP"

  }
  service {
    name = "ALL_ICMP"
  }
}

*/