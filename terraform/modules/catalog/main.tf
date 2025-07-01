# EC2 Instance for Catalog Service
resource "aws_instance" "catalog_productos" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.catalog_sg.id]
  # Sin perfil de instancia IAM
  key_name      = var.key_name
  
  user_data = templatefile("${path.module}/scripts/catalog_setup.sh", {
    environment = var.environment
    service_name = "productos"
    service_port = 8081
    APP_DIR = "/home/ec2-user/catalog-productos"
  })
  
  tags = {
    Name = "catalog-productos-${var.environment}"
  }
}

resource "aws_instance" "catalog_materiales" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnets[1 % length(var.public_subnets)]
  vpc_security_group_ids = [aws_security_group.catalog_sg.id]
  # Sin perfil de instancia IAM
  key_name      = var.key_name
  
  user_data = templatefile("${path.module}/scripts/catalog_setup.sh", {
    environment = var.environment
    service_name = "materiales"
    service_port = 8082
    APP_DIR = "/home/ec2-user/catalog-materiales"
  })
  
  tags = {
    Name = "catalog-materiales-${var.environment}"
  }
}

# Security Group for Catalog Services
resource "aws_security_group" "catalog_sg" {
  name        = "catalog-sg-${var.environment}"
  description = "Security group for catalog services"
  vpc_id      = var.vpc_id
  
  # Allow HTTP traffic
  ingress {
    from_port   = 8081
    to_port     = 8083
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
    Name = "catalog-sg-${var.environment}"
  }
}
