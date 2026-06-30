# =============================================================
# VARIABLES.TF
# Todas las variables del proyecto en un solo lugar.
# Nunca pongas valores sensibles aquí (contraseñas, tokens).
# Esos van en terraform.tfvars o como variables de entorno.
# IMPORTANTE: terraform.tfvars está en .gitignore y NO se
# sube a GitHub. Las variables sensibles se configuran
# directamente en Terraform Cloud (Variable Sets).
# =============================================================

# -------------------------------------------------------
# CREDENCIALES AZURE - SERVICE PRINCIPAL
# Valores configurados en Terraform Cloud → Variable Sets
# -------------------------------------------------------

variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "ID del tenant de Azure"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "ID del Service Principal"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Contraseña del Service Principal"
  type        = string
  sensitive   = true
}

# -------------------------------------------------------
# IDENTIFICACIÓN DEL WORKSHOP
# -------------------------------------------------------

variable "cliente" {
  description = "Nombre del cliente o proyecto"
  type        = string
  default     = "democolono"
}

variable "colaborador" {
  description = "Tu nombre, sin espacios ni tildes. Configurar en Terraform Cloud."
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "Central US"
}

variable "tags" {
  description = "Etiquetas para los recursos"
  type        = map(string)
  default     = {}
}

# -------------------------------------------------------
# WINDOWS VM
# -------------------------------------------------------

variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Usuario administrador de Windows"
  type        = string
  default     = "adminworkshop"
}

variable "vm_admin_password" {
  description = "Contraseña del administrador de Windows. Configurar en Terraform Cloud."
  type        = string
  sensitive   = true
}

# -------------------------------------------------------
# SQL SERVER
# -------------------------------------------------------

variable "sql_admin_user" {
  description = "Usuario administrador del SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Contraseña del administrador del SQL Server. Configurar en Terraform Cloud."
  type        = string
  sensitive   = true
}
