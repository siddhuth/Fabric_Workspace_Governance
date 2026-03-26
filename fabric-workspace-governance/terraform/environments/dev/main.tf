# environments/dev/main.tf
# Development environment — isolated sandboxes with Git-connected feature branches.

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

# --- Domains ---

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

module "marketing_domain" {
  source      = "../../modules/domain"
  name        = "Marketing"
  description = "Marketing analytics and campaign data"
  subdomains  = ["Campaign Analytics", "Digital"]

  admin_principals = [
    {
      principal_id   = var.marketing_admin_group_id
      principal_type = "Group"
      role           = "Admins"
    },
  ]

  contributor_principals = []
}

# --- Workspaces ---

module "fin_reporting_dev" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Gold-Dev"
  description  = "Finance quarterly financials - gold layer - development"
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id

  role_assignments = [
    {
      principal_id   = var.finance_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.finance_dev_group_id
      principal_type = "Group"
      role           = "Contributor"
    },
  ]

  git_config = {
    provider_type = "AzureDevOps"
    organization  = var.ado_organization
    project       = var.ado_project
    repository    = "FIN-QuarterlyFinancials-Gold"
    branch        = "develop"
  }
}

module "fin_bronze_dev" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Bronze-Dev"
  description  = "Finance quarterly financials - bronze layer - development"
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

module "mkt_campaign_dev" {
  source       = "../../modules/workspace"
  display_name = "MKT-CampaignAnalytics-Gold-Dev"
  description  = "Marketing campaign analytics - gold layer - development"
  capacity_id  = module.capacity.id
  domain_id    = module.marketing_domain.id

  role_assignments = [
    {
      principal_id   = var.marketing_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
  ]
}
