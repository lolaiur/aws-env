# RELEASE NOTES

- Added toggle for DMZ VPC partition IGW/VPCe/routes.  Basically all resoruces in _dmz_aaS_partition.tf

## DMZ Toggles: 
- deploy_dmz = true 
    # Deploys DMZ VPC infra resources. No compute
- deploy_dmz_ftgs = true 
    #Deploys DMZ VPC compute with Fortigates configured with north/south and policies permitting any/any on both zones for ICMP/ 
    HTTPS/HTTP (dependent on the DMZ VPC deploy_dmz must be toggled on)
- deploy_dmz_in_vpc = true 
    #Deploys routing and IGW into 'customer' VPC  (var.vpcs should also contain a "dmz" value of true and secondary cidrs   
    are configured with 'scidr' in var.vpcs)

