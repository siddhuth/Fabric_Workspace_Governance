# environments/prod/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-fabric-terraform"
    storage_account_name = "stfabrictfstate"
    container_name       = "tfstate"
    key                  = "fabric-prod.tfstate"
    use_azuread_auth     = true
  }
}
