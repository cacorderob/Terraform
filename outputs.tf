# =============================================================
# OUTPUTS.TF
# Valores que Terraform muestra al terminar el apply.
# Útil para saber la IP de la VM, el nombre del storage, etc.
# =============================================================

# -------------------------------------------------------
# AZURE OUTPUTS
# -------------------------------------------------------

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Nombre de la VM Windows"
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_public_ip" {
  description = "IP pública para conectarte a la VM por RDP"
  value       = azurerm_public_ip.vm.ip_address
}

output "rdp_connection" {
  description = "Datos para conectarte por RDP"
  value       = "Abrí Remote Desktop y conectate a: ${azurerm_public_ip.vm.ip_address}"
}

output "sql_server_name" {
  description = "Nombre del servidor SQL"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_host" {
  description = "Host para conectarte al SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Nombre de la base de datos"
  value       = azurerm_mssql_database.main.name
}

output "sql_admin_user" {
  description = "Usuario administrador del SQL Server"
  value       = var.sql_admin_user
}
