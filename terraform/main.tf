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

# Elastic IP for Load Balancer
resource "aws_eip" "alb" {
  domain = "vpc"
  
  tags = {
    Name        = "alb-eip-${var.environment}"
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

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow application ports
  ingress {
    from_port   = 3000
    to_port     = 3008
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

# Security Group for Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "alb-sg-${var.environment}"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-${var.environment}"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  # Allow PostgreSQL access from instances
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  tags = {
    Name = "rds-sg-${var.environment}"
  }
}

# Security Group for Redis (ElastiCache)
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg-${var.environment}"
  description = "Security group for Redis ElastiCache"
  vpc_id      = module.vpc.vpc_id

  # Allow Redis access from instances
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  tags = {
    Name = "redis-sg-${var.environment}"
  }
}

# RDS PostgreSQL Database
resource "aws_db_instance" "postgresql" {
  identifier = "auth-db-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "auth_db"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name        = "auth-db-${var.environment}"
    Environment = var.environment
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "auth-db-subnet-group-${var.environment}"
  subnet_ids = module.vpc.private_subnets
  
  tags = {
    Name        = "auth-db-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "auth-redis-subnet-group-${var.environment}"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "auth-redis-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  
  tags = {
    Name        = "auth-redis-${var.environment}"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "auth-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name        = "auth-alb-${var.environment}"
    Environment = var.environment
  }
}

# Associate Elastic IP with Load Balancer
resource "aws_eip_association" "alb" {
  allocation_id = aws_eip.alb.id
  network_interface_id = aws_lb.main.arn_suffix
}

# ALB Target Groups
resource "aws_lb_target_group" "auth" {
  name     = "auth-tg-${var.environment}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "auth-tg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "profile" {
  name     = "profile-tg-${var.environment}"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "profile-tg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "history" {
  name     = "history-tg-${var.environment}"
  port     = 3002
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "history-tg-${var.environment}"
    Environment = var.environment
  }
}

# ALB Listeners
resource "aws_lb_listener" "auth" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }
}

resource "aws_lb_listener_rule" "profile" {
  listener_arn = aws_lb_listener.auth.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.profile.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/profile*", "/profile*"]
    }
  }
}

resource "aws_lb_listener_rule" "history" {
  listener_arn = aws_lb_listener.auth.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.history.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/history*", "/history*"]
    }
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "auth-lt-${var.environment}"
  image_id      = "ami-06528c11a66cef7a8"  # Amazon Linux 2023
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }

  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    environment = var.environment
    db_endpoint = aws_db_instance.postgresql.endpoint
    db_name     = aws_db_instance.postgresql.db_name
    db_username = aws_db_instance.postgresql.username
    db_password = aws_db_instance.postgresql.password
    redis_endpoint = aws_elasticache_cluster.redis.cache_nodes[0].address
    redis_port     = aws_elasticache_cluster.redis.cache_nodes[0].port
    alb_dns_name   = aws_lb.main.dns_name
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "auth-instance-${var.environment}"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "auth-asg-${var.environment}"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  target_group_arns   = [aws_lb_target_group.auth.arn, aws_lb_target_group.profile.arn, aws_lb_target_group.history.arn]
  vpc_zone_identifier = module.vpc.public_subnets

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "auth-asg-${var.environment}"
    propagate_at_launch = true
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "auth-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "auth-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

# Auth Service Module
module "auth_service" {
  source = "./modules/auth"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  instance_sg_id = aws_security_group.instance_sg.id
  target_group_arn = aws_lb_target_group.auth.arn
}

# Profile Service Module
module "profile_service" {
  source = "./modules/profile"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  instance_sg_id = aws_security_group.instance_sg.id
  target_group_arn = aws_lb_target_group.profile.arn
}

# History Service Module
module "history_service" {
  source = "./modules/history"
  
  environment    = var.environment
  instance_type  = var.instance_type
  vpc_id         = module.vpc.vpc_id
  public_subnets = [module.vpc.public_subnets[0]]
  key_name       = var.key_name
  instance_sg_id = aws_security_group.instance_sg.id
  target_group_arn = aws_lb_target_group.history.arn
}

