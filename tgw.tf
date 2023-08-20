resource "aws_ec2_transit_gateway" "transit_gateway" {
  description                     = "Main-TGW"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
}

resource "aws_ec2_transit_gateway_route_table" "route_table" {
  for_each           = var.route_tables
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags = {
    Name = "${each.key}.rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "association" {
  for_each = { for assoc in local.route_table_associations : assoc.unique_key => assoc }

  transit_gateway_attachment_id  = each.value.tgw_attachment_id
  transit_gateway_route_table_id = each.value.tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "propagations" {
  for_each = { for prop in local.route_table_propagations : prop.unique_key => prop }

  transit_gateway_attachment_id  = each.value.tgw_attachment_id
  transit_gateway_route_table_id = each.value.tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route" "static_route" {
  for_each = length(local.static_routes) > 0 ? { for route in local.static_routes : route.unique_key => route } : {}

  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.transit_gateway_route_table_id
}

resource "aws_ec2_transit_gateway_route" "blackhole_route" {
  for_each = length(local.blackhole_routes) > 0 ? { for route in local.blackhole_routes : route.unique_key => route } : {}

  destination_cidr_block         = each.value.destination_cidr_block
  blackhole                      = true
  transit_gateway_route_table_id = each.value.transit_gateway_route_table_id
}
