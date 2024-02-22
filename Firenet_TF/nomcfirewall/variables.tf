variable "controller_ip" {
}
variable "username" {
  default = "admin"
}
variable "password" {
  default = "aviaReg!23"
}
variable "account_name_aws" {

}
variable "aws_region" {
  default = "us-east-1"
}

variable "aws_region1" {
  default = "us-east-1"
}

variable "aws_region2" {
  default = "us-east-2"
}
variable "aws_access_key" {

}
variable "aws_secret_key" {

}
variable "pre_shared_key" {

}
variable "iam_role_1" {

}
variable "iam_role_2" {}
variable "bootstrap_bucket_name_1" {

}
variable "bootstrap_bucket_name_2" {

}
variable "gcloud_project_id" {

}
variable "gcloud_project_credentials_filepath" {

}

variable "region_oci" {

}
variable "oci_tenancy_id" {

}
variable "oci_user_id" {

}
variable "oci_api_private_key_filepath" {

}
variable "oci_fingerprint" {

}
variable "gcp_region" {
  default = "us-west1"

}
variable "aws_spoke1_cidr" {

}

variable "transit_gw_reg1_attrs" {
  default = {
    transit_reg1 = {
      region            = "us-east-1"
      gw_name           = "transit-east1"
      insane_mode_az    = "us-east-1a"
      ha_insane_mode_az = "us-east-1b"
      asn               = "65001"
    }
  }
}
