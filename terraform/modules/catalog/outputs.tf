# Security Group Outputs
output "catalog_sg_id" {
  description = "ID of the catalog security group"
  value       = aws_security_group.catalog_sg.id
}

# EC2 Instance Outputs
output "catalog_productos_public_ip" {
  description = "Public IP of the catalog-productos instance"
  value       = aws_instance.catalog_productos.public_ip
}

output "catalog_productos_private_ip" {
  description = "Private IP of the catalog-productos instance"
  value       = aws_instance.catalog_productos.private_ip
}

output "catalog_materiales_public_ip" {
  description = "Public IP of the catalog-materiales instance"
  value       = aws_instance.catalog_materiales.public_ip
}

output "catalog_materiales_private_ip" {
  description = "Private IP of the catalog-materiales instance"
  value       = aws_instance.catalog_materiales.private_ip
}

# Service Endpoints
output "catalog_productos_endpoint" {
  description = "Endpoint URL for the catalog-productos service"
  value       = "http://${aws_instance.catalog_productos.public_ip}:8081"
}

output "catalog_materiales_endpoint" {
  description = "Endpoint URL for the catalog-materiales service"
  value       = "http://${aws_instance.catalog_materiales.public_ip}:8082"
}
