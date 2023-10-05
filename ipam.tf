# resource "aws_vpc_ipam" "main" {
#   description = "Multi Regional IPAM"
#   dynamic "operating_regions" {
#     for_each = local.all_ipam_regions
#     content {
#       region_name = operating_regions.value
#     }
#   }
# }

# resource "aws_vpc_ipam_pool" "pool" {
#   for_each       = { for item in local.flattened_byoip : "${item.region}-${item.descriptor}" => item }
#   description    = "${each.value.region}-${each.value.descriptor}"
#   address_family = "ipv4"
#   ipam_scope_id  = aws_vpc_ipam.main.public_default_scope_id
#   locale         = each.value.region
# }

# resource "aws_vpc_ipam_pool_cidr" "cidr" {
#   for_each     = { for item in local.flattened_byoip : "${item.region}-${item.descriptor}" => item }
#   ipam_pool_id = aws_vpc_ipam_pool.pool[each.key].id
#   cidr         = each.value.cidr

#   cidr_authorization_context {
#     message   = each.value.message
#     signature = each.value.signature
#   }
# }

resource "aws_vpc_ipam" "main" {
  count       = var.deploy_ipm ? 1 : 0
  description = "Multi Regional IPAM"
  dynamic "operating_regions" {
    for_each = local.all_ipam_regions
    content {
      region_name = operating_regions.value
    }
  }
}

resource "aws_vpc_ipam_pool" "pool" {
  for_each       = length(local.flattened_byoip) > 0 ? { for item in local.flattened_byoip : "${item.region}-${item.descriptor}" => item } : {}
  description    = "${each.value.region}-${each.value.descriptor}"
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.main[0].public_default_scope_id
  locale         = each.value.region
}

resource "aws_vpc_ipam_pool_cidr" "cidr" {
  for_each     = length(local.flattened_byoip) > 0 ? { for item in local.flattened_byoip : "${item.region}-${item.descriptor}" => item } : {}
  ipam_pool_id = aws_vpc_ipam_pool.pool[each.key].id
  cidr         = each.value.cidr

  cidr_authorization_context {
    message   = each.value.message
    signature = each.value.signature
  }
}

