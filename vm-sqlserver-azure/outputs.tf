# =============================================================
# OUTPUTS.TF
# Valores exportados al finalizar el apply de Terraform.
# Son útiles para:
#   - Consumo por otros módulos/workspaces (remote state)
#   - Visualización en HCP Terraform UI
#   - Integración con pipelines CI/CD
# =============================================================

# -------------------------------------------------------
# GRUPO DE RECURSOS
# -------------------------------------------------------

output "resource_group_id" {
  description = "ID único del grupo de recursos de Azure creado."
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Nombre del grupo de recursos de Azure."
  value       = azurerm_resource_group.main.name
}

# -------------------------------------------------------
# MÁQUINA VIRTUAL
# -------------------------------------------------------

output "vm_id" {
  description = "ID del recurso de la máquina virtual Windows."
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_name" {
  description = "Nombre de la máquina virtual Windows."
  value       = azurerm_windows_virtual_machine.main.name
}

output "vm_public_ip" {
  description = "Dirección IP pública de la VM. Usar esta IP para conectarse por RDP (puerto 3389)."
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_private_ip" {
  description = "Dirección IP privada de la VM dentro de la VNet."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_rdp_connection" {
  description = "Cadena de conexión RDP para acceso remoto a la VM."
  value       = "Conectar por Remote Desktop a: ${azurerm_public_ip.vm.ip_address}:3389"
}

# -------------------------------------------------------
# AZURE SQL SERVER
# -------------------------------------------------------

output "sql_server_id" {
  description = "ID del recurso del Azure SQL Server."
  value       = azurerm_mssql_server.main.id
}

output "sql_server_name" {
  description = "Nombre del Azure SQL Server."
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "FQDN (Fully Qualified Domain Name) del Azure SQL Server. Usar para cadenas de conexión."
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Nombre de la base de datos Azure SQL creada."
  value       = azurerm_mssql_database.main.name
}

output "sql_database_id" {
  description = "ID del recurso de la base de datos Azure SQL."
  value       = azurerm_mssql_database.main.id
}

output "sql_connection_string" {
  description = "Cadena de conexión ADO.NET para la base de datos (sin contraseña por seguridad)."
  sensitive   = true
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin_login};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# -------------------------------------------------------
# RED
# -------------------------------------------------------

output "vnet_id" {
  description = "ID de la red virtual."
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID de la subred de la VM."
  value       = azurerm_subnet.vm.id
}
