output "controller_public_ip" {
  value = data.terraform_remote_state.controller.outputs.public_ip
}
output "controller_private_ip" {
  value = data.terraform_remote_state.controller.outputs.private_ip
}

output "controller_ssh_keyfile" {
  #value = var.controller_ssh_keyfile
  value = "/Users/abhishekrao/Downloads/abrao-master-key-Ohio.pem"
}

output "aws_vpc1_public_vm_pub_ip" {
  value       = module.aws_spoke1vm.vm.public_vm_public_ip_list[0]
  description = "SPOKE1 Public VM Public IP"
}


output "aws_vpc1_public_vm_pri_ip" {
  value       = module.aws_spoke1vm.vm.vm_private_ip_list[0]
  description = "SPOKE1 Public VM Private IP"
}

output "aws_vpc1_private_vm_pri_ip" {
  value       = module.aws_spoke1vm.vm.vm_private_ip_list[1]
  description = "SPOKE1 Private VM Private IP"
}


output "aws_vpc2_public_vm_pub_ip" {
  value       = module.aws_vm-spoke2.vm.public_vm_public_ip_list[0]
  description = "Spoke2 Public VM Public IP"
}

output "aws_vpc2_public_vm_pri_ip" {
  value       = module.aws_vm-spoke2.vm.vm_private_ip_list[0]
  description = "Spoke2 Public VM Private IP"
}

output "aws_vpc2_private_vm_pri_ip" {
  value       = module.aws_vm-spoke2.vm.vm_private_ip_list[1]
  description = "Spoke2 Private VM Private IP"
}

output "aws_onprem_public_vm_pub_ip" {
  value       = module.aws-onpremvm.vm.public_vm_public_ip_list[0]
  description = "Onprem DEtails"
}
output "aws_onprem_public_vm_pri_ip" {
  value       = module.aws-onpremvm.vm.vm_private_ip_list[0]
  description = "Onprem Public VM Private IP DEtails"
}

output "aws_onprem_private_vm_pri_ip" {
  value       = module.aws-onpremvm.vm.vm_private_ip_list[1]
  description = "Onprem Private VM Private IP"
}

output "aws_private_key_filename_spoke1" {
  value       = module.aws_spoke1vm.vm.private_key_filename
  description = "Spoke1 Key file name"
}

output "aws_private_key_filename_spoke2" {
  value       = module.aws_vm-spoke2.vm.private_key_filename
  description = "Spoke1 Key file name"
}

output "aws_private_key_filename_onpremvm" {
  value       = module.aws-onpremvm.vm.private_key_filename
  description = "Spoke1 Key file name"
}


output "aws_spoke1_gateway_name" {
  sensitive   = true
  value       = module.spoke_aws_1.spoke_gateway.gw_name
  description = "Spoke1  Gateway Name"
}

output "aws_spoke1_ha_gateway_name" {
  sensitive   = true
  value       = module.spoke_aws_1.spoke_gateway.ha_gw_name
  description = "Spoke1  Gateway Name"
}

output "aws_spoke2_gateway_name" {
  sensitive   = true
  value       = module.spoke_aws_2.spoke_gateway.gw_name
  description = "Spoke2 Gateway Name"
}
output "aws_onprem_gateway_name" {
  sensitive   = true
  value       = module.spoke_aws_on_prem.spoke_gateway.gw_name
  description = "On prem Spoke Gateway Name"
}

output "aws_firenet_gw_name" {
  sensitive   = true
  value       = module.transit_ha_aws.transit_gateway.gw_name
  description = "AWS Firenet gateway name"
}

output "aws_firenet_ha_gw_name" {
  sensitive   = true
  value       = module.transit_ha_aws.transit_gateway.ha_gw_name
  description = "AWS Firenet HA gateway Name"
}

output "aws_transit_fqdn_gw_name" {
  sensitive   = true
  value       = aviatrix_transit_gateway.aws-transit-fqdn-gw.gw_name
  description = "AWS FQDN gateway name"
}

# output "aws_transit_fqdn_ha_gw_name" {
#   sensitive   = true
#   value       = module.transit_ha_fqdn_aws.transit_gateway.ha_gw_name
#   description = "AWS FQDN HA gateway Name"
# }

output "aws_transit_egress_gw_name" {
  sensitive   = true
  value       = module.transit_ha_egress_aws.transit_gateway.gw_name
  description = "AWS FQDN gateway name"
}

output "aws_transit_egress_ha_gw_name" {
  sensitive   = true
  value       = module.transit_ha_egress_aws.transit_gateway.ha_gw_name
  description = "AWS FQDN HA gateway Name"
}


output "aws_firewall_name" {
  sensitive   = true
  value       = module.mc_firenet_ha_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  description = "Firewall Name"
}

output "aws_firewall_ha_name" {
  sensitive   = true
  value       = module.mc_firenet_ha_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  description = "Firewall HA Name"
}

output "aws_egress_firewall_name" {
  sensitive   = true
  value       = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[0].*.firewall_name[0]
  description = "Egress Firewall Name"
}

output "aws_egress_firewall_ha_name" {
  sensitive   = true
  value       = module.mc_firenet_ha_egress_aws.aviatrix_firewall_instance[1].*.firewall_name[0]
  description = "Egress Firewall HA Name"
}


output "aws_on_prem_connection_name" {
  value       = aviatrix_transit_external_device_conn.transittoonprem.connection_name
  description = "AWS S2C Connection Name"
}

output "aws_spoke1_cidr" {
  value       = var.aws_spoke1_cidr
  description = "AWS Spoke1 CIDR"
}
output "aws_spoke2_cidr" {
  value       = var.aws_spoke2_cidr
  description = "AWS Spoke2 CIDR"
}


output "aws_onprem_spoke_cidr" {
  value       = var.aws_onprem_spoke_cidr
  description = "AWS On prem Spoke CIDR"
}




output "aws_onprem_spoke_gw_name" {
  value       = module.spoke_aws_on_prem.spoke_gateway.gw_name
  sensitive   = true
  description = "AWS Onprem Spoke gateway name"

}

output "aws_onprem_transit_gw_name" {
  value       = module.onprem-transit_1.transit_gateway.gw_name
  description = "AWS On Prem Transit gateway name"

}

output "ubuntu_username" {
  value       = "ubuntu"
  description = "Ubuntu Username"
}

output "controller_ssh_keyfile_name" {
  value       = var.controller_ssh_keyfile_name
  description = "Controller SSH Keyfile Name"
}