
### Dynamically creates typical VPCs with full routing towards TGW

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  for_each = { for v in local.flattened_vpcs : "${v.region}-${v.vpc_name}" => v }

  name = each.value.vpc_name
  cidr = each.value.vpc_data.cidr

  azs           = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  intra_subnets = each.value.vpc_data.subnet

  #private_subnet_ipv6_prefixes    = [0, 1, 2]
  create_egress_only_igw          = false
  enable_nat_gateway              = false
  enable_vpn_gateway              = false
  create_elasticache_subnet_group = false
  create_igw                      = false
  manage_default_route_table      = false
  manage_default_security_group   = false

  tags = {
    "Env" = each.value.vpc_data.env
  }
}

### VPC TGW Route Table, Attachment, and Association

resource "aws_subnet" "tgw" {
  for_each          = { for v in local.flattened_vpcs_tgw : "${v.region}-${v.vpc_name}-${replace(v.tgw, ".", "-")}" => v }
  vpc_id            = module.vpc["${each.value.region}-${each.value.vpc_name}"].vpc_id
  cidr_block        = each.value.tgw
  availability_zone = module.vpc["${each.value.region}-${each.value.vpc_name}"].azs[each.value.index]

  tags = {
    "Name" = "${each.value.region}-${each.value.vpc_name}-${module.vpc["${each.value.region}-${each.value.vpc_name}"].azs[each.value.index]}.tgw.sub"
    "Env"  = each.value.vpc_data.env
  }
}

resource "aws_route_table" "tgw" {
  for_each = { for v in local.flattened_vpcs_tgw : "${v.region}-${v.vpc_name}-${replace(v.tgw, ".", "-")}" => v }
  vpc_id   = module.vpc["${each.value.region}-${each.value.vpc_name}"].vpc_id

  tags = {
    "Name" = "${each.value.vpc_name}.tgw.rt"
    "Env"  = each.value.vpc_data.env
  }
}

resource "aws_route_table_association" "tgw" {
  for_each       = { for v in local.flattened_vpcs_tgw : "${v.region}-${v.vpc_name}-${replace(v.tgw, ".", "-")}" => v }
  subnet_id      = aws_subnet.tgw[each.key].id
  route_table_id = aws_route_table.tgw[each.key].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attch" {
  for_each           = { for v in local.flattened_vpcs_for_tgw_attachment : "${v.region}-${v.vpc_name}" => v }
  subnet_ids         = [for subnet in aws_subnet.tgw : subnet.id if contains(each.value.tgw_subnets, subnet.cidr_block)]
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  vpc_id             = module.vpc["${each.value.region}-${each.value.vpc_name}"].vpc_id

  tags = {
    "Name" = "${each.value.region}-${each.value.vpc_name}-tgw-attch"
  }
}

# VPC Route Creation*
resource "aws_route" "intra" {
  for_each               = { for subnet in local.vpc_subnets : subnet.subnet_id => subnet } # pain
  route_table_id         = module.vpc[each.value.vpc_key].intra_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.transit_gateway.id

  depends_on = [module.vpc]
}