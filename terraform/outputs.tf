# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

# Load Balancer Outputs
output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# Elastic IP Outputs
output "alb_elastic_ip" {
  description = "Elastic IP address of the Load Balancer"
  value       = aws_eip.alb.public_ip
}

output "alb_elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP"
  value       = aws_eip.alb.allocation_id
}

# Target Groups Outputs
output "auth_target_group_arn" {
  description = "ARN of the Auth service target group"
  value       = aws_lb_target_group.auth.arn
}

output "profile_target_group_arn" {
  description = "ARN of the Profile service target group"
  value       = aws_lb_target_group.profile.arn
}

output "history_target_group_arn" {
  description = "ARN of the History service target group"
  value       = aws_lb_target_group.history.arn
}

# Database Outputs
output "database_endpoint" {
  description = "Endpoint of the RDS PostgreSQL database"
  value       = aws_db_instance.postgresql.endpoint
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgresql.db_name
}

output "database_port" {
  description = "Port of the database"
  value       = aws_db_instance.postgresql.port
}

# Redis Outputs
output "redis_endpoint" {
  description = "Endpoint of the Redis ElastiCache cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Port of the Redis ElastiCache cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}

# Auto Scaling Group Outputs
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

# Security Groups Outputs
output "instance_security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance_sg.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis_sg.id
}

# Service URLs
output "auth_service_url" {
  description = "URL for the Auth service"
  value       = "http://${aws_lb.main.dns_name}/api/v1/auth"
}

output "profile_service_url" {
  description = "URL for the Profile service"
  value       = "http://${aws_lb.main.dns_name}/api/v1/profile"
}

output "history_service_url" {
  description = "URL for the History service"
  value       = "http://${aws_lb.main.dns_name}/api/v1/history"
}

output "health_check_url" {
  description = "URL for the health check endpoint"
  value       = "http://${aws_lb.main.dns_name}/health"
}

# Module Outputs
output "auth_service_instance_id" {
  description = "Instance ID of the Auth service"
  value       = module.auth_service.instance_id
}

output "profile_service_instance_id" {
  description = "Instance ID of the Profile service"
  value       = module.profile_service.instance_id
}

output "history_service_instance_id" {
  description = "Instance ID of the History service"
  value       = module.history_service.instance_id
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.vpc.vpc_id
    alb_dns     = aws_lb.main.dns_name
    alb_ip      = aws_eip.alb.public_ip
    services = {
      auth    = "http://${aws_lb.main.dns_name}/api/v1/auth"
      profile = "http://${aws_lb.main.dns_name}/api/v1/profile"
      history = "http://${aws_lb.main.dns_name}/api/v1/history"
    }
    database = {
      endpoint = aws_db_instance.postgresql.endpoint
      name     = aws_db_instance.postgresql.db_name
    }
    redis = {
      endpoint = aws_elasticache_cluster.redis.cache_nodes[0].address
      port     = aws_elasticache_cluster.redis.cache_nodes[0].port
    }
  }
}
