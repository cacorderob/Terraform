output "vm_name" {
  description = "Nombre de la VM creada"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "public_ip_address" {
  description = "IP pública para conectarse por RDP"
  value       = azurerm_public_ip.pip.ip_address
}

output "private_ip_address" {
  description = "IP privada de la VM"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "rdp_connection" {
  description = "Comando para conectarse por RDP"
  value       = "mstsc /v:${azurerm_public_ip.pip.ip_address}"
}

output "admin_username" {
  description = "Usuario administrador"
  value       = azurerm_windows_virtual_machine.vm.admin_username
}

output "resource_group_name" {
  description = "Resource Group donde se desplegó la VM"
  value       = azurerm_resource_group.rg.name
}
