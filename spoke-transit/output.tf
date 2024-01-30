output "controller_public_ip" {
  value = data.terraform_remote_state.controller.outputs.public_ip

}
output "controller_private_ip" {
  value = data.terraform_remote_state.controller.outputs.private_ip
}

output "controller_ssh_keyfile" {
  value = "/Users/abhishekrao/Downloads/abrao-master-key-Ohio.pem"
}

output "aws_vpc1_public_vm_pub_ip" {
  value       = module.aws_vm-spoke-reg1.vm.public_vm_public_ip_list[0]
  description = "SPOKE1 Public VM Public IP"
}


output "aws_vpc1_public_vm_pri_ip" {
  value       = module.aws_vm-spoke-reg1.vm.vm_private_ip_list[0]
  description = "SPOKE1 Public VM Private IP"
}

output "aws_vpc1_private_vm_pri_ip" {
  value       = module.aws_vm-spoke-reg1.vm.vm_private_ip_list[1]
  description = "SPOKE1 Private VM Private IP"
}


output "aws_vpc2_public_vm_pub_ip" {
  value       = module.aws_vm-spoke-reg2.vm.public_vm_public_ip_list[0]
  description = "Spoke2 Public VM Public IP"
}

output "aws_vpc2_public_vm_pri_ip" {
  value       = module.aws_vm-spoke-reg2.vm.vm_private_ip_list[0]
  description = "Spoke2 Public VM Private IP"
}

output "aws_vpc2_private_vm_pri_ip" {
  value       = module.aws_vm-spoke-reg2.vm.vm_private_ip_list[1]
  description = "Spoke2 Private VM Private IP"
}


output "aws_private_key_filename_spoke1" {
  value       = module.aws_vm-spoke-reg1.vm.private_key_filename
  description = "Spoke1 Key file name"
}

output "aws_private_key_filename_spoke2" {
  value       = module.aws_vm-spoke-reg2.vm.private_key_filename
  description = "Spoke1 Key file name"
}

output "aws_spoke1_gateway_name" {
  sensitive   = true
  value       = aviatrix_spoke_gateway.spoke_gateway_aws.gw_name
  description = "Spoke1  Gateway Name"
}

output "aws_spoke2_gateway_name" {
  sensitive   = true
  value       = aviatrix_spoke_gateway.spoke2_gateway_aws.gw_name
  description = "Spoke2  Gateway Name"
}



output "aws_firenet_gw_name" {
  sensitive   = true
  value       = aviatrix_transit_gateway.aws_transit_1.gw_name
  description = "AWS Firenet gateway name"
}

output "aws_firenet_ha_gw_name" {
  sensitive   = true
  value       = aviatrix_transit_gateway.aws_transit_1.ha_gw_name
  description = "AWS Firenet HA gateway Name"
}


