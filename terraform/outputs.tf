# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

# Auth Service Outputs
output "auth_service_public_ip" {
  description = "Public IP of the Auth Service instance (Elastic IP)"
  value       = module.auth_service.auth_service_public_ip
}

output "auth_service_public_dns" {
  description = "Public DNS of the Auth Service instance (Elastic IP)"
  value       = module.auth_service.auth_service_public_dns
}

output "auth_service_private_ip" {
  description = "Private IP of the Auth Service instance"
  value       = module.auth_service.auth_service_private_ip
}

# Profile Service Outputs
output "profile_service_public_ip" {
  description = "Public IP of the Profile Service instance (Elastic IP)"
  value       = module.profile_service.profile_public_ip
}

output "profile_service_public_dns" {
  description = "Public DNS of the Profile Service instance (Elastic IP)"
  value       = module.profile_service.profile_public_dns
}

output "profile_service_private_ip" {
  description = "Private IP of the Profile Service instance"
  value       = module.profile_service.profile_private_ip
}

# History Service Outputs
output "history_service_public_ip" {
  description = "Public IP of the History Service instance (Elastic IP)"
  value       = module.history_service.history_public_ip
}

output "history_service_public_dns" {
  description = "Public DNS of the History Service instance (Elastic IP)"
  value       = module.history_service.history_public_dns
}

output "history_service_private_ip" {
  description = "Private IP of the History Service instance"
  value       = module.history_service.history_private_ip
}

# SSH Access Commands
output "ssh_auth_service" {
  description = "Command to SSH into the Auth Service instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.auth_service.auth_service_public_ip}"
}

output "ssh_profile_service" {
  description = "Command to SSH into the Profile Service instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.profile_service.profile_public_ip}"
}

output "ssh_history_service" {
  description = "Command to SSH into the History Service instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.history_service.history_public_ip}"
}

# Direct Service Endpoints
output "auth_service_url" {
  description = "Direct URL to access the Auth Service"
  value       = "http://${module.auth_service.auth_service_public_ip}:4567"
}

output "profile_service_url" {
  description = "Direct URL to access the Profile Service"
  value       = "http://${module.profile_service.profile_public_ip}:4567"
}

output "history_service_url" {
  description = "Direct URL to access the History Service"
  value       = "http://${module.history_service.history_public_ip}:4567"
}
