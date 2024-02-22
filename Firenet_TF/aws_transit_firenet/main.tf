locals {
  prefix = "${var.release}-${var.testbed}"
}

#AWS Transit Gateway HA 
module "transit_ha_aws" {
  source = "terraform-aviatrix-modules/mc-transit/aviatrix"
  cloud                  = "aws"
  name                   = "aws-transit-${local.prefix}"
  region                 = var.aws_region
  cidr                   = var.aws_transit1_cidr
  account                = var.account_name_aws
  enable_spot_instance = true
  insane_mode            = true
  enable_transit_firenet = true
}

#Attach Firewalls to Transit Gateway
module "mc_firenet_ha_aws" {
  source = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  transit_module                       = module.transit_ha_aws
  firewall_image                       = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  egress_enabled                       = true
  custom_fw_names                      = ["aws-fw1-${local.prefix}", "aws-fw2-${local.prefix}"]
  //Use this only for bootstrap
  #iam_role_1                           = var.iam_role_1
  #bootstrap_bucket_name_1              = var.bootstrap_bucket_name_1
  keep_alive_via_lan_interface_enabled = true
  depends_on                           = [module.transit_ha_aws.transit_gateway]
}
module "transit_ha_egress_aws" {
  source      = "terraform-aviatrix-modules/mc-transit/aviatrix"
  #version     = "v2.3.0"
  cloud       = "aws"
  name        = "aws-tx-egress-${local.prefix}"
  region      = var.aws_region
  cidr        = var.aws_transit_egress_cidr
  account     = var.account_name_aws
  insane_mode = true
  enable_spot_instance = true
  #enable_transit_firenet = true
  enable_egress_transit_firenet = true
}

module "mc_firenet_ha_egress_aws" {
  source = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  #version = "1.3.0"
  #version = "1.4.3"
  transit_module                       = module.transit_ha_egress_aws
  firewall_image                       = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  egress_enabled                       = false
  custom_fw_names                      = ["egress-fw1-${local.prefix}", "egress-fw2-${local.prefix}"]
  iam_role_1                           = var.iam_role_1
  bootstrap_bucket_name_1              = var.bootstrap_bucket_name_1
  keep_alive_via_lan_interface_enabled = true
  depends_on                           = [module.transit_ha_egress_aws.transit_gateway]
}

#Create Security VPC for FireNet
resource "aviatrix_vpc" "security-vpc" {
  cloud_type           = 1
  account_name         = var.account_name_aws
  region               = var.aws_region
  name                 = "fqdn-vpc-${local.prefix}"
  cidr                 = var.aws_efqdn_vpc_cidr
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = true
}

#Create an Aviatrix FireNet Gateway
resource "aviatrix_transit_gateway" "aws-transit-fqdn-gw" {
  cloud_type             = 1
  account_name           = var.account_name_aws
  gw_name                = "avx-tx-fqdn-gw-${local.prefix}"
  vpc_id                 = aviatrix_vpc.security-vpc.vpc_id
  vpc_reg                = aviatrix_vpc.security-vpc.region
  gw_size                = "c5.xlarge"
  subnet                 = aviatrix_vpc.security-vpc.subnets[0].cidr
  single_ip_snat         = false
  connected_transit      = true
  insane_mode            = false
  enable_transit_firenet = true
  #ha_subnet                = aviatrix_vpc.security-vpc.subnets[2].cidr
  #ha_gw_size               = "c5.xlarge"
  #enable_active_mesh       = true
}

#Create an Aviatrix FQDN GW instance
resource "aviatrix_gateway" "aws-fqdn-gw" {
  cloud_type     = 1
  account_name   = var.account_name_aws
  gw_name        = "avx-fqdn-gw-${local.prefix}"
  vpc_id         = aviatrix_vpc.security-vpc.vpc_id
  vpc_reg        = aviatrix_vpc.security-vpc.region
  gw_size        = "t3.micro"
  subnet         = aviatrix_vpc.security-vpc.subnets[0].cidr
  single_az_ha   = true
  single_ip_snat = false
}

resource "aviatrix_fqdn" "FQDN-allow" {
  fqdn_tag            = "test-firenet-fqdn-allow"
  fqdn_enabled        = true
  fqdn_mode           = "white"
  manage_domain_names = false
  depends_on          = [aviatrix_firenet.fqdn_firenet]

  gw_filter_tag_list {
    gw_name = aviatrix_gateway.aws-fqdn-gw.gw_name
  }
}

# Create an Aviatrix Gateway FQDN Tag Rule filter rule
resource "aviatrix_fqdn_tag_rule" "test_fqdn" {
  fqdn_tag_name = aviatrix_fqdn.FQDN-allow.fqdn_tag
  fqdn          = "reddit.com"
  protocol      = "icmp"
  port          = "ping"
}


resource "aviatrix_firenet" "fqdn_firenet" {
  vpc_id             = aviatrix_vpc.security-vpc.vpc_id
  inspection_enabled = false // FQDN doesn't inspect E-W, N-S traffic flows
  egress_enabled     = true
  keep_alive_via_lan_interface_enabled = true
  #manage_firewall_instance_association = false

  depends_on = [aviatrix_firewall_instance_association.fqdn]
}

