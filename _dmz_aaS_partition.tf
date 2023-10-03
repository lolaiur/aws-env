##################################
#### IGW and Routes 
##################################

# Create IGW for DMZ
resource "aws_internet_gateway" "dmz_in_vpc_igw" {
  for_each = var.deploy_dmz ? local.igw_route_table_keys : {}
  vpc_id   = module.vpc[each.key].vpc_id

  tags = {
    Name = "DMZ-${each.key}-IGW"
  }
}

# Create IGW route table
resource "aws_route_table" "dmz_in_vpc_igw" {
  for_each = var.deploy_dmz ? local.igw_route_table_keys : {}
  vpc_id   = module.vpc[each.key].vpc_id

  tags = {
    Name = "dmz-${each.key}-vpc.igw.rt"
  }
}

# Assocation IGW route table
resource "aws_route_table_association" "dmz_in_vpc_igw" {
  for_each       = var.deploy_dmz ? local.igw_route_table_keys : {}
  gateway_id     = aws_internet_gateway.dmz_in_vpc_igw[each.key].id
  route_table_id = aws_route_table.dmz_in_vpc_igw[each.key].id
}

# For partition networks route all ingress from IGW to the North GWLBe aligned with the destination network's AZ
resource "aws_route" "igw_to_partitions_az_vpce" {
  for_each               = var.deploy_dmz ? local.igw_routes : {}
  route_table_id         = aws_route_table.dmz_in_vpc_igw[each.value.vpc_name].id
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = aws_vpc_endpoint.dmz_in_vpc_gwlb["north_${each.value.vpc_name}_${each.value.subnet_az}"].id
}

##################################
#### TGW and Routes 
##################################

resource "aws_route" "dmz_in_vpc_tgw_to_az_vpce" {
  for_each               = var.deploy_dmz ? { for k, v in local.tgw_routes : k => v if v.subnet_type != "management_subnet" } : {}
  route_table_id         = each.value.tgw_route_table
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = aws_vpc_endpoint.dmz_in_vpc_gwlb["south_${each.value.vpc_name}_${each.value.subnet_az}"].id
}

##################################
# GWLB Endpoints
##################################

resource "aws_subnet" "dmz_in_vpc_vpce" {
  for_each          = var.deploy_dmz ? local.dmz_in_vpc_gwlbes : {}
  vpc_id            = module.vpc[each.value.vpc_name].vpc_id
  cidr_block        = each.value.inspection_subnet
  availability_zone = each.value.az

  tags = {
    "Name" = "DMZaaS-${each.value.vpc_name}.${each.value.zone}_vpce.subnet"
  }
}

resource "aws_route_table" "dmz_in_vpc_north_south_vpce" {
  for_each = var.deploy_dmz ? { for key, value in local.dmz_in_vpc_gwlbes : "${value.zone}_${value.vpc_name}" => value.vpc_name... } : {}
  vpc_id   = module.vpc[each.value[0]].vpc_id

  tags = {
    Name = "DMZaaS.${each.key}_vpce.rt"
  }
}

# GWLB route table associations
resource "aws_route_table_association" "dmz_in_vpc_vpce" {
  for_each       = var.deploy_dmz ? local.dmz_in_vpc_gwlbes : {}
  subnet_id      = aws_subnet.dmz_in_vpc_vpce[each.key].id
  route_table_id = aws_route_table.dmz_in_vpc_north_south_vpce[each.value.route_table].id
}

# Create a GWLBe (VPCe) in each az associated to each of the load balancers (North/South)
resource "aws_vpc_endpoint" "dmz_in_vpc_gwlb" {
  for_each          = var.deploy_dmz ? local.dmz_in_vpc_gwlbes : {}
  service_name      = aws_vpc_endpoint_service.dmz_vpc_gwlb[each.value.zone].service_name
  subnet_ids        = [aws_subnet.dmz_in_vpc_vpce[each.key].id]
  vpc_endpoint_type = aws_vpc_endpoint_service.dmz_vpc_gwlb[each.value.zone].service_type
  vpc_id            = module.vpc[each.value.vpc_name].vpc_id
  tags = {
    "Name" = "DMZaaS.${each.value.zone}.gwlb.${each.value.az}.vpce"
  }
}

