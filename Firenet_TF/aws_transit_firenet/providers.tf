terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~>3.1.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
    oci = {
      source = "oracle/oci"
    }
  }
}

# Configure Aviatrix provider
provider "aviatrix" {
  controller_ip           = var.controller_ip
  username                = var.username
  password                = var.password
  skip_version_validation = true
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "google" {
  region      = var.region_gcp
  project     = var.gcloud_project_id
  credentials = var.gcloud_project_credentials_filepath
}

provider "azurerm" {
  features {}
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_id
  user_ocid        = var.oci_user_id
  private_key_path = var.oci_api_private_key_filepath
  region           = var.region_oci
  fingerprint      = var.oci_fingerprint
}


data "terraform_remote_state" "controller" {
  backend = "local"

  config = {
    path = "../../controller/terraform.tfstate"
  }
}