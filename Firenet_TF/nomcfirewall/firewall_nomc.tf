locals {
  prefix = "${var.testbed}-${var.release}"
}


data "aviatrix_vpc" "aws_reg1_vpc" {
  name = var.aws_transit_region1_vpc_name
}

resource "aviatrix_firewall_instance" "aws_firewall_instance1" {
  firewall_name          = "aws-edge-fw1-reg1"
  firewall_size          = "m5.xlarge"
  vpc_id                 = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  firewall_image         = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  firewall_image_version = "10.1.3"
  management_subnet      = data.aviatrix_vpc.aws_reg1_vpc.public_subnets[0].cidr
  egress_subnet          = data.aviatrix_vpc.aws_reg1_vpc.public_subnets[1].cidr
  firenet_gw_name        = aviatrix_transit_gateway.transit_ha_aws_reg1["transit_reg1"].gw_name
  #Bootstrapping
  iam_role              = var.iam_role_1
  bootstrap_bucket_name = var.bootstrap_bucket_name_1

  lifecycle {
    ignore_changes = [
      firewall_image_version,
      firewall_size,
    ]
  }
}

#Firenet
resource "aviatrix_firenet" "aws_firenet" {
  vpc_id                               = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = true
  keep_alive_via_lan_interface_enabled = true
  depends_on = [
    aviatrix_firewall_instance_association.aws_firenet_instance1
  ]
}
resource "aviatrix_firewall_instance_association" "aws_firenet_instance1" {
  vpc_id               = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.transit_ha_aws_reg1["transit_reg1"].gw_name
  instance_id          = aviatrix_firewall_instance.aws_firewall_instance1.instance_id
  firewall_name        = aviatrix_firewall_instance.aws_firewall_instance1.firewall_name
  lan_interface        = aviatrix_firewall_instance.aws_firewall_instance1.lan_interface
  management_interface = aviatrix_firewall_instance.aws_firewall_instance1.management_interface
  egress_interface     = aviatrix_firewall_instance.aws_firewall_instance1.egress_interface
  attached             = true
}

resource "aviatrix_firewall_instance" "aws_firewall_instance1_ha" {
  firewall_name          = "aws-edge-fw2-ha"
  firewall_size          = "m5.xlarge"
  vpc_id                 = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  firewall_image         = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  firewall_image_version = "10.1.3"
  management_subnet      = data.aviatrix_vpc.aws_reg1_vpc.public_subnets[2].cidr
  egress_subnet          = data.aviatrix_vpc.aws_reg1_vpc.public_subnets[3].cidr
  firenet_gw_name        = aviatrix_transit_gateway.transit_ha_aws_reg1["transit_reg1"].ha_gw_name
  #Bootstrapping
  iam_role              = var.iam_role_1
  bootstrap_bucket_name = var.bootstrap_bucket_name_1

  lifecycle {
    ignore_changes = [
      firewall_image_version,
      firewall_size,
    ]
  }
}

#Firenet
resource "aviatrix_firenet" "aws_firenet_ha" {
  vpc_id                               = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  inspection_enabled                   = true
  egress_enabled                       = true
  keep_alive_via_lan_interface_enabled = true
  depends_on = [
    aviatrix_firewall_instance_association.aws_firenet_instance1_ha
  ]
}
resource "aviatrix_firewall_instance_association" "aws_firenet_instance1_ha" {
  vpc_id               = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  firenet_gw_name      = aviatrix_transit_gateway.transit_ha_aws_reg1["transit_reg1"].ha_gw_name
  instance_id          = aviatrix_firewall_instance.aws_firewall_instance1_ha.instance_id
  firewall_name        = aviatrix_firewall_instance.aws_firewall_instance1_ha.firewall_name
  lan_interface        = aviatrix_firewall_instance.aws_firewall_instance1_ha.lan_interface
  management_interface = aviatrix_firewall_instance.aws_firewall_instance1_ha.management_interface
  egress_interface     = aviatrix_firewall_instance.aws_firewall_instance1_ha.egress_interface
  attached             = true
}


################## Vendor Integration of Firewalls ########################################
data "aviatrix_firenet_vendor_integration" "foo_reg1" {
  vpc_id            = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  instance_id       = aviatrix_firewall_instance.aws_firewall_instance1.instance_id
  vendor_type       = "Palo Alto Networks VM-Series"
  public_ip         = aviatrix_firewall_instance.aws_firewall_instance1.public_ip
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = aviatrix_firewall_instance.aws_firewall_instance1.firewall_name
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  aviatrix_transit_gateway.transit_ha_aws_reg1]
}

data "aviatrix_firenet_vendor_integration" "foo_reg1_ha" {
  vpc_id            = data.aviatrix_vpc.aws_reg1_vpc.vpc_id
  instance_id       = aviatrix_firewall_instance.aws_firewall_instance1_ha.instance_id
  vendor_type       = "Palo Alto Networks VM-Series"
  public_ip         = aviatrix_firewall_instance.aws_firewall_instance1_ha.public_ip
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = aviatrix_firewall_instance.aws_firewall_instance1_ha.firewall_name
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  aviatrix_transit_gateway.transit_ha_aws_reg1]
}
