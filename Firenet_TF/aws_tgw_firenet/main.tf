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

resource "aviatrix_aws_tgw" "aws_tgw_1" {
    tgw_name = "AWS-TGW-Egress-terraform"
    account_name = var.account_name
    region = var.region
    aws_side_as_number = 64512
    manage_security_domain = false
    manage_vpc_attachment = false
    manage_transit_gateway_attachment = false
}

resource "aviatrix_aws_tgw_network_domain" "aws_tgw_network_domain_1" {
    name = "Shared_Service_Domain"
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    depends_on = [
      aviatrix_aws_tgw.aws_tgw_1
    ]
}
resource "aviatrix_aws_tgw_network_domain" "aws_tgw_network_domain_2" {
    name = "Aviatrix_Edge_Domain"
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    depends_on = [
      aviatrix_aws_tgw.aws_tgw_1
    ]
}
resource "aviatrix_aws_tgw_network_domain" "aws_tgw_network_domain_3" {
    name = "Default_Domain"
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    depends_on = [
      aviatrix_aws_tgw.aws_tgw_1
    ]
}

resource "aviatrix_aws_tgw_network_domain" "aws_tgw_network_domain_4" {
    name = "Avtxfirenetdoamain"
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    aviatrix_firewall = true
    depends_on = [
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_1,
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_2,
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_3
    ]
}

resource "aviatrix_aws_tgw_vpc_attachment" "aws_tgw_vpc_attachment_1" {
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    region = "us-west-2"
    network_domain_name = "Default_Domain"
    vpc_account_name = var.account_name
    vpc_id = var.default_domain_vpc_id
    #subnets = "subnet-03630b88854ae8c81,subnet-0ba9d3951d43d120f,subnet-04b58c6dfac489bdc,subnet-01caea934f3d0f731"
    disable_local_route_propagation = false
    depends_on = [
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_1
    ]
}
resource "aviatrix_aws_tgw_vpc_attachment" "aws_tgw_vpc_attachment_2" {
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    region = "us-west-2"
    network_domain_name = "Shared_Service_Domain"
    vpc_account_name = var.account_name
    vpc_id = var.shared_domain_vpc_id
    #subnets = "subnet-0868530ef702ce019,subnet-0d341c59f96b98a64,subnet-0c2528d35dd04ab8b,subnet-0f04445465204347a"
    disable_local_route_propagation = false
    depends_on = [
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_4
    ]
}
resource "aviatrix_aws_tgw_vpc_attachment" "aws_tgw_vpc_attachment_3" {
    tgw_name = aviatrix_aws_tgw.aws_tgw_1.tgw_name
    region = "us-west-2"
    network_domain_name = "orgfndomain"
    vpc_account_name = var.account_name
    vpc_id = "vpc-083670cf139be1914"
    #subnets = "subnet-01aa0a55d6cba770d"
    disable_local_route_propagation = false
    depends_on = [
      aviatrix_aws_tgw_network_domain.aws_tgw_network_domain_4
    ]
}
resource "aviatrix_transit_gateway" "transit_gateway_1" {
    gw_name = "AVX-terrafom-abrao-transit-gw"
    vpc_id = var.trans_vpc_id
    cloud_type = 1
    vpc_reg = var.region
    gw_size = "c5.xlarge"
    account_name = var.account_name
    enable_hybrid_connection = true
    subnet = "10.8.0.64/28"
    enable_firenet = true
    connected_transit = true
    enable_encrypt_volume = true
     #depends_on = [
     # aviatrix_aws_tgw_vpc_attachment.aws_tgw_vpc_attachment_3
    #] 
}
#Create an Aviatrix AWS Spoke Gateway-A in Spoke VPC1
resource "aviatrix_spoke_gateway" "AVX-Spoke-GW-1" {
  cloud_type         = 1
  account_name       = var.account_name
  gw_name            = "AVX-Spoke-GW-abrao-${random_integer.num.result}"
  vpc_id             = var.spoke_vpc_id
  vpc_reg            = var.region
  gw_size            = "t3.micro"
  subnet             = module.aws-vpc.subnet_cidr[0]
  #transit_gw         = aviatrix_transit_gateway.AVX-Transit-GW-1.gw_name
  #enable_active_mesh = true
  manage_transit_gateway_attachment = false
}

# Spoke-A Transit Attachment
resource "aviatrix_spoke_transit_attachment" "Spoke-A_attachment" {
  spoke_gw_name   = aviatrix_spoke_gateway.AVX-Spoke-GW-1.gw_name
  transit_gw_name = aviatrix_transit_gateway.transit_gateway_1.gw_name
}

resource "aviatrix_firewall_instance" "firewall_instance_1" {
    firewall_name = "Terraform-firewall"
    firewall_size = "m5.xlarge"
    vpc_id = "vpc-083670cf139be1914"
    firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1 [VM-300]"
    firewall_image_id = "ami-0a6686eecd430ba77"
    firewall_image_version = "9."
    egress_subnet = "10.8.0.80/28"
    firenet_gw_name = aviatrix_transit_gateway.transit_gateway_1.gw_name
    tags = {
        }
    management_subnet = "10.8.0.64/28"
    depends_on = [
      aviatrix_transit_gateway.transit_gateway_1
    ]
}
resource "aviatrix_firewall_instance_association" "firewall_instance_association_1" {
    vpc_id = aviatrix_firewall_instance.firewall_instance_1.vpc_id
    firenet_gw_name = aviatrix_firewall_instance.firewall_instance_1.firenet_gw_name
    instance_id = aviatrix_firewall_instance.firewall_instance_1.instance_id
    firewall_name = aviatrix_firewall_instance.firewall_instance_1.firewall_name
    lan_interface = aviatrix_firewall_instance.firewall_instance_1.lan_interface
    management_interface = aviatrix_firewall_instance.firewall_instance_1.management_interface
    egress_interface = aviatrix_firewall_instance.firewall_instance_1.egress_interface
    attached = true
    depends_on = [
      aviatrix_firewall_instance.firewall_instance_1
    ]
}