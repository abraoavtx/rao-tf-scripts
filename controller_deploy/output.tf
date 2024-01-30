output "public_ip" {
  value = module.aviatrix_controller_aws.public_ip
}

output "private_ip" {
  value = module.aviatrix_controller_aws.private_ip
}

output "vpc_id" {
  value = module.aviatrix_controller_aws.vpc_id
}

output "security_group" {
  value = module.aviatrix_controller_aws.security_group_id
}


output "data_ssh_response" {
  value = data.http.enable_ssh_passphrase.response_body
}

output "ipaddress_response" {
  value = {
    status_code = data.curl_request.ipaddress.response_status_code
    body        = data.curl_request.ipaddress.response_body
  }
}


output "account_name_aws" {
  value = var.access_account_name
}