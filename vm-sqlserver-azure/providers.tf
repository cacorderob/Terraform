# =============================================================
# PROVIDERS.TF
# Configura el backend remoto en HCP Terraform (app.terraform.io)
# y el provider azurerm para interactuar con Azure.
#
# IMPORTANTE: Las credenciales de Azure (ARM_*) se configuran
# como variables de entorno en el workspace de HCP Terraform,
# NO se pasan directamente al provider aquí.
# =============================================================

terraform {
  # -------------------------------------------------------
  # BACKEND: HCP TERRAFORM (app.terraform.io)
  # El estado se almacena y los planes se ejecutan de forma
  # remota en HCP Terraform. NO se usa backend local.
  # -------------------------------------------------------
  cloud {
    organization = "GBM-HA-TEST"

    workspaces {
      name = "vm-sqlserver-azure"
    }
  }
}

# -------------------------------------------------------
# PROVIDER: AZURERM
# Las credenciales (client_id, client_secret, etc.) se
# inyectan automáticamente desde las variables de entorno
# ARM_* configuradas en el workspace de HCP Terraform.
# -------------------------------------------------------
provider "azurerm" {
  features {
    # No eliminar el RG si aún contiene recursos (protección anti-borrado accidental)
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    # Eliminar el disco OS cuando se destruye la VM para evitar costos residuales
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }

    # Configuración de Key Vault (habilitado para cifrado futuro)
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
