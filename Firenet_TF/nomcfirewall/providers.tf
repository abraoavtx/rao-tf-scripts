terraform {
  required_providers {
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "~>3.1.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
    google = {
      source = "hashicorp/google"
    }
    oci = {
      source = "oracle/oci"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias      = "east-1"
  region     = var.aws_region1
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
provider "aws" {
  alias      = "east2"
  region     = var.aws_region2
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


data "terraform_remote_state" "controller" {
  backend = "local"

  config = {
    path = "../../controller/terraform.tfstate"
  }
}

# Configure Aviatrix provider
provider "aviatrix" {
  controller_ip           = data.terraform_remote_state.controller.public_ip
  username                = var.username
  password                = var.password
  skip_version_validation = true
}

provider "google" {
  region      = var.gcp_region
  project     = var.gcloud_project_id
  credentials = var.gcloud_project_credentials_filepath
}


provider "azurerm" {
  skip_provider_registration = true
  client_id                  = var.client_id
  environment                = var.environment
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  client_secret              = var.client_secret
  features {}
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_id
  user_ocid        = var.oci_user_id
  private_key_path = var.oci_api_private_key_filepath
  region           = "us-phoenix-1"
  fingerprint      = var.oci_fingerprint
}