# GWLB routes to IGW and TGW
resource "aws_route" "dmz_in_vpc_loadbalancer_igw_tgw" {
  for_each               = var.deploy_dmz ? merge(toset([for k, v in local.dmz_in_vpc_gwlbes : { "${v.zone}_${v.vpc_name}" = v.zone }])...) : {}
  route_table_id         = aws_route_table.dmz_in_vpc_north_south_vpce["${each.key}"].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = each.value == "south" ? aws_ec2_transit_gateway.transit_gateway.id : null
  gateway_id             = each.value == "north" ? aws_internet_gateway.dmz_in_vpc_igw["${substr(each.key, 6, length(each.key) - 5)}"].id : null

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.dmz_vpc_tgw_subnets, aws_internet_gateway.dmz_vpc_igw]
}

##################################
# Partition Subnets
##################################

resource "aws_subnet" "dmz_in_vpc_partition_subnets" {
  for_each          = var.deploy_dmz ? { for subnets, subnet_values in local.all_subnets_key : subnets => subnet_values if subnet_values.subnet_type != "south_inspection_subnet" && subnet_values.subnet_type != "north_inspection_subnet" } : {}
  vpc_id            = module.vpc[each.value.vpc_name].vpc_id # example key used in VPC module us-east-1-vpc-01
  cidr_block        = each.value.cidr
  availability_zone = each.value.subnet_az

  tags = {
    "Name"      = replace("${each.value.vpc_name}.${each.value.subnet_type}.${each.value.subnet_az}.subnet", "_subnet", "")
    "partition" = each.value.partition
  }
}

resource "aws_route_table" "dmz_in_vpc_partition_subnets" {
  for_each = var.deploy_dmz ? { for subnets, subnet_values in local.all_subnets_key : subnets => subnet_values if subnet_values.subnet_type != "south_inspection_subnet" && subnet_values.subnet_type != "north_inspection_subnet" } : {}
  vpc_id   = module.vpc[each.value.vpc_name].vpc_id # example key used in VPC module us-east-1-vpc-01

  tags = {
    "Name" = replace("${each.value.vpc_name}.${each.value.subnet_type}.${each.value.subnet_az}.rt", "_subnet", "")
  }
}

resource "aws_route_table_association" "partition_subnets" {
  for_each       = var.deploy_dmz ? { for subnets, subnet_values in local.all_subnets_key : subnets => subnet_values if subnet_values.subnet_type != "south_inspection_subnet" && subnet_values.subnet_type != "north_inspection_subnet" } : {}
  subnet_id      = aws_subnet.dmz_in_vpc_partition_subnets[each.key].id
  route_table_id = aws_route_table.dmz_in_vpc_partition_subnets[each.key].id
}


##################################
# Partition Routing
##################################

##### Disable East/West routing between partitions and any other networks ######
resource "aws_route" "partitions_east_west_to_south_vpce" {
  for_each               = var.deploy_dmz ? local.all_partition_routes : {}
  route_table_id         = each.value.source_subnet_type != "intra_subnet" ? aws_route_table.dmz_in_vpc_partition_subnets[each.value.source_route_table].id : module.vpc[each.value.source_route_table].intra_route_table_ids[0]
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = aws_vpc_endpoint.dmz_in_vpc_gwlb["south_${each.value.source_vpc_name}_us-east-1a"].id # depends on AZ1 for east-west to function. Could be toggled to change the a to b or c for AZ 1 2 or 3
  # vpc_endpoint_id = aws_vpc_endpoint.dmz_gwlb["south_${local.route_mappings[each.value.source_subnet_az][each.value.destination_subnet_az]}"].id
}

# #### Defaults to VPCe
resource "aws_route" "partition_subnets_defaults_to_vpce" {
  for_each               = var.deploy_dmz ? { for subnets, subnet_values in local.all_subnets_key : subnets => subnet_values if subnet_values["subnet_type"] != "south_inspection_subnet" && subnet_values["subnet_type"] != "north_inspection_subnet" } : {}
  route_table_id         = aws_route_table.dmz_in_vpc_partition_subnets[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = contains(["servers_outside_subnet"], each.value.subnet_type) ? aws_vpc_endpoint.dmz_in_vpc_gwlb[each.value.gwlbe_mapping].id : (contains(["management_subnet"], each.value.subnet_type) ? null : (contains(["servers_inside_subnet"], each.value.subnet_type) ? aws_vpc_endpoint.dmz_in_vpc_gwlb[each.value.gwlbe_mapping].id : null))
  transit_gateway_id     = contains(["management_subnet"], each.value.subnet_type) ? aws_ec2_transit_gateway.transit_gateway.id : null
}