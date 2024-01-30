variable "admin_password" {
}
variable "admin_email" {
  default = ""
}

variable "access_account_email" {
  default = ""
}
variable "access_account_name" {
  default = "reg_controller"
}
variable "customer_license_id" {
    default = ""
}
variable "controller_version" {
}

variable "aws_access_key" {
}

variable "aws_secret_key" {
}
variable "controller_name" {
}

variable "key_pair" {
  default = ""
}
variable "aws_account_id" {
}

variable "incoming_ssl_cidrs" {
  default = ["152.179.42.234/32", "73.70.165.140/32"]

}

variable "release_infra" {
  default     = "staging"
  description = "Can be one of the prod,dev or staging"
}
variable "ami_id"{
  default = ""
  
}
variable "backend_passphrase_6" {
}

variable "backend_passphrase_7" {
}