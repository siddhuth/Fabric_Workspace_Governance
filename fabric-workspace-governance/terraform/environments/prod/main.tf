# environments/prod/main.tf
# Production environment — consumer-facing content with strict RBAC and full audit.

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
# Domains are tenant-scoped, so they are defined once (typically in dev or a shared root).
# In prod, reference the existing domain IDs via data sources or shared outputs.
# For simplicity, this example defines them here — in practice, use remote state references.

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

  contributor_principals = [
    {
      principal_id   = var.finance_contributor_group_id
      principal_type = "Group"
      role           = "Contributors"
    },
  ]
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

# --- Production Workspaces ---

module "fin_reporting_prod" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Gold-Prod"
  description  = "Finance quarterly financials - gold layer - production"
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id

  role_assignments = [
    {
      principal_id   = var.platform_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.finance_admin_group_id
      principal_type = "Group"
      role           = "Member"
    },
    {
      principal_id   = var.finance_viewer_group_id
      principal_type = "Group"
      role           = "Viewer"
    },
  ]

  git_config = {
    provider_type = "AzureDevOps"
    organization  = var.ado_organization
    project       = var.ado_project
    repository    = "FIN-QuarterlyFinancials-Gold"
    branch        = "main"
  }
}

module "fin_bronze_prod" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Bronze-Prod"
  description  = "Finance quarterly financials - bronze layer - production"
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id

  role_assignments = [
    {
      principal_id   = var.platform_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.data_engineering_group_id
      principal_type = "Group"
      role           = "Member"
    },
  ]
}

module "mkt_campaign_prod" {
  source       = "../../modules/workspace"
  display_name = "MKT-CampaignAnalytics-Gold-Prod"
  description  = "Marketing campaign analytics - gold layer - production"
  capacity_id  = module.capacity.id
  domain_id    = module.marketing_domain.id

  role_assignments = [
    {
      principal_id   = var.platform_admin_group_id
      principal_type = "Group"
      role           = "Admin"
    },
    {
      principal_id   = var.marketing_admin_group_id
      principal_type = "Group"
      role           = "Member"
    },
    {
      principal_id   = var.marketing_viewer_group_id
      principal_type = "Group"
      role           = "Viewer"
    },
  ]
}
