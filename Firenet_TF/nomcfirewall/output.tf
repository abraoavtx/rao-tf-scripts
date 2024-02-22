output "aws_firewall_reg1_ip" {
  value       = aviatrix_firewall_instance.aws_firewall_instance1.public_ip
  description = "PAN1 Public IP"
}

output "aws_firewall_ha_reg1_ip" {
  value       = aviatrix_firewall_instance.aws_firewall_instance1_ha.public_ip
  description = "PAN1-HA Public IP"
}