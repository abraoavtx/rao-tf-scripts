terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~>3.0.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
    http-full = {
      source = "salrashid123/http-full"
    }
    curl = {
      source = "marcofranssen/curl"
    }
  }
}

provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
