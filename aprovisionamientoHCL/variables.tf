# ============================================================
# variables.tf
# Declaración de todas las variables de entrada con
# validaciones, descripciones y marcadores de sensibilidad.
# Ninguna variable contiene valores por defecto para
# credenciales o datos sensibles.
# ============================================================

# ─── Generales ───────────────────────────────────────────────

variable "resource_group_name" {
  description = "Nombre del grupo de recursos de Azure donde se desplegarán todos los recursos."
  type        = string

  validation {
    condition     = length(var.resource_group_name) >= 3 && length(var.resource_group_name) <= 90
    error_message = "El nombre del grupo de recursos debe tener entre 3 y 90 caracteres."
  }
}

variable "location" {
  description = "Región de Azure donde se crearán los recursos. Por defecto: Central US."
  type        = string
  default     = "centralus"

  validation {
    condition     = contains(["centralus", "eastus", "eastus2", "westus", "westus2", "westus3", "northcentralus", "southcentralus"], var.location)
    error_message = "La ubicación debe ser una región válida de Azure en Estados Unidos."
  }
}

variable "environment" {
  description = "Nombre del entorno (production, staging, development)."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "El entorno debe ser uno de: production, staging, development."
  }
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetado de recursos."
  type        = string
  default     = "carlos-pruebas"

  validation {
    condition     = length(var.project_name) >= 2 && length(var.project_name) <= 50
    error_message = "El nombre del proyecto debe tener entre 2 y 50 caracteres."
  }
}

variable "owner" {
  description = "Nombre o correo del responsable de los recursos (usado en etiquetas)."
  type        = string
  default     = "cacorderob"
}

# ─── Red virtual ────────────────────────────────────────────

variable "vnet_address_space" {
  description = "Espacio de direcciones CIDR para la red virtual."
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "Debe especificar al menos un bloque CIDR para la red virtual."
  }
}

variable "subnet_address_prefix" {
  description = "Prefijo CIDR de la subred donde residirá la máquina virtual."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.subnet_address_prefix))
    error_message = "El prefijo de subred debe ser un CIDR válido (ej. 10.0.1.0/24)."
  }
}

# ─── Máquina Virtual ────────────────────────────────────────

variable "vm_size" {
  description = "Tamaño de la máquina virtual de Azure (SKU)."
  type        = string
  default     = "Standard_B2ms"

  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "El tamaño de la VM debe comenzar con 'Standard_'."
  }
}

variable "admin_username" {
  description = "Nombre de usuario administrador de la máquina virtual Windows. SENSIBLE: no registrar en logs."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_username) >= 4 && length(var.admin_username) <= 20
    error_message = "El nombre de usuario administrador debe tener entre 4 y 20 caracteres."
  }
}

variable "admin_password" {
  description = "Contraseña del administrador de la VM Windows. Mínimo 12 caracteres, debe incluir mayúsculas, minúsculas, números y caracteres especiales."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "La contraseña del administrador debe tener al menos 12 caracteres."
  }
}

variable "os_disk_type" {
  description = "Tipo de disco OS para la VM (Premium_LRS, StandardSSD_LRS, Standard_LRS)."
  type        = string
  default     = "StandardSSD_LRS"

  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS", "UltraSSD_LRS"], var.os_disk_type)
    error_message = "El tipo de disco debe ser Premium_LRS, StandardSSD_LRS, Standard_LRS o UltraSSD_LRS."
  }
}

# ─── Azure SQL Server ────────────────────────────────────────

variable "sql_admin_login" {
  description = "Login del administrador de Azure SQL Server. SENSIBLE: no registrar en logs."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_login) >= 4 && !can(regex("^(admin|administrator|sa|root|guest|public)$", lower(var.sql_admin_login)))
    error_message = "El login SQL debe tener al menos 4 caracteres y no puede ser un nombre reservado (admin, sa, root, etc.)."
  }
}

variable "sql_admin_password" {
  description = "Contraseña del administrador de Azure SQL Server. Mínimo 16 caracteres."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_password) >= 16
    error_message = "La contraseña SQL debe tener al menos 16 caracteres."
  }
}

variable "sql_database_sku" {
  description = "SKU de la Azure SQL Database (ej. GP_S_Gen5_1 para serverless, Basic, S0, S1)."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "sql_server_version" {
  description = "Versión del motor de Azure SQL Server."
  type        = string
  default     = "12.0"

  validation {
    condition     = contains(["12.0"], var.sql_server_version)
    error_message = "La versión del SQL Server debe ser 12.0."
  }
}
