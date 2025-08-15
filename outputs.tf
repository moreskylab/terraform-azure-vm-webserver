output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = azurerm_public_ip.web.ip_address
}

output "web_server_pip_id" {
  description = "ID of the Public IP"
  value       = azurerm_public_ip.web.id
}

output "logs_storage_account" {
  description = "Name of the storage account for logs"
  value       = azurerm_storage_account.logs.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "ssh_connection_command" {
  description = "SSH command to connect to the web server"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web.ip_address}"
}

output "web_server_url" {
  description = "URL of the web server"
  value       = "http://${azurerm_public_ip.web.ip_address}"
}