# Associate an Aviatrix FireNet Gateway with a Firewall Instance
resource "aviatrix_firewall_instance_association" "fqdn" {
  vpc_id          = aviatrix_vpc.security-vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.aws-transit-fqdn-gw.gw_name
  instance_id     = aviatrix_gateway.aws-fqdn-gw.gw_name
  vendor_type     = "fqdn_gateway"
  attached        = true
}


#AWS Spoke-1 VPC in HA mode
module "spoke_aws_1" {
  source = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  #version = "1.4.2"
  #version     = "v1.6.2"
  cloud       = "AWS"
  name        = "aws-spk1-${local.prefix}"
  cidr        = var.aws_spoke1_cidr
  region      = var.aws_region
  account     = var.account_name_aws
  insane_mode = true
  enable_spot_instance = true
  transit_gw  = module.transit_ha_aws.transit_gateway.gw_name
  depends_on  = [module.transit_ha_aws.transit_gateway]
}

#AWS Spoke-2 VPC
module "spoke_aws_2" {
  source = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  #version = "1.4.2"
  #version     = "v1.6.2"
  cloud       = "AWS"
  name        = "aws-spk2-${local.prefix}"
  cidr        = var.aws_spoke2_cidr
  region      = var.aws_region
  account     = var.account_name_aws
  ha_gw       = false
  insane_mode = false
  enable_spot_instance = true
  transit_gw  = module.transit_ha_aws.transit_gateway.gw_name
  depends_on  = [module.transit_ha_aws.transit_gateway]
}


#Vendor Integration of Transit Firewalls
data "aviatrix_firenet_vendor_integration" "foo" {
  vpc_id      = module.transit_ha_aws.vpc.vpc_id
  instance_id = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.instance_id[0]
  vendor_type = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip         = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.public_ip[0]
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  module.transit_ha_aws.transit_gateway]
}

data "aviatrix_firenet_vendor_integration" "foo2" {
  vpc_id      = module.transit_ha_aws.vpc.vpc_id
  instance_id = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.instance_id[0]
  vendor_type = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip         = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.public_ip[0]
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  module.transit_ha_aws.transit_gateway]
}

#Vendor Integration of Egress Firewalls
data "aviatrix_firenet_vendor_integration" "foo_egress1" {
  vpc_id      = module.transit_ha_egress_aws.vpc.vpc_id
  instance_id = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[0].*.instance_id[0]
  vendor_type = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip         = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[0].*.public_ip[0]
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  module.transit_ha_egress_aws.transit_gateway]
}

data "aviatrix_firenet_vendor_integration" "foo_egress2" {
  vpc_id      = module.transit_ha_egress_aws.vpc.vpc_id
  instance_id = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[1].*.instance_id[0]
  vendor_type = "Palo Alto Networks VM-Series"
  #vendor_type   = "Generic"
  public_ip         = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[1].*.public_ip[0]
  username          = "admin"
  password          = "aviaReg!23"
  firewall_name     = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  save              = true
  number_of_retries = 2
  retry_interval    = 900
  depends_on = [
  module.transit_ha_egress_aws.transit_gateway]
}


#AWS Onprem Transit Gateway
module "onprem-transit_1" {
  source      = "terraform-aviatrix-modules/mc-transit/aviatrix"
  #version     = "v2.3.0"
  cloud       = "aws"
  name        = "aws-onprem-${local.prefix}"
  region      = var.aws_region
  cidr        = var.aws_onprem_transit_cidr
  account     = var.account_name_aws
  insane_mode = true
  enable_spot_instance = true
  ha_gw       = false
}
#On-Prem Spoke Gateway
module "spoke_aws_on_prem" {
  source = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  #version = "1.4.2"
  #version     = "v1.6.2"
  cloud       = "AWS"
  name        = "onprem-aws-spoke-${local.prefix}"
  cidr        = var.aws_onprem_spoke_cidr
  region      = var.aws_region
  account     = var.account_name_aws
  ha_gw       = false
  insane_mode = true
  enable_spot_instance = true
  transit_gw  = module.onprem-transit_1.transit_gateway.gw_name
  depends_on = [
  module.onprem-transit_1.transit_gateway]
}

#Create External Connectiom Between Onprem to Transit 
resource "aviatrix_transit_external_device_conn" "onpremtotransit" {
  vpc_id                    = module.onprem-transit_1.vpc.vpc_id
  connection_name           = "awsnpremtotransit-${local.prefix}"
  gw_name                   = module.onprem-transit_1.transit_gateway.gw_name
  connection_type           = "bgp"
  tunnel_protocol           = "IPsec"
  bgp_local_as_num          = "64214"
  bgp_remote_as_num         = "64215"
  pre_shared_key            = var.pre_shared_key
  remote_gateway_ip         = module.transit_ha_aws.transit_gateway.eip
  local_tunnel_cidr         = "169.254.254.145/30"
  remote_tunnel_cidr        = "169.254.254.146/30"
  ha_enabled                = true
  backup_bgp_remote_as_num  = "64215"
  backup_pre_shared_key     = var.pre_shared_key
  backup_remote_gateway_ip  = module.transit_ha_aws.transit_gateway.ha_eip
  backup_local_tunnel_cidr  = "169.254.254.149/30"
  backup_remote_tunnel_cidr = "169.254.254.150/30"
}

