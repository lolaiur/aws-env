# aws-env fun times
# params.tfvars style:
```
create_cgw = false # Creates CloudWAN (WIP)
deploy_ssm = false # Enables SSM Service (Complete)
deploy_ep  = false # Creates SSM Required Endpoints (Complete)
deploy_vpn = false # Deploys site-to-site VPN (Use OpenVPN instead)
deploy_ovp = true  # Deploys OpenVPN infrastructure (Complete)
deploy_dns = true  # Deploys DNS & Updates A Records
deploy_obi = false # Deploys OBI & Routes to NATGW
deploy_oig = true  # Deploys OBI & Routes to NATGW using FortiGates which are autoconfigured
deploy_cfg = false # Deploys FortiOS Config <<< Not working because provider can't be conditional :(

# Things used for OS deployments
os_user = "a_user_name"
os_pass = "a_pass_word"

# Used for DNS zone & record creation. Renders input.com
dns_name = "whaterver-you-like"

# forti stuff 
ftg_ami      = "ami-059d36a8887155edb" # FortiGate-VM64-AWSONDEMAND build2360 (7.4.0) GA
ftg_instance = "c4.large"
forti_token  = "a_long_token"

# OBI Specifics
x_zone_lb = false # Sets if you want Cross AZ LB (Can be costly!)
obi = { # Defines OBI VPC. Remove/Add to list for more/less AZs
  cidr       = "10.253.0.0/16"
  intra      = ["10.253.0.0/24", "10.253.1.0/24", "10.253.2.0/24"]
  mgmt       = ["10.253.3.0/24", "10.253.4.0/24", "10.253.5.0/24"]
  inspection = ["10.253.6.0/24", "10.253.7.0/24", "10.253.8.0/24"]
  nat        = ["10.253.9.0/24", "10.253.10.0/24", "10.253.11.0/24"]
  gwlb       = ["10.253.12.0/24", "10.253.13.0/24", "10.253.14.0/24"]
  tgw        = ["10.253.15.0/24", "10.253.16.0/24", "10.253.17.0/24"]
}

# Declares how many FTGs to deploy, which AZ to place them in and if they should be in a TG, or not
ftg = {
  ftg01 = { az = "0", tg = "n" }
  ftg02 = { az = "1", tg = "y" }
  ftg03 = { az = "2", tg = "n" }
}

# Dynamically create typical VPCs
vpcs = {
  "us-east-1" = {
    "vpc-01" = {
      cidr   = "10.10.0.0/16"
      subnet = ["10.10.0.0/24", "10.10.1.0/24"]
      tgw    = ["10.10.10.0/24", "10.10.20.0/24"]
      env    = "dev"
    }
    #"vpc-02" = {
    #  cidr   = "10.20.0.0/16"
    #  subnet = ["10.20.0.0/24"]
    #  tgw    = ["10.20.10.0/24"]
    #  env    = "prd"
    #}
    #"vpc-03" = {
    #  cidr   = "10.30.0.0/16"
    #  subnet = ["10.30.0.0/24", "10.30.1.0/24"]
    #  tgw    = ["10.30.10.0/24", "10.30.20.0/24"]
    #  env    = "prd"
    #}
  }
}

# Dynamically create EC2s in specific VPCs, Assigned to a specific AZ, which OS to use, and if userdata (UD) should be applied
ec2 = {
  server01 = { vpc = "vpc-01", az = "1", os = "win", ud = "Y" }
  #server02 = { vpc = "vpc-01", az = "1", os = "win", ud = "Y" }
  #server03 = { vpc = "vpc-01", az = "1", os = "win", ud = "Y" }
  #server04 = { vpc = "vpc-01", az = "1", os = "lnx", ud = "Y" }
  #server05 = { vpc = "vpc-02", az = "1", os = "lnx", ud = "Y" }
  #server06 = { vpc = "vpc-02", az = "1", os = "win", ud = "Y" }
}

route_tables = { # Default behavior associates & propgates to default rtb
  "main" = {
    associations = [
    ]
    propagations = [
    ]
    static_routes = {
    }
    blackhole_routes = [
    ]
  }
}


public_key       = "ssh-rsa your public key"

## OpenVPN Things
admin_user       = "another_user_name"
storage_path     = "./scripts/openvpn"
private_key_path = "./scripts/openvpn/key" # <replace the .pem in the path with your private key.  This is used in the null_resources for the SSH connectcfb

my_ip = "xxx.xxx.xxx.xxx" # probably not needed
```

<!--- BEGIN_TF_DOCS --->

