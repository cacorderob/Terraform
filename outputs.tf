# ============================================================
# outputs.tf
# Exporta los atributos más importantes de los recursos
# creados para facilitar la integración con otros sistemas,
# pipelines o referencias entre módulos.
# ============================================================

# ─── Grupo de recursos ──────────────────────────────────────

output "resource_group_id" {
  description = "ID único del grupo de recursos de Azure."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Nombre del grupo de recursos de Azure."
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Región de Azure donde se desplegaron los recursos."
  value       = azurerm_resource_group.main.location
}

# ─── Máquina Virtual ────────────────────────────────────────

output "vm_public_ip_address" {
  description = "Dirección IP pública de la máquina virtual Windows."
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_private_ip_address" {
  description = "Dirección IP privada de la máquina virtual dentro de la VNet."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_id" {
  description = "ID del recurso de la máquina virtual de Azure."
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Nombre de la máquina virtual."
  value       = azurerm_windows_virtual_machine.main.name
}

# ─── Azure SQL Server ────────────────────────────────────────

output "sql_server_fqdn" {
  description = "Nombre de dominio completo (FQDN) del Azure SQL Server para conexiones."
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_server_name" {
  description = "Nombre del recurso Azure SQL Server."
  value       = azurerm_mssql_server.main.name
}

output "sql_database_name" {
  description = "Nombre de la Azure SQL Database creada."
  value       = azurerm_mssql_database.main.name
}

output "sql_database_id" {
  description = "ID del recurso de la Azure SQL Database."
  value       = azurerm_mssql_database.main.id
}

# ─── Red ────────────────────────────────────────────────────

output "virtual_network_id" {
  description = "ID de la red virtual."
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID de la subred donde reside la VM."
  value       = azurerm_subnet.vm.id
}

output "nsg_id" {
  description = "ID del Network Security Group asociado a la subred."
  value       = azurerm_network_security_group.vm.id
}
