locals {
  prefix = "${var.testbed}-${var.release}"
}

#Create an AWS Spoke1 Non-Insane VPC 
resource "aviatrix_vpc" "aws_spoke1_vpc" {
  cloud_type           = 1
  account_name         = var.account_name_aws
  name                 = "spk1-${local.prefix}"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  region               = var.aws_region1
  cidr                 = var.aws_spoke1_cidr
}

# Create an Aviatrix AWS Spoke1  Gateway
resource "aviatrix_spoke_gateway" "spoke_gateway_aws" {
  cloud_type     = 1
  account_name   = var.account_name_aws
  gw_name        = "spk1-${local.prefix}"
  vpc_id         = aviatrix_vpc.aws_spoke1_vpc.vpc_id
  vpc_reg        = var.aws_region1
  subnet         = aviatrix_vpc.aws_spoke1_vpc.public_subnets[0].cidr
  gw_size        = "t3.medium"
  single_ip_snat = false
  #manage_transit_gateway_attachment = false
}


#Create an AWS Spoke2 VPC
resource "aviatrix_vpc" "aws_spoke2_vpc" {
  cloud_type           = 1
  account_name         = var.account_name_aws
  name                 = "spoke2-${local.prefix}"
  aviatrix_transit_vpc = false
  aviatrix_firenet_vpc = false
  region               = var.aws_region2
  cidr                 = var.aws_spoke2_cidr
}

# Create an Aviatrix AWS Spoke2  Gateway
resource "aviatrix_spoke_gateway" "spoke2_gateway_aws" {
  cloud_type     = 1
  account_name   = var.account_name_aws
  gw_name        = "spoke2-${local.prefix}"
  vpc_id         = aviatrix_vpc.aws_spoke2_vpc.vpc_id
  vpc_reg        = var.aws_region2
  subnet         = aviatrix_vpc.aws_spoke2_vpc.public_subnets[0].cidr
  gw_size        = "t3.medium"
  single_ip_snat = false
  #manage_transit_gateway_attachment = false
}

// Create AWS Transit1 VPC
resource "aviatrix_vpc" "aws_transit1_vpc" {
  name         = "transit-1-${local.prefix}"
  account_name = var.account_name_aws
  cloud_type   = 1
  cidr         = var.aws_transit1_cidr
  region       = var.aws_region1

}

// Create AWS Transit
resource "aviatrix_transit_gateway" "aws_transit_1" {
  account_name           = var.account_name_aws
  cloud_type             = 1
  gw_name                = "aws-transit1-${local.prefix}"
  gw_size                = "c5n.xlarge"
  ha_gw_size             = "c5n.xlarge"
  insane_mode            = false
  subnet                 = aviatrix_vpc.aws_transit1_vpc.public_subnets[0].cidr
  ha_subnet              = aviatrix_vpc.aws_transit1_vpc.public_subnets[1].cidr
  vpc_id                 = aviatrix_vpc.aws_transit1_vpc.vpc_id
  vpc_reg                = aviatrix_vpc.aws_transit1_vpc.region
  local_as_number        = 65511
  enable_transit_firenet = true
  connected_transit      = true
}


resource "aviatrix_spoke_transit_attachment" "spoke1_transit" {
  spoke_gw_name   = aviatrix_spoke_gateway.spoke_gateway_aws.gw_name
  transit_gw_name = aviatrix_transit_gateway.aws_transit_1.gw_name

}

resource "aviatrix_spoke_transit_attachment" "spoke2_transit" {
  spoke_gw_name   = aviatrix_spoke_gateway.spoke2_gateway_aws.gw_name
  transit_gw_name = aviatrix_transit_gateway.aws_transit_1.gw_name
}


module "aws_vm-spoke-reg1" {
  # will generate 1 pair of pri+pub vm on that vpc we created    `
  source              = "github.com/AviatrixDev/regression/avxt/terraform/modules/mc-vm"
   cloud               = "aws"
  resource_name_label = "tf-aws-vm-spk1-${local.prefix}"
  region              = aviatrix_vpc.aws_spoke1_vpc.region
  vpc_id              = aviatrix_vpc.aws_spoke1_vpc.vpc_id
  public_subnet_id    = aviatrix_vpc.aws_spoke1_vpc.public_subnets[0].subnet_id
  private_subnet_id   = aviatrix_vpc.aws_spoke1_vpc.private_subnets[0].subnet_id
  ingress_cidrs       = ["0.0.0.0/0", "0.0.0.0/0"]
  owner               = "tf_abrao"
}

resource "null_resource" "terraform-aws-vm-spoke1" {
  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = module.aws_vm-spoke-reg1.vm.private_key_filename
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke-reg1.vm.private_key_filename}")
      host        = module.aws_vm-spoke-reg1.vm.public_vm_public_ip_list[0]
    }
  }

  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke-reg1.vm.private_key_filename}")
      host        = module.aws_vm-spoke-reg1.vm.public_vm_public_ip_list[0]
    }

  }
}


module "aws_vm-spoke-reg2" {
  # will generate 1 pair of pri+pub vm on that vpc we created    `
  source = "github.com/AviatrixDev/regression/avxt/terraform/modules/mc-vm"
   cloud               = "aws"
  providers = {
    aws = aws.west
  }
  resource_name_label = "tf-aws-vm-spk2-${local.prefix}"
  region              = aviatrix_vpc.aws_spoke2_vpc.region
  vpc_id              = aviatrix_vpc.aws_spoke2_vpc.vpc_id
  public_subnet_id    = aviatrix_vpc.aws_spoke2_vpc.public_subnets[0].subnet_id
  private_subnet_id   = aviatrix_vpc.aws_spoke2_vpc.private_subnets[0].subnet_id
  ingress_cidrs       = ["0.0.0.0/0", "0.0.0.0/0"]
  owner               = "tf_abrao"
}

resource "null_resource" "terraform-aws-vm-spoke2" {
  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = module.aws_vm-spoke-reg2.vm.private_key_filename
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke-reg2.vm.private_key_filename}")
      host        = module.aws_vm-spoke-reg2.vm.public_vm_public_ip_list[0]
    }
  }

  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 /home/ubuntu/.ssh/id_rsa"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${module.aws_vm-spoke-reg2.vm.private_key_filename}")
      host        = module.aws_vm-spoke-reg2.vm.public_vm_public_ip_list[0]
    }

  }
}