#Create External Connectiom Between Transit to Onprem
resource "aviatrix_transit_external_device_conn" "transittoonprem" {
  vpc_id             = module.transit_ha_aws.vpc.vpc_id
  connection_name    = "transittoonprem-${local.prefix}"
  gw_name            = module.transit_ha_aws.transit_gateway.gw_name
  connection_type    = "bgp"
  tunnel_protocol    = "IPSEC"
  bgp_local_as_num   = "64215"
  bgp_remote_as_num  = "64214"
  pre_shared_key     = var.pre_shared_key
  remote_gateway_ip  = module.onprem-transit_1.transit_gateway.eip
  local_tunnel_cidr  = "169.254.254.146/30,169.254.254.150/30"
  remote_tunnel_cidr = "169.254.254.145/30,169.254.254.149/30"
}

module "aws_spoke1vm" {
  # will generate 1 pair of pri+pub vm on that vpc we created
  source              = "github.com/AviatrixDev/regression/avxt/terraform/modules/mc-vm"
  cloud               = "aws"
  resource_name_label = "tf-aws-vm-${local.prefix}"
  region              = var.aws_region
  vpc_id              = module.spoke_aws_1.vpc.vpc_id
  public_subnet_id    = module.spoke_aws_1.vpc.public_subnets[0].subnet_id
  private_subnet_id   = module.spoke_aws_1.vpc.private_subnets[0].subnet_id
  ingress_cidrs       = ["0.0.0.0/0", "0.0.0.0/0"]
  owner               = "tf_abrao"
}

resource "null_resource" "terraform-aws-vm-spoke1" {
  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = module.aws_spoke1vm.vm.private_key_filename
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_spoke1vm.vm.private_key_filename}")
      host        = module.aws_spoke1vm.vm.public_vm_public_ip_list[0]
    }
    #depends_on = [module.aws_vm_spoke_onprem]
  }

  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_spoke1vm.vm.private_key_filename}")
      host        = module.aws_spoke1vm.vm.public_vm_public_ip_list[0]
    }

  }
}


module "aws_vm-spoke2" {
  # will generate 1 pair of pri+pub vm on that vpc we created
  #source = "../mc-vm"
  source              = "github.com/AviatrixDev/regression/avxt/terraform/modules/mc-vm"
  cloud               = "aws"
  resource_name_label = "tf-aws-vm-spk2-${local.prefix}"
  region              = var.aws_region
  vpc_id              = module.spoke_aws_2.vpc.vpc_id
  public_subnet_id    = module.spoke_aws_2.vpc.public_subnets[0].subnet_id
  private_subnet_id   = module.spoke_aws_2.vpc.private_subnets[0].subnet_id
  ingress_cidrs       = ["0.0.0.0/0", "0.0.0.0/0"]
  owner               = "tf_abrao"
}

resource "null_resource" "terraform-aws-vm-spoke2" {
  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = module.aws_vm-spoke2.vm.private_key_filename
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke2.vm.private_key_filename}")
      host        = module.aws_vm-spoke2.vm.public_vm_public_ip_list[0]
    }
    #depends_on = [module.aws_vm_spoke_onprem]
  }

  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke2.vm.private_key_filename}")
      host        = module.aws_vm-spoke2.vm.public_vm_public_ip_list[0]
    }

  }
}
module "aws-onpremvm" {
  # will generate 1 pair of pri+pub vm on that vpc we created
  #source = "../mc-vm"
  source              = "github.com/AviatrixDev/regression/avxt/terraform/modules/mc-vm"
  cloud               = "aws"
  resource_name_label = "tf-aws-vm-onprem-${local.prefix}"
  region              = var.aws_region
  vpc_id              = module.spoke_aws_on_prem.vpc.vpc_id
  public_subnet_id    = module.spoke_aws_on_prem.vpc.public_subnets[0].subnet_id
  private_subnet_id   = module.spoke_aws_on_prem.vpc.private_subnets[0].subnet_id
  ingress_cidrs       = ["0.0.0.0/0", "0.0.0.0/0"]
  owner               = "tf_abrao"
}

resource "null_resource" "terraform-aws-vm-onprem" {
  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = module.aws-onpremvm.vm.private_key_filename
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws-onpremvm.vm.private_key_filename}")
      host        = module.aws-onpremvm.vm.public_vm_public_ip_list[0]
    }
  }

  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws-onpremvm.vm.private_key_filename}")
      host        = module.aws-onpremvm.vm.public_vm_public_ip_list[0]
    }

  }
}