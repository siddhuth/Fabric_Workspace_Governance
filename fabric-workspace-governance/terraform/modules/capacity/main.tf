# modules/capacity/main.tf
# Data source to look up an existing Fabric capacity by display name.
# Capacities are Azure resources provisioned via azapi/azurerm — this module
# only reads them for reference by workspace and environment configs.

data "fabric_capacity" "this" {
  display_name = var.capacity_name
}
