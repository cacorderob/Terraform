# =============================================================
# PROVIDERS.TF
# Aquí le decimos a Terraform CON QUÉ herramientas trabajar.
# Provider = plugin que sabe hablar con Azure.
# Backend configurado para Terraform Cloud (HCP Terraform).
# =============================================================

terraform {
  required_version = ">= 1.5.0"

  # -------------------------------------------------------
  # BACKEND: TERRAFORM CLOUD
  # Reemplaza "NOMBRE_DEL_WORKSPACE" con el nombre exacto
  # del workspace que creaste en app.terraform.io
  # -------------------------------------------------------
  cloud {
    organization = "GBM-HA-TEST"

    workspaces {
      name = "NOMBRE_DEL_WORKSPACE"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}
