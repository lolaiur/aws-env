# output "tgw_id" {
#   description = "The value of deployed TGW"
#   value       = aws_ec2_transit_gateway.transit_gateway.id
# }
# 
# output "vpc_data" {
#   value = var.vpcs
# }

# output "debug" {
#   value = { for k, v in module.vpc : k => v.vpc_id }
# }

# output "vpcs" {
#   value       = module.vpc
#   description = "The IDs of the VPCs created"
# }
# 
# output "vpn_vpc" {
#   value       = module.vpcVPN
#   description = "The ID of the VPN VPC"
# }

#output "vpceip" {
#  value = aws_vpc_endpoint.gwlbe[0]
#}
#
#output "vpceip2" {
#  value = data.aws_network_interface.endpoint.private_ip
#}

output "server_details" {
  value = { for k, v in var.ec2 : k => {
    server_name = k,
    vpc_name    = v.vpc
    private_ip  = aws_instance.server[k].private_ip,
    az          = v.az,
    os          = v.os,
  } }
}

# output "private_zone_keys" {
#   value = keys(aws_route53_zone[0].private_zone)
# }
