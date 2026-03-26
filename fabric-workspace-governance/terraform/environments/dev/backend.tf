# environments/dev/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-fabric-terraform"
    storage_account_name = "stfabrictfstate"       # Replace with your storage account
    container_name       = "tfstate"
    key                  = "fabric-dev.tfstate"
    use_azuread_auth     = true
  }
}
