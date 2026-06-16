# BACKEND REMOTO EN AZURE STORAGE
# Storage Account: demoaprovisionarpipeline
# Resource Group:  hyperautomation-team_group
# Subscription:    03305b29-4a2a-41ca-a6ca-60f845dca450
#
# Verifica que el contenedor 'tfstate' exista en el Storage Account:
#   az storage container create --name tfstate --account-name demoaprovisionarpipeline

terraform {
  backend "azurerm" {
    resource_group_name  = "hyperautomation-team_group"
    storage_account_name = "demoaprovisionarpipeline"
    container_name       = "tfstate"
    key                  = "vm-windows-prod.terraform.tfstate"
  }
}
