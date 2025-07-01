# Terraform Configuration for Microservices on AWS EC2

This directory contains Terraform configurations to deploy microservices on AWS EC2 instances.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (v1.2.0 or later)
2. [AWS CLI](https://aws.amazon.com/cli/) installed and configured with appropriate credentials
3. An existing AWS key pair for SSH access (or create a new one in the AWS Console)
4. Required AWS permissions to create resources (VPC, EC2, IAM, etc.)

## Directory Structure

```
terraform/
├── main.tf              # Main Terraform configuration
├── variables.tf          # Variable definitions
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (sensitive, should be in .gitignore)
└── scripts/
    └── auth_service_setup.sh  # Bootstrap script for auth service
```

## Configuration

1. **Update Variables**:
   - Edit `terraform.tfvars` to set your AWS region, instance type, and other parameters.
   - Update the `key_name` with your AWS key pair name.

2. **Update Bootstrap Script**:
   - Edit `scripts/auth_service_setup.sh` to point to your actual repository.
   - Update environment variables as needed.

## Usage

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Review Plan**:
   ```bash
   terraform plan
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm the changes.

4. **Access the Service**:
   - After the apply completes, Terraform will output the public DNS and IP of your instance.
   - Access the auth service at `http://<public-ip>`

## Managing the Infrastructure

- **View Outputs**:
  ```bash
  terraform output
  ```

- **Destroy Resources** (when done):
  ```bash
  terraform destroy
  ```

## Security Notes

1. **SSH Access**:
   - The security group allows SSH from any IP (0.0.0.0/0).
   - Restrict this to your IP address in production.

2. **Secrets Management**:
   - Store sensitive values in environment variables or a secrets manager.
   - Do not commit sensitive data to version control.

3. **Updates**:
   - To update the infrastructure, modify the Terraform files and run `terraform apply` again.

## Next Steps

1. Set up monitoring and logging
2. Configure auto-scaling
3. Set up a custom domain with SSL
4. Implement CI/CD for automated deployments
