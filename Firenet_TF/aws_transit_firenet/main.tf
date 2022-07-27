terraform {
  required_providers {
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "2.22.1"
    }
    aws = {
        source = "hashicorp/aws"
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


#AWS Transit Gateway HA 
module "transit_ha_aws" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.1.5"

  cloud                  = "aws"
  name                   = "abrao-tf-tx-gw-aws-us-east-2"
  region                 = var.region
  cidr                   = "10.190.0.0/23"
  account                = var.account_name
  insane_mode            = true
  enable_transit_firenet = true
}

module "mc_firenet_ha_aws" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "v1.1.2"

  transit_module = module.transit_ha_aws
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  egress_enabled = true
  iam_role_1 = var.iam_role_1
  bootstrap_bucket_name_1 = var.bootstrap_bucket_name_1
}

#Spoke VPC
module "spoke_aws_1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"

  cloud             = "AWS"
  name              = "abrao-tf-spoke-vpc-east2"
  cidr              = "10.194.0.0/24"
  region            = var.region
  account           = var.account_name
  insane_mode        = true
  transit_gw        = module.transit_ha_aws.transit_gateway.gw_name 
  #transit_gw_egress = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}

#Spoke VPC
module "spoke_aws_2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"

  cloud             = "AWS"
  name              = "abrao-tm-spoke2-vpc-east2"
  cidr              = "10.195.0.0/24"
  region            = var.region
  account           = var.account_name
  ha_gw             = false
  insane_mode       = true
  transit_gw        = module.transit_ha_aws.transit_gateway.gw_name 
  #transit_gw_egress    = module.transit_ha_dual_firenet_aws_egress.transit_gateway.gw_name
}
output transit_vpc_id {
  value = module.transit_ha_aws.vpc.vpc_id
  #value = module.transit_firenet_1[0].vpc.*.vpc_id[0]
  description = "VPC ID of Transit gateway"
 }

output pan_1_public_ip {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.public_ip[0]
  description = "PAN1 Public IP"
 }

output pan_2_public_ip {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.public_ip[0]
  description = "PAN2 Public IP "
 }

output pan_1_firewall_name {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  description = "VPC ID of Transit gateway"
 }

output pan_2_firewall_name {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  description = "VPC ID of Transit gateway"
 }

output pan_1_instance_id {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.instance_id[0]
  description = "VPC ID of Transit gateway"
 }

output pan_2_instance_id {
  value = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.instance_id[0]
  description = "VPC ID of Transit gateway"
 }

data "aviatrix_firenet_vendor_integration" "foo" {
  vpc_id        = module.transit_ha_aws.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.public_ip[0]
  username      = "admin"
  password      = "aviaReg!23"
  firewall_name = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  save          = true
}

data "aviatrix_firenet_vendor_integration" "foo2" {
  vpc_id        = module.transit_ha_aws.vpc.vpc_id
  instance_id   = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.instance_id[0]
  vendor_type   = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip     = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.public_ip[0]
  username      = "admin"
  password      = "aviaReg!23"
  firewall_name = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  save          = true
}

#Deploy an On-Prem gateway
module "onprem-transit_1" {
  source  = "terraform-aviatrix-modules/aws-transit/aviatrix"
  version = "v4.0.3"
  cidr = "10.200.2.0/23"
  region = var.region
  ha_gw=false
  account = var.account_name
}

/*
resource "aviatrix_vpc" "onprem-vpc" {
  cloud_type           = 1
  account_name         = var.account_name
  region               = var.region
  name                 = "onprem-vpc-terraform"
  cidr                 = "10.200.1.0/23"
  aviatrix_transit_vpc = true
  aviatrix_firenet_vpc = false
}

output "onpremvpc_output" {
  value = aviatrix_vpc.onprem-vpc
  description = "VPC ID of Transit gateway"
 }

 resource "aviatrix_transit_gateway" "Onprem-transit-gateway" {
   cloud_type = 1
   account_name = var.account_name
   gw_name = "Onprem-transit-gateway"
   vpc_id = aviatrix_vpc.onprem-vpc.vpc_id
   vpc_reg = var.region
   gw_size = "t2.micro"
   subnet = aviatrix_vpc.onprem-vpc.subnets[4].cidr
   insane_mode = true  
   connected_transit = true
 }
*/


 #Create External Connectiom Between Onprem to Transit 
 resource "aviatrix_transit_external_device_conn" "onpremtotransit" {
   vpc_id = module.onprem-transit_1.vpc.vpc_id
   connection_name = "Onpremtotransit"
   gw_name = module.onprem-transit_1.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPsec"
   bgp_local_as_num = "64511"
   bgp_remote_as_num = "64512"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.transit_ha_aws.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.1/30"
   remote_tunnel_cidr = "169.254.254.2/30"
   ha_enabled = true
   backup_bgp_remote_as_num = "64512"
   backup_pre_shared_key = var.pre_shared_key
   backup_remote_gateway_ip = module.transit_ha_aws.transit_gateway.ha_eip
   backup_local_tunnel_cidr  = "169.254.254.5/30"
   backup_remote_tunnel_cidr = "169.254.254.6/30"
 }

#Create External Connectiom Between Transit to Onprem
 resource "aviatrix_transit_external_device_conn" "transittoonprem" {
   vpc_id = module.transit_ha_aws.vpc.vpc_id
   connection_name = "transittoonprem"
   gw_name = module.transit_ha_aws.transit_gateway.gw_name
   connection_type = "bgp"
   tunnel_protocol = "IPSEC"
   bgp_local_as_num = "64512"
   bgp_remote_as_num = "64511"
   pre_shared_key = var.pre_shared_key
   remote_gateway_ip = module.onprem-transit_1.transit_gateway.eip
   local_tunnel_cidr = "169.254.254.2/30,169.254.254.6/30"
   remote_tunnel_cidr = "169.254.254.1/30,169.254.254.5/30"
 }
