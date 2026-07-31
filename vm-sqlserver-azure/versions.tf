# =============================================================
# VERSIONS.TF
# Define la versión mínima de Terraform y los providers
# requeridos con versiones fijas para garantizar reproducibilidad.
# =============================================================

terraform {
  # Versión mínima de Terraform CLI requerida
  required_version = ">= 1.7.0"

  # Providers requeridos con versiones fijas (pin de versión mayor)
  # Fijar la versión evita actualizaciones automáticas que puedan
  # introducir breaking changes en el código.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
