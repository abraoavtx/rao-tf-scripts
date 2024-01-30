locals {
  #wan_ip = chomp(data.http.wan_ip.body)
  wan_ip = chomp(data.curl_request.ipaddress.response_body)
  incoming_cidrs = setunion(["152.179.42.234/32", "98.35.216.87/32"])
  backend_passphrase = startswith(var.controller_version, "6.") ? var.backend_passphrase_6 : var.backend_passphrase_7
}


provider "curl" {
}

data "curl_request" "ipaddress" {
  uri = "https://ipv4.icanhazip.com"
  http_method = "GET"
}


module "aviatrix_controller_aws" {
  #source               = "AviatrixSystems/aws-controller/aviatrix"// DO not use this for staging
  source               = "github.com/AviatrixDev/terraform-aviatrix-aws-controller.git"
  create_iam_roles     = false
  incoming_ssl_cidrs   = local.incoming_cidrs
  admin_password       = var.admin_password
  admin_email          = var.admin_email
  access_account_name  = var.access_account_name
  access_account_email = var.access_account_email
  customer_license_id  = var.customer_license_id
  controller_version   = var.controller_version
  controller_name      = "${var.controller_name}-${var.controller_version}"
  aws_account_id       = var.aws_account_id
  use_existing_keypair = true
  type                 = "BYOL"
  #ami_id = var.ami_id
  key_pair_name        = var.key_pair
  release_infra        = var.release_infra

}

resource "aws_security_group_rule" "dev_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.incoming_cidrs
  security_group_id = module.aviatrix_controller_aws.security_group_id
}


provider "http-full" {}

# HTTP POST 
data "http" "enable_ssh_passphrase" {
  provider             = http-full
  url                  = "https://${module.aviatrix_controller_aws.public_ip}/v1/backend1"
  method               = "POST"
  insecure_skip_verify = true
  request_headers = {
    content-type = "application/x-www-form-urlencoded"
  }
  request_body = "action=enable_access_shell&passphrase=${local.backend_passphrase}"
  depends_on   = [module.aviatrix_controller_aws]
}