<!--- END_TF_DOCS --->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.13.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.13.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_OBI"></a> [OBI](#module\_OBI) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_cloudwan"></a> [cloudwan](#module\_cloudwan) | aws-ia/cloudwan/aws | ~>2 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_vpcOBI"></a> [vpcOBI](#module\_vpcOBI) | terraform-aws-modules/vpc/aws | ~> 5.0 |
| <a name="module_vpcVPN"></a> [vpcVPN](#module\_vpcVPN) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_customer_gateway.customer_gw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/customer_gateway) | resource |
| [aws_ec2_transit_gateway.transit_gateway](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway) | resource |
| [aws_ec2_transit_gateway_route.blackhole_route](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.obi](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.obirt](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route.static_route](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route) | resource |
| [aws_ec2_transit_gateway_route_table.route_table](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route_table) | resource |
| [aws_ec2_transit_gateway_route_table_association.association](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route_table_association) | resource |
| [aws_ec2_transit_gateway_route_table_propagation.propagations](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_route_table_propagation) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.obi-tgw_attch](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.obitgw_attch](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.tgw_attch](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_ec2_transit_gateway_vpc_attachment.vpntgw_attch](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.obi-eip](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/eip) | resource |
| [aws_eip.obi_eip](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/eip) | resource |
| [aws_eip.vpnserver_eip](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/eip) | resource |
| [aws_eip_association.vpnserver_eip_association](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/eip_association) | resource |
| [aws_iam_instance_profile.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ssm_role](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ssm_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.ftg_instance](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/instance) | resource |
| [aws_instance.server](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/instance) | resource |
| [aws_instance.vpnserver](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/instance) | resource |
| [aws_internet_gateway.obi-igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/internet_gateway) | resource |
| [aws_internet_gateway.obi_vpc_igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/internet_gateway) | resource |
| [aws_internet_gateway.vpn_vpc_igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/internet_gateway) | resource |
| [aws_key_pair.ec2_key](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/key_pair) | resource |
| [aws_key_pair.vpn_ec2_key](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/key_pair) | resource |
| [aws_kms_key.ssm_key](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/kms_key) | resource |
| [aws_lb.gwlb](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/lb) | resource |
| [aws_lb_listener.gwlb_listener](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.gwlb_tg](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.ftg_tg_attachment](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/lb_target_group_attachment) | resource |
| [aws_nat_gateway.obi_nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.obi_nat_gw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/nat_gateway) | resource |
| [aws_network_interface.mgmt_eni](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/network_interface) | resource |
| [aws_network_interface.south_eni](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/network_interface) | resource |
| [aws_route.gwlb-def_to_nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.gwlb-env_to_tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.inspect-def_to_nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.intra](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.intraOBI](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.intraVPN](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.mgmt-def_to_nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.mgmt-env_to_tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.obivpc_to_my_ip](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.public_return](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.public_to_igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.tgw-def_to_igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.tgw-env_to_vpce](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.tgw_sub_to_nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.tgw_to_gwlbe](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route.vpn_vpc_to_my_ip](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route53_record) | resource |
| [aws_route53_zone.private_zone](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route53_zone) | resource |
| [aws_route53_zone_association.this](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route53_zone_association) | resource |
| [aws_route_table.gwlb](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.igw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.inspection](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.mgmt](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.obi-tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.obitgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.public_subnet_route_table](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table.vpntgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table) | resource |
| [aws_route_table_association.gwlb](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.inspection](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.mgmt](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.obi-tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.obitgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_subnet_rtb_assoc](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_route_table_association.vpntgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/route_table_association) | resource |
| [aws_security_group.ec2](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/security_group) | resource |
| [aws_security_group.endpoint_sg](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/security_group) | resource |
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/security_group) | resource |
| [aws_security_group.vpnec2](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/security_group) | resource |
| [aws_ssm_association.example](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ssm_association) | resource |
| [aws_ssm_document.ssm_document](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ssm_document) | resource |
| [aws_ssm_service_setting.default_host_management](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/ssm_service_setting) | resource |
| [aws_subnet.gwlb](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.inspection](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.mgmt](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.nat](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.obi-tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.obitgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.tgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_subnet.vpntgw](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/subnet) | resource |
| [aws_vpc_endpoint.ec2messages](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.gwlbe](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssmmessages](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_service.gwlb](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpc_endpoint_service) | resource |
| [aws_vpn_connection.vpn_connection](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/resources/vpn_connection) | resource |
| [null_resource.openvpn_adduser](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [null_resource.openvpn_download_configurations](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [null_resource.openvpn_install](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [null_resource.openvpn_move_files](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [null_resource.provision_core](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [null_resource.provision_openvpn](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/caller_identity) | data source |
| [aws_network_interface.endpoint](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/network_interface) | data source |
| [aws_network_interface.gwlb_eni](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/network_interface) | data source |
| [aws_network_interfaces.gwlb_enis](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/network_interfaces) | data source |
| [aws_networkmanager_core_network_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/networkmanager_core_network_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.13.1/docs/data-sources/region) | data source |
| [template_file.ftg_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_user"></a> [admin\_user](#input\_admin\_user) | admin user | `string` | `"openvpn"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | List of Availability Zones | `list(string)` | <pre>[<br>  "us-west-2a",<br>  "us-west-2b",<br>  "us-west-2c"<br>]</pre> | no |
| <a name="input_create_cgw"></a> [create\_cgw](#input\_create\_cgw) | n/a | `bool` | `false` | no |
| <a name="input_deploy_cfg"></a> [deploy\_cfg](#input\_deploy\_cfg) | Toggle to deploy or not configure the OBI Forti | `bool` | `false` | no |
| <a name="input_deploy_dns"></a> [deploy\_dns](#input\_deploy\_dns) | n/a | `bool` | `false` | no |
| <a name="input_deploy_ep"></a> [deploy\_ep](#input\_deploy\_ep) | Toggle to deploy the VPC endpoints | `bool` | `false` | no |
| <a name="input_deploy_obi"></a> [deploy\_obi](#input\_deploy\_obi) | Toggle to deploy or not deploy the OBI VPC | `bool` | `false` | no |
| <a name="input_deploy_oig"></a> [deploy\_oig](#input\_deploy\_oig) | Toggle to deploy or not deploy the OBI VPC | `bool` | `false` | no |
| <a name="input_deploy_ovp"></a> [deploy\_ovp](#input\_deploy\_ovp) | n/a | `bool` | `false` | no |
| <a name="input_deploy_ssm"></a> [deploy\_ssm](#input\_deploy\_ssm) | Whether to deploy SSM related resources | `bool` | `false` | no |
| <a name="input_deploy_vpn"></a> [deploy\_vpn](#input\_deploy\_vpn) | n/a | `bool` | `false` | no |
| <a name="input_ec2"></a> [ec2](#input\_ec2) | Configuration for EC2 instances | <pre>map(object({<br>    vpc = string<br>    az  = string<br>    os  = string<br>    ud  = string<br>  }))</pre> | n/a | yes |
| <a name="input_forti_token"></a> [forti\_token](#input\_forti\_token) | Token generated from FortiOS for API User | `string` | `""` | no |
| <a name="input_ftg"></a> [ftg](#input\_ftg) | Defines number of FTGs to deploy, which az, and if they should be placed into target group | <pre>map(object({<br>    az = string # Availability Zone index as a string<br>    tg = string # Whether to add to target group: 'y' or 'n'<br>  }))</pre> | n/a | yes |
| <a name="input_ftg_ami"></a> [ftg\_ami](#input\_ftg\_ami) | Value of FTG AMI to use | `string` | n/a | yes |
| <a name="input_ftg_instance"></a> [ftg\_instance](#input\_ftg\_instance) | Value of Instance Type for FTG | `string` | n/a | yes |
| <a name="input_my_ip"></a> [my\_ip](#input\_my\_ip) | n/a | `string` | n/a | yes |
| <a name="input_obi"></a> [obi](#input\_obi) | The CIDRs for OBI setup | <pre>object({<br>    cidr       = string<br>    intra      = list(string)<br>    mgmt       = list(string)<br>    inspection = list(string)<br>    nat        = list(string)<br>    gwlb       = list(string)<br>    tgw        = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_os_pass"></a> [os\_pass](#input\_os\_pass) | Password you wish to pass into userdata | `string` | n/a | yes |
| <a name="input_os_user"></a> [os\_user](#input\_os\_user) | Username you wish to pass into userdata | `string` | n/a | yes |
| <a name="input_private_key_path"></a> [private\_key\_path](#input\_private\_key\_path) | n/a | `string` | `"./key.pub"` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | Public key for EC2 instances | `string` | `""` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | n/a | <pre>map(object({<br>    associations     = list(string)<br>    propagations     = list(string)<br>    static_routes    = map(string)<br>    blackhole_routes = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | port ssh | `number` | `22` | no |
| <a name="input_ssh_user"></a> [ssh\_user](#input\_ssh\_user) | user ssh | `string` | `"ec2-user"` | no |
| <a name="input_storage_path"></a> [storage\_path](#input\_storage\_path) | storage path keys to local | `string` | `"./openvpn"` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | Map of regions to VPCs to create | `any` | `{}` | no |
| <a name="input_x_zone_lb"></a> [x\_zone\_lb](#input\_x\_zone\_lb) | Toggles Cross Zone LB on GWLB | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
