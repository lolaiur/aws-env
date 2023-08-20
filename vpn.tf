resource "aws_customer_gateway" "customer_gw" {
  count = var.deploy_vpn ? 1 : 0
  # other customer gateway configurations
  bgp_asn    = 65000
  ip_address = var.my_ip
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_connection" {
  count = var.deploy_vpn ? 1 : 0

  type                     = aws_customer_gateway.customer_gw[0].type
  transit_gateway_id       = aws_ec2_transit_gateway.transit_gateway.id
  customer_gateway_id      = aws_customer_gateway.customer_gw[0].id
  tunnel1_inside_cidr      = "169.254.10.0/30"
  local_ipv4_network_cidr  = "10.0.0.0/8"
  remote_ipv4_network_cidr = "192.168.0.0/16"
  depends_on               = [aws_ec2_transit_gateway.transit_gateway]
  tunnel1_preshared_key    = "akey2share"
  tunnel2_preshared_key    = "akey2share"
}
