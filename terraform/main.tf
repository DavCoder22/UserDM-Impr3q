terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Create VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "microservices-vpc-${var.environment}"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway  = true
  enable_vpn_gateway  = false
  
  # Enable DNS hostnames and support for public DNS
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# Security Groups
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg-${var.environment}"
  description = "Security group for microservices instances"
  vpc_id      = module.vpc.vpc_id

  # Allow SSH access from anywhere (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "instance-sg-${var.environment}"
  }
}



# Auth Service
module "auth_service" {
  source = "./modules/auth"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  
  # Security
  instance_sg_id = aws_security_group.instance_sg.id
  

}

# Profile Service
module "profile_service" {
  source = "./modules/profile"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  
  # Security
  instance_sg_id = aws_security_group.instance_sg.id
  

}

# History Service
module "history_service" {
  source = "./modules/history"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  
  # Security
  instance_sg_id = aws_security_group.instance_sg.id
  

}

