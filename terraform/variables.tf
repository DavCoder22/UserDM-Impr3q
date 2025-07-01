variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "pc1"  # This should match your .pem file name
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ports" {
  description = "Map of service names to their exposed ports"
  type        = map(number)
  default = {
    auth_service = 3000
    # Add other services and their ports here
  }
}
