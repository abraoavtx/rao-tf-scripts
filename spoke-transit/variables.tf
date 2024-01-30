variable "controller_ip" {
  #default = data.terraform_remote_state.controller.outputs.public_ip
}
variable "aws_spoke1_cidr" {
}
variable "aws_spoke2_cidr" {
}
variable "aws_transit1_cidr" {
}

variable "aws_region1" {
}
variable "region_azure" {

}

variable "username" {
  default = "admin"
}
variable "password" {

}
variable "account_name_aws" {

}
variable "ubuntu_username" {
  default = "ubuntu"
}
variable "gcloud_project_id" {

}
variable "gcloud_project_credentials_filepath" {

}

variable "oci_tenancy_id" {

}
variable "oci_user_id" {

}
variable "oci_api_private_key_filepath" {

}
variable "region_oci" {

}
variable "oci_fingerprint" {

}

variable "pre_shared_key" {
}
variable "testbed" {

}
variable "release" {

}

variable "aws_access_key" {

}

variable "aws_secret_key" {

}
variable "aws_region2" {

}


variable "region_gcp" {

}
variable "controller_ssh_keyfile_name" {

}
