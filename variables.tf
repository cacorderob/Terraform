variable "location" {
  description = "Region de Azure donde se desplegara la VM"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-vm-windows-prod"
}

variable "vm_name" {
  description = "Nombre de la Virtual Machine"
  type        = string
  default     = "vm-windows-01"
}

variable "vm_size" {
  description = "Tamano de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Contrasena del administrador (minimo 12 caracteres, mayusculas, numeros y especiales)"
  type        = string
  sensitive   = true
}

# Cambia este valor por tu IP real en produccion para restringir acceso RDP
variable "rdp_source_ip" {
  description = "IP o rango permitido para RDP. Usa tu IP publica o rango corporativo."
  type        = string
  default     = "*"
}

variable "tags" {
  description = "Tags aplicados a todos los recursos"
  type        = map(string)
  default = {
    environment = "produccion"
    managed_by  = "terraform"
    project     = "vm-windows"
  }
}
