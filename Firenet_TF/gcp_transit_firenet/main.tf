terraform {
  required_providers {
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "2.22.1"
    }
  }
}

# Configure Aviatrix provider
provider "aviatrix" {
  controller_ip = var.controller_ip
  username      = var.username
  password      = var.password
  skip_version_validation = true
}

module "transit_ha_gcp" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "2.1.5"

  cloud                  = "gcp"
  name                   = "tx-gw-gcp-v66"
  region                 = "us-east1"
  cidr                   = var.cidr
  account                = var.account_name
  insane_mode            = true
  enable_transit_firenet = true
  lan_cidr               = var.lan_cidr
}

module "mc_firenet_ha_gcp" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "1.1.2"

  transit_module = module.transit_ha_gcp
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall BUNDLE1"
  egress_enabled = true
  egress_cidr    = var.egress_cidr
  mgmt_cidr      = var.mgmt_cidr
}

#Spoke VPC
module "spoke_gcp_1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"

  cloud             = "gcp"
  name              = "gcp-spoke1-gw-v66"
  cidr              = "10.207.7.0/24"
  region            = var.region
  account           = var.account_name
  insane_mode       = true
  instance_size     = "n1-highcpu-4"
  transit_gw        = module.transit_ha_gcp.transit_gateway.gw_name 
  #transit_gw_egress = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}

#Spoke VPC
module "spoke_gcp_2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"

  cloud             = "gcp"
  name              = "gcp-spoke2-gw-v66"
  cidr              = "10.207.8.0/24"
  region            = var.region
  account           = var.account_name
  ha_gw             = false
  insane_mode       = true
  instance_size     = "n1-highcpu-4"
  transit_gw        = module.transit_ha_gcp.transit_gateway.gw_name
  #transit_gw_egress    = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}


module "onprem-transit_3" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.1.5"

  cloud                  = "aws"
  name                   = "avx-onprem-gcp"
  region                 = var.region_aws
  cidr                   = "10.207.10.0/23"
  account                = var.account_name_aws
  insane_mode            = true
  ha_gw                  = false
  enable_advertise_transit_cidr = true
  
}
/*
module "onprem-transit_3" {
  source  = "terraform-aviatrix-modules/aws-transit/aviatrix"
  version = "v4.0.3"
  cidr = "10.207.9.0/23"
  region = var.region_aws
  name = "avx-onprem-gcp"
  ha_gw=false
  account = var.account_name_aws
}
*/

#Create External Connectiom Between Onprem to Transit 
 resource "aviatrix_transit_external_device_conn" "onpremtotransit" {
   #vpc_id = "vpc-00785e1c4f430e932~~${module.onprem-transit_1.vpc.id}"
   vpc_id = module.onprem-transit_3.vpc.vpc_id
   connection_name = "Onpremtotransit-gcp"
   gw_name = module.onprem-transit_3.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPsec"
   bgp_local_as_num = "64431"
   bgp_remote_as_num = "64432"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.transit_ha_gcp.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.41/30"
   remote_tunnel_cidr = "169.254.254.42/30"
   ha_enabled = true
   backup_bgp_remote_as_num = "64432"
   backup_pre_shared_key = var.pre_shared_key
   backup_remote_gateway_ip = module.transit_ha_gcp.transit_gateway.ha_eip
   backup_local_tunnel_cidr  = "169.254.254.45/30"
   backup_remote_tunnel_cidr = "169.254.254.46/30"
 }

#Create External Connectiom Between Transit to Onprem
 resource "aviatrix_transit_external_device_conn" "transittoonprem" {
   vpc_id = module.transit_ha_gcp.vpc.vpc_id
   connection_name = "transittoonprem-gcp"
   gw_name = module.transit_ha_gcp.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPsec"
   bgp_local_as_num = "64432"
   bgp_remote_as_num = "64431"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.onprem-transit_3.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.42/30,169.254.254.46/30"
   remote_tunnel_cidr = "169.254.254.41/30,169.254.254.45/30"
 }

output spoke1_name {
  value = module.spoke_gcp_1.spoke_gateway.gw_name
  description = "VPC ID of Transit gateway"
 }

output spoke2_name {
  value = module.spoke_gcp_2.spoke_gateway.gw_name
  description = "VPC ID of Transit gateway"
 }

/*
data "aviatrix_firenet_vendor_integration" "foo" {
  vpc_id        = module.transit_ha_gcp.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[0].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[0].*.public_ip[0]
  username      = "admin"
  password      = "aviaReg!23"
  firewall_name = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[0].*.firewall_name[0]
  save          = true
}

data "aviatrix_firenet_vendor_integration" "foo2" {
  vpc_id        = module.transit_ha_gcp.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[1].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[1].*.public_ip[0]
  username      = "admin"
  password      = "aviaReg!23"
  firewall_name = module.mc_firenet_ha_gcp.aviatrix_firewall_instance[1].*.firewall_name[0]
  save          = true
}
*/
