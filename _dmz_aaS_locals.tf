locals {

  #################################################################
  # DMZ CIA VPC
  #################################################################

  dmz_inspection_all_subnets_key = merge(flatten([for zone, zone_value in var.dmz_zones :
    flatten([for az, az_value in zone_value["availability_zones"] :
      { for subnet, cidr in az_value :
        "${zone}_${az}" => {
          "zone"           = zone
          "subnet_az"      = az
          "subnet_type"    = subnet
          "cidr"           = cidr
        } if subnet == "inspection_subnet"
      }
    ])
  ])...)

  all_subnets = flatten([for partition, partition_value in var.dmz_partitions :
    flatten([for az, az_value in partition_value["availability_zones"] :
      flatten([for subnet, cidr in az_value :
        {
          "vpc_name"       = partition_value["vpc_name"]
          "partition"      = partition
          "partition_type" = partition_value["partition_type"]
          "subnet_az"      = az
          "subnet_type"    = subnet
          "cidr"           = cidr
          "region"         = partition_value["region"]
        }
      ])
    ])
  ])

  # creates a list of all intra created subnets and assigns AZ values based on element position of var.vpcs.subnets
  intra_subnets_keys = merge(flatten([for region, vpc_values in var.vpcs :
    [for vpc_key, vpc_data in vpc_values :
      [for subnet_idx, subnet_cidr in vpc_data.subnet : {
        "${subnet_cidr}_${region}_${subnet_idx}" = {
          "vpc_name"       = "${region}-${vpc_key}"
          "cidr"           = subnet_cidr
          "partition"      = "${region}-${vpc_key}"
          "partition_type" = "${vpc_key}_default"
          "subnet_az"      = element(["${region}a", "${region}b", "${region}c"], subnet_idx % 3)
          "subnet_type"    = "intra_subnet"
          "region"         = region
        }
        }
      ] if vpc_data.dmz == "true"
    ]
  ])...)

  # creates all partitions subnets based on var.dmz_partitions for use in routes and subnet creation
  all_subnets_key = merge(flatten([for partition, partition_value in var.dmz_partitions :
    flatten([for az, az_value in partition_value["availability_zones"] :
      { for subnet, cidr in az_value :
        "${cidr}_${az}" => {
          "vpc_name"       = partition_value["vpc_name"]
          "partition"      = partition
          "partition_type" = partition_value["partition_type"]
          "subnet_az"      = az
          "subnet_type"    = subnet
          "cidr"           = cidr
          "region"         = partition_value["region"]
          "gwlbe_mapping"  = "${subnet == "servers_inside_subnet" ? "south" : subnet == "servers_outside_subnet" ? "north" : "america"}_${partition_value["vpc_name"]}_${az}"
        }
      }
    ])
  ])...)

  # creates the combined list of all partition routes including intra created subnets
  all_partition_routes = merge([for index, values in merge(local.all_subnets_key, local.intra_subnets_keys) :
    { for index2, values2 in merge(local.all_subnets_key, local.intra_subnets_keys) :
      "${values.partition}_${values.subnet_az}_${values.subnet_type}_${values2.partition}_${values2.cidr}" => {
        "cidr"                       = values2.cidr
        "destination_partition"      = values2.partition
        "destination_partition_type" = values2.partition_type
        "destination_subnet_az"      = values2.subnet_az
        "destination_subnet_type"    = values2.subnet_type
        "destination_vpc_name"       = values2.vpc_name
        "source_partition"           = values.partition
        "source_partition_type"      = values.partition_type
        "source_route_table"         = contains([values.subnet_type], "intra_subnet") ? values.partition : index #(values.subnet_type == "intra_subnet" ? values.partition : index)
        "source_subnet_az"           = values.subnet_az
        "source_subnet_type"         = values.subnet_type
        "source_vpc_name"            = values.vpc_name
        "region"                     = values.region
      } if values.partition != values2.partition && values.vpc_name == values2.vpc_name || # Disable east-west between partitions
      values.partition != values2.partition && values.subnet_type == "management_subnet" && values2.subnet_type == "management_subnet" && values.vpc_name == values2.vpc_name || #Disable east-west between management and non-management
      values.partition == values2.partition && values.subnet_type == "management_subnet" && values2.subnet_type != "management_subnet" && values.vpc_name == values2.vpc_name
    }
  ]...)

  # IGW ingress routes only create if igw_route_table_keys exist used by route resource on IGW to force inbound from north into the endpoints
  igw_routes = { for tuple in setproduct(local.all_subnets, keys(local.igw_route_table_keys)) : #pain works fine for one VPC, doesn't scale to multiples setproduct is a problem here
    "${tuple[1]}_${tuple[0].cidr}" => {
      "partition"       = tuple[0].partition
      "partition_type"  = tuple[0].partition_type
      "subnet_az"       = tuple[0].subnet_az
      "subnet_type"     = tuple[0].subnet_type
      "cidr"            = tuple[0].cidr
      "igw_route_table" = tuple[1]
      "vpc_name"        = tuple[0].vpc_name
    } if local.igw_route_table_keys != {}
  }

  # keys to build and reference the IGW route tables
  igw_route_table_keys = { for v in local.flattened_vpcs : "${v.region}-${v.vpc_name}" => v if var.deploy_dmz && v.vpc_data.dmz == "true"}

   # creates a list of all intra created subnets and assigns AZ values based on element position of var.vpcs.subnets
  tgw_subnets_keys = merge(flatten([for region, vpc_values in var.vpcs :
    [for vpc_key, vpc_data in vpc_values :
      [for subnet_idx, subnet_cidr in vpc_data.tgw : {
        "tgw_${region}-${vpc_key}_${element(["${region}a", "${region}b", "${region}c"], subnet_idx % 3)}" = {
          "vpc_name"       = "${region}-${vpc_key}"
          "cidr"           = subnet_cidr
          "partition"      = "${region}-${vpc_key}"
          "partition_type" = "${vpc_key}_default"
          "subnet_az"      = element(["${region}a", "${region}b", "${region}c"], subnet_idx % 3)
          "subnet_type"    = "intra_subnet"
          "region"         = region
        }
      }] if var.deploy_dmz
    ]
  ])...)

  # maps of TGW ingress routes used in DMZ partition routing within the target VPC
  tgw_routes = { for tuple in setproduct(local.all_subnets, keys(var.dmz_partitions)) :
    "${tuple[1]}_${tuple[0].cidr}" => {
      "partition" = tuple[0].partition
      "partition_type" = tuple[0].partition_type
      "subnet_az" = tuple[0].subnet_az
      "subnet_type" = tuple[0].subnet_type
      "cidr" = tuple[0].cidr
      "tgw_route_table" = data.aws_route_table.tgw["${tuple[0].vpc_name}"].id
      "vpc_name" = tuple[0].vpc_name
      "vpc_id" = module.vpc["${tuple[0].vpc_name}"].vpc_id
    } if contains(["lb_inside_subnet", "servers_inside_subnet", "lb_outside_subnet", "management_subnet"], tuple[0].subnet_type) && tuple[0].vpc_name == tuple[1] && var.deploy_dmz == true #Makes sure only south-facing subnets are routable from TGW
  }

  # builds a list of GWLB subnets based on var.dmz_zones 
  gwlb_subnets = merge([for zone, zone_values in var.dmz_zones :
    { for az, subnets in zone_values.availability_zones :
      "${zone}_${az}" => {
        loadbalancer_subnet = subnets.loadbalancer_subnet
        zone                = zone
        az                  = az
    } } if var.deploy_dmz == true
  ]...)

  # creates a map of GWLBE endpoints to create in each VPC basec on var.dmz_partitions having a set of partition variables
  dmz_in_vpc_gwlbes = merge(flatten([for partition, partition_values in var.dmz_partitions :
    flatten([for az, az_value in partition_values.availability_zones :
      { for subnets, cidrs in az_value :
        "${subnets == "north_inspection_subnet" ? "north" : "south"}_${partition_values.vpc_name}_${az}" => {
          "az"                = az
          "inspection_subnet" = cidrs
          "zone"              = subnets == "north_inspection_subnet" ? "north" : "south"
          "vpc_name"          = partition
          "route_table"       = "${subnets == "north_inspection_subnet" ? "north" : "south"}_${partition}"
        } if subnets == "north_inspection_subnet" || subnets == "south_inspection_subnet"
      }
    ])
  ])...)

  # maps subnets to gwlb zone north/south alignment
  gwlb_mappings = { for subnets, zone in local.gwlb_subnets : zone.zone => subnets... if var.deploy_dmz == true }

  # for future use for east-west routing to/from DMZ partition in vpc
  route_mappings = {
    "us-east-1a" = {
      us-east-1a = "us-east-1a"
      us-east-1b = "us-east-1b"
      us-east-1c = "us-east-1c"
    }
    "us-east-1b" = {
      us-east-1a = "us-east-1b"
      us-east-1b = "us-east-1b"
      us-east-1c = "us-east-1c"
    }
    "us-east-1c" = {
      us-east-1a = "us-east-1c"
      us-east-1b = "us-east-1c"
      us-east-1c = "us-east-1c"
    }
  }

}
