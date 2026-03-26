# policies/naming_validation.tf
#
# Centralized naming convention validation logic.
# These locals can be used by any module or environment config
# to validate workspace names, item names, and domain prefixes.

locals {
  # Approved domain abbreviations — extend as your org grows
  valid_domain_prefixes = [
    "FIN",       # Finance
    "MKT",       # Marketing
    "HR",        # Human Resources
    "ENG",       # Engineering
    "SALES",     # Sales
    "OPS",       # Operations
    "EXEC",      # Executive
    "DATA",      # Data Platform / shared infrastructure
    "ANALYTICS", # Cross-functional analytics
  ]

  # Approved medallion layers
  valid_layers = [
    "Bronze",
    "Silver",
    "Gold",
    "Reporting",
    "Sandbox",
  ]

  # Approved DTAP environments
  valid_environments = [
    "Dev",
    "Test",
    "UAT",
    "Prod",
  ]

  # Regex pattern for workspace naming validation
  # Pattern: {DOMAIN}-{Project}-{Layer}-{Env}
  workspace_name_pattern = "^(${join("|", local.valid_domain_prefixes)})-[A-Z][A-Za-z0-9]+-(?:${join("|", local.valid_layers)})-(?:${join("|", local.valid_environments)})$"

  # Item naming prefixes (for documentation / external tooling)
  item_type_prefixes = {
    lakehouse      = "lh_"
    warehouse      = "wh_"
    notebook       = "nb_"
    pipeline       = "pl_"
    dataflow       = "df_"
    semantic_model = "sm_"
    report         = "rpt_"
    eventstream    = "es_"
    kql_database   = "kql_"
    eventhouse     = "eh_"
    environment    = "env_"
    sql_database   = "sqldb_"
  }

  # Domain prefix to full domain name mapping
  domain_prefix_map = {
    "FIN"       = "Finance"
    "MKT"       = "Marketing"
    "HR"        = "Human Resources"
    "ENG"       = "Engineering"
    "SALES"     = "Sales"
    "OPS"       = "Operations"
    "EXEC"      = "Executive"
    "DATA"      = "Data Platform"
    "ANALYTICS" = "Analytics"
  }
}

# --- Helper: Extract domain prefix from workspace name ---

# Usage: local.extract_domain_prefix("FIN-QuarterlyFinancials-Gold-Prod") => "FIN"
# This can be used to auto-assign workspaces to domains based on naming convention.

locals {
  # Example function (Terraform doesn't support true functions, but this pattern
  # can be used in for_each or local values):
  #
  # workspace_domain_prefix = regex("^([A-Z]+)-", var.workspace_name)[0]
  # workspace_domain_name   = local.domain_prefix_map[local.workspace_domain_prefix]
}
