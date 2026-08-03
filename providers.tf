# ============================================================
# providers.tf
# Configura el proveedor AzureRM y el backend remoto en
# HCP Terraform (HashiCorp Cloud Platform).
# Las credenciales ARM se inyectan vía variables de entorno
# (ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID,
#  ARM_TENANT_ID) gestionadas en el workspace de HCP Terraform.
# ============================================================

# Backend remoto: almacena el estado de Terraform en HCP Terraform
# para colaboración segura y auditoría de cambios.
terraform {
  cloud {
    organization = "cacorderob"

    workspaces {
      name = "vm-sqlserver-azure"
    }
  }
}

# Configuración del proveedor de Azure Resource Manager.
# Las credenciales se resuelven automáticamente desde las
# variables de entorno ARM_* definidas en HCP Terraform.
provider "azurerm" {
  features {
    # Limpieza completa del Key Vault al destruir (si se usa en el futuro)
    key_vault {
      purge_soft_delete_on_destroy = true
    }

    # Eliminación forzada del grupo de recursos con todos sus recursos
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
