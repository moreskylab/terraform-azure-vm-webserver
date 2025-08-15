# terraform-azure-vm-webserver
create webserver in azure using terraform 

# Azure Web Server Infrastructure

This Terraform configuration creates a web server infrastructure in Azure, equivalent to the AWS EC2 webserver setup.

## Architecture

- **Resource Group**: Container for all resources
- **Virtual Network**: Network isolation (equivalent to AWS VPC)
- **Subnet**: Public subnet for the web server
- **Network Security Group**: Firewall rules (equivalent to AWS Security Group)
- **Virtual Machine**: Ubuntu web server with Apache
- **Public IP**: Static public IP (equivalent to AWS Elastic IP)
- **Storage Account**: Log storage (equivalent to AWS S3)
- **Managed Identity**: VM permissions (equivalent to AWS IAM Role)

## Prerequisites

1. Azure CLI installed and logged in: `az login`
2. Terraform installed
3. SSH key pair generated: `ssh-keygen -t rsa -b 4096`

## Deployment

1. Clone this repository
2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your desired values
4. Initialize Terraform:
   ```bash
   terraform init
   ```
5. Plan the deployment:
   ```bash
   terraform plan
   ```
6. Apply the configuration:
   ```bash
   terraform apply
   ```

## Accessing the Web Server

After deployment, you can access the web server using the public IP address output by Terraform:
- Web Server: `http://<public_ip>`
- SSH: `ssh azureuser@<public_ip>`

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

## Cost Considerations

- Standard_B1s VM: ~$7.30/month
- Storage Account: ~$0.10/month
- Public IP: ~$2.92/month
- Total estimated cost: ~$10.32/month