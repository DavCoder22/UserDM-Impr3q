variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The VPC ID where resources will be created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
}

variable "instance_sg_id" {
  description = "ID of the security group to use for the instance"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group to attach the instance to (optional)"
  type        = string
  default     = null
}

variable "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances (optional)"
  type        = string
  default     = null
}
