# =============================================================
# VARIABLES.TF
# Declaración de todas las variables del proyecto.
#
# REGLAS:
#   - Variables sensibles (contraseñas, tokens): sensitive = true
#   - Sin valores hardcodeados de credenciales en este archivo
#   - Cada variable incluye validación con condition + error_message
#   - Los valores reales van en terraform.tfvars (excluido de git)
#     o como Variables en HCP Terraform
# =============================================================

# -------------------------------------------------------
# IDENTIFICACIÓN DEL ENTORNO
# -------------------------------------------------------

variable "resource_group_name" {
  description = "Nombre del grupo de recursos de Azure donde se crearán todos los recursos."
  type        = string
  default     = "rg-vm-sqlserver-prod"

  validation {
    condition     = can(regex("^rg-[a-z0-9-]{3,50}$", var.resource_group_name))
    error_message = "El nombre del resource group debe comenzar con 'rg-' y contener solo letras minúsculas, números y guiones (3-50 caracteres)."
  }
}

variable "location" {
  description = "Región de Azure donde se desplegará la infraestructura. Por defecto: Central US."
  type        = string
  default     = "centralus"

  validation {
    condition     = contains(["centralus", "eastus", "eastus2", "westus", "westus2", "westus3", "northcentralus", "southcentralus"], var.location)
    error_message = "La región debe ser una región válida de Azure en Estados Unidos. Valores permitidos: centralus, eastus, eastus2, westus, westus2, westus3, northcentralus, southcentralus."
  }
}

variable "environment" {
  description = "Entorno de despliegue (production, staging, development). Usado en tags y nombres de recursos."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development", "testing"], var.environment)
    error_message = "El entorno debe ser uno de: production, staging, development, testing."
  }
}

variable "project_name" {
  description = "Nombre del proyecto. Usado en tags y como prefijo en nombres de recursos."
  type        = string
  default     = "carlos-pruebas"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.project_name))
    error_message = "El nombre del proyecto debe contener solo letras minúsculas, números y guiones (3-30 caracteres)."
  }
}

variable "owner" {
  description = "Propietario o responsable de los recursos. Usado en el tag 'Owner'."
  type        = string
  default     = "cacordero"

  validation {
    condition     = length(var.owner) >= 3 && length(var.owner) <= 50
    error_message = "El campo owner debe tener entre 3 y 50 caracteres."
  }
}

# -------------------------------------------------------
# RED VIRTUAL
# -------------------------------------------------------

variable "vnet_address_space" {
  description = "Espacio de direcciones CIDR para la red virtual."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "El valor de vnet_address_space debe ser un bloque CIDR válido (ej: 10.10.0.0/16)."
  }
}

variable "subnet_address_prefix" {
  description = "Prefijo de dirección CIDR para la subred de la VM."
  type        = string
  default     = "10.10.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_address_prefix, 0))
    error_message = "El valor de subnet_address_prefix debe ser un bloque CIDR válido (ej: 10.10.1.0/24)."
  }
}

# -------------------------------------------------------
# MÁQUINA VIRTUAL WINDOWS
# -------------------------------------------------------

variable "vm_size" {
  description = "Tamaño (SKU) de la máquina virtual Azure. Por defecto: Standard_B2s_v2 (Standard_B2ats_v2 no tiene capacidad disponible en centralus)."
  type        = string
  default     = "Standard_B2s_v2"

  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "El tamaño de VM debe ser un SKU válido de Azure que comience con 'Standard_' (ej: Standard_B2s_v2, Standard_D2s_v3)."
  }
}

variable "admin_username" {
  description = "Nombre del usuario administrador local de la VM Windows. NO usar 'admin', 'administrator' u otros nombres reservados."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_username) >= 4 && length(var.admin_username) <= 20 && !contains(["admin", "administrator", "user", "guest", "root"], lower(var.admin_username))
    error_message = "El username debe tener entre 4 y 20 caracteres y no puede ser un nombre reservado (admin, administrator, user, guest, root)."
  }
}

variable "admin_password" {
  description = "Contraseña del administrador de la VM Windows. Debe cumplir con los requisitos de complejidad de Azure (mín. 12 caracteres, mayúsculas, minúsculas, números y caracteres especiales)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12 && can(regex("[A-Z]", var.admin_password)) && can(regex("[a-z]", var.admin_password)) && can(regex("[0-9]", var.admin_password)) && can(regex("[^a-zA-Z0-9]", var.admin_password))
    error_message = "La contraseña debe tener al menos 12 caracteres e incluir: mayúsculas, minúsculas, números y caracteres especiales."
  }
}

variable "os_disk_size_gb" {
  description = "Tamaño del disco del sistema operativo en GB."
  type        = number
  default     = 128

  validation {
    condition     = var.os_disk_size_gb >= 128 && var.os_disk_size_gb <= 1024
    error_message = "El tamaño del disco OS debe estar entre 128 GB y 1024 GB."
  }
}

# -------------------------------------------------------
# AZURE SQL SERVER
# -------------------------------------------------------

variable "sql_admin_login" {
  description = "Nombre del usuario administrador del Azure SQL Server. NO usar 'sa', 'admin', 'root' u otros nombres reservados."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_login) >= 4 && length(var.sql_admin_login) <= 30 && !contains(["sa", "admin", "administrator", "root", "guest"], lower(var.sql_admin_login))
    error_message = "El login de SQL debe tener entre 4 y 30 caracteres y no puede ser un nombre reservado (sa, admin, administrator, root, guest)."
  }
}

variable "sql_admin_password" {
  description = "Contraseña del administrador del Azure SQL Server. Debe cumplir con la política de contraseñas de Azure SQL (mín. 8 caracteres con complejidad)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_password) >= 12 && can(regex("[A-Z]", var.sql_admin_password)) && can(regex("[a-z]", var.sql_admin_password)) && can(regex("[0-9]", var.sql_admin_password)) && can(regex("[^a-zA-Z0-9]", var.sql_admin_password))
    error_message = "La contraseña del SQL Server debe tener al menos 12 caracteres e incluir: mayúsculas, minúsculas, números y caracteres especiales."
  }
}

variable "sql_database_sku" {
  description = "SKU de la base de datos Azure SQL. GP_S_Gen5_1 es Serverless Gen5 (recomendado para workloads intermitentes)."
  type        = string
  default     = "GP_S_Gen5_1"

  validation {
    condition     = can(regex("^(Basic|S[0-9]|P[0-9]|GP_S_Gen5_[0-9]+|GP_Gen5_[0-9]+|BC_Gen5_[0-9]+|HS_Gen5_[0-9]+)$", var.sql_database_sku))
    error_message = "El SKU de SQL Database debe ser un valor válido (ej: Basic, S1, GP_S_Gen5_1, GP_Gen5_2)."
  }
}

variable "sql_max_size_gb" {
  description = "Tamaño máximo de la base de datos en GB."
  type        = number
  default     = 32

  validation {
    condition     = var.sql_max_size_gb >= 1 && var.sql_max_size_gb <= 4096
    error_message = "El tamaño máximo de la base de datos debe estar entre 1 GB y 4096 GB."
  }
}
