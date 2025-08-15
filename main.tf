# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Generate a random suffix for global uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-webserver-${var.environment}"
  location = var.location

  tags = {
    Name        = "tf-main-rg"
    Environment = var.environment
  }
}

# Create a virtual network (equivalent to AWS VPC)
resource "azurerm_virtual_network" "main" {
  name                = "vnet-main-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "tf-main-vnet"
  }
}

# Create a public subnet
resource "azurerm_subnet" "public" {
  name                 = "subnet-public-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP (equivalent to AWS Elastic IP)
resource "azurerm_public_ip" "web" {
  name                = "pip-webserver-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "tf-web-server-pip"
  }
}

# Create Network Security Group (equivalent to AWS Security Group)
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "tf-web-sg"
  }
}

# Create Storage Account (equivalent to AWS S3)
resource "azurerm_storage_account" "logs" {
  name                     = "stlogsweb${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = {
    Name = "tf-web-server-logs"
  }
}

# Create Storage Container (equivalent to S3 bucket)
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.logs.name
  container_access_type = "private"
}

# Create User Assigned Identity (equivalent to AWS IAM Role)
resource "azurerm_user_assigned_identity" "vm_identity" {
  name                = "id-vm-webserver-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Name = "tf-vm-identity"
  }
}

# Note: Role assignment removed due to insufficient permissions
# Manual step required: Assign "Storage Blob Data Contributor" role to the managed identity
# via Azure Portal or by a user with sufficient privileges

# Create network interface
resource "azurerm_network_interface" "web" {
  name                = "nic-webserver-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }

  tags = {
    Name = "tf-web-server-nic"
  }
}

# Associate Network Security Group to the network interface
resource "azurerm_network_interface_security_group_association" "web" {
  network_interface_id      = azurerm_network_interface.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "web" {
  name                = "vm-webserver-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.web.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(templatefile("${path.module}/user_data.sh", {
    storage_account_name = azurerm_storage_account.logs.name
    container_name       = azurerm_storage_container.logs.name
  }))

  tags = {
    Name = "tf-web-server"
  }
}