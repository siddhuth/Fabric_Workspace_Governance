# environments/test/main.tf
# Test/UAT environment — integration testing and business validation.

terraform {
  required_version = ">= 1.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.0"
    }
  }
}

provider "fabric" {}

# --- Capacity ---

module "capacity" {
  source        = "../../modules/capacity"
  capacity_name = var.capacity_name
}

# --- Domains (tenant-scoped, shared with dev/prod) ---

module "finance_domain" {
  source      = "../../modules/domain"
  name        = "Finance"
  description = "Finance department data assets"
  subdomains  = ["Accounting", "FP&A"]

  admin_principals = [
    {
      principal_id   = var.finance_admin_group_id
      principal_type = "Group"
      role           = "Admins"
    },
  ]

  contributor_principals = []
}

# --- Test Workspaces ---

module "fin_reporting_test" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Gold-Test"
  description  = "Finance quarterly financials - gold layer - test"
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id

  role_assignments = [
    {
      principal_id   = var.finance_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.qa_group_id
      principal_type = "Group"
      role           = "Contributor"
    },
  ]
}

module "fin_bronze_test" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Bronze-Test"
  description  = "Finance quarterly financials - bronze layer - test"
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id

  role_assignments = [
    {
      principal_id   = var.finance_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.data_engineering_group_id
      principal_type = "Group"
      role           = "Contributor"
    },
  ]
}
