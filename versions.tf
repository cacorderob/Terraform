# ============================================================
# versions.tf
# Define las versiones mínimas requeridas de Terraform y
# de los proveedores para garantizar reproducibilidad.
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.95"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
