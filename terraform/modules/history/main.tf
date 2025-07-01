# EC2 Instance for History Service
resource "aws_instance" "history_service" {
  ami                    = "ami-06528c11a66cef7a8"  # SUSE Linux AMI
  instance_type          = var.instance_type
  subnet_id              = var.public_subnets[0]
  vpc_security_group_ids = [var.instance_sg_id]
  key_name               = var.key_name
  
  # Enable automatic public IP assignment
  associate_public_ip_address = true
  
  user_data = file("${path.module}/scripts/history_service_setup.sh")
  
  tags = {
    Name = "history-service-${var.environment}"
  }
}

# Attach instance to target group if target_group_arn is provided
resource "aws_lb_target_group_attachment" "history" {
  count            = var.target_group_arn != null ? 1 : 0
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.history_service.id
  port             = 4567
}

# Outputs
output "history_instance_id" {
  value = aws_instance.history_service.id
}

output "history_public_ip" {
  value = aws_instance.history_service.public_ip
}

output "history_private_ip" {
  value = aws_instance.history_service.private_ip
}

output "history_private_dns" {
  value = aws_instance.history_service.private_dns
}

output "history_public_dns" {
  value = aws_instance.history_service.public_dns
}
