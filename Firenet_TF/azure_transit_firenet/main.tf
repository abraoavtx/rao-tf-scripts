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

#Azure Transit HA Gateway
module "transit_ha_azure" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.1.5"
  cloud                  = "azure"
  name                   = "rao-tx-gw-az-westus"
  region                 = var.region
  insane_mode            = true
  cidr                   = "10.206.2.0/23"
  account                = var.account_name
  enable_transit_firenet = true
}

module "mc_firenet_ha_azure" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "v1.1.2"
  transit_module = module.transit_ha_azure
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  egress_enabled = true
  username = "ubuntu"
  #password = "aviaReg!23"
  password = "Aviatrix123!"
  bootstrap_storage_name_1 = var.bootstrap_storage_name_1
  storage_access_key_1     = var.storage_access_key_1
  file_share_folder_1      = var.file_share_folder_1
}

#Spoke VPC
module "spoke_azure_1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"

  cloud             = "Azure"
  name              = "abrao-tm-spoke1-gw-azure"
  cidr              = "10.206.4.0/24"
  region            = var.region
  account           = var.account_name
  insane_mode       = true
  instance_size     = "Standard_D3_v2"
  #transit_gw        = "rao-tx-gw-az-westus"
  transit_gw        = module.transit_ha_azure.transit_gateway.gw_name 
  #transit_gw_egress = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}

#Spoke VPC
module "spoke_azure_2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"
  cloud             = "Azure"
  name              = "abrao-tm-spoke2-gw-azure"
  cidr              = "10.206.5.0/24"
  region            = var.region
  account           = var.account_name
  ha_gw             = false
  insane_mode       = true
  instance_size     = "Standard_D3_v2"
  #transit_gw        = "rao-tx-gw-az-westus"
  transit_gw        =  module.transit_ha_azure.transit_gateway.gw_name
  #transit_gw_egress    = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}


module "onprem-transit_2" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.1.5"

  cloud                  = "aws"
  name                   = "avx-onprem-azure"
  region                 = var.region_aws
  cidr                   = "10.206.6.0/23"
  account                = var.account_name_aws
  insane_mode            = true
  ha_gw                  = false
  enable_advertise_transit_cidr = true
  
}

#Create External Connectiom Between Onprem to Transit 
 resource "aviatrix_transit_external_device_conn" "onpremtotransit" {
   #vpc_id = "vpc-00785e1c4f430e932~~${module.onprem-transit_1.vpc.id}"
   vpc_id = module.onprem-transit_2.vpc.vpc_id
   connection_name = "Onpremtotransit-azure"
   gw_name = module.onprem-transit_2.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPsec"
   bgp_local_as_num = "64531"
   bgp_remote_as_num = "64532"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.transit_ha_azure.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.29/30"
   remote_tunnel_cidr = "169.254.254.30/30"
   ha_enabled = true
   backup_bgp_remote_as_num = "64532"
   backup_pre_shared_key = var.pre_shared_key
   backup_remote_gateway_ip = module.transit_ha_azure.transit_gateway.ha_eip
   backup_local_tunnel_cidr  = "169.254.254.33/30"
   backup_remote_tunnel_cidr = "169.254.254.34/30"
 }

#Create External Connectiom Between Transit to Onprem
 resource "aviatrix_transit_external_device_conn" "transittoonprem" {
   vpc_id = module.transit_ha_azure.vpc.vpc_id
   connection_name = "transittoonprem-azure"
   gw_name = module.transit_ha_azure.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPsec"
   bgp_local_as_num = "64532"
   bgp_remote_as_num = "64531"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.onprem-transit_2.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.30/30,169.254.254.34/30"
   remote_tunnel_cidr = "169.254.254.29/30,169.254.254.33/30"
 }

output spoke1_name {
  value = module.spoke_azure_1.spoke_gateway.gw_name
  description = "VPC ID of Transit gateway"
 }

output spoke2_name {
  value = module.spoke_azure_2.spoke_gateway.gw_name
  description = "VPC ID of Transit gateway"
 }

data "aviatrix_firenet_vendor_integration" "foo" {
  vpc_id        = module.transit_ha_azure.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_azure.aviatrix_firewall_instance[0].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_azure.aviatrix_firewall_instance[0].*.public_ip[0]
  username      = "ubuntu"
  password      = "Aviatrix123!"
  firewall_name = module.mc_firenet_ha_azure.aviatrix_firewall_instance[0].*.firewall_name[0]
  save          = true
}

data "aviatrix_firenet_vendor_integration" "foo2" {
  vpc_id        = module.transit_ha_azure.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_azure.aviatrix_firewall_instance[1].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_azure.aviatrix_firewall_instance[1].*.public_ip[0]
  username      = "ubuntu"
  password      = "Aviatrix123!"
  firewall_name = module.mc_firenet_ha_azure.aviatrix_firewall_instance[1].*.firewall_name[0]
  save          = true
}
 