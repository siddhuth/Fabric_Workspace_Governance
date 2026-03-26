# Terraform Architecture

This document covers the provider configuration, module design patterns, state management, and the rationale behind the repository structure.

---

## Provider Overview

The [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest) (`microsoft/fabric`) is GA as of March 2025, currently at v1.3+. It is developed and maintained by Microsoft.

### Supported Resources (Governance-Relevant)

| Resource | Purpose |
|----------|---------|
| `fabric_workspace` | Create and manage workspaces with capacity assignment |
| `fabric_workspace_role_assignment` | Assign RBAC roles (Admin, Member, Contributor, Viewer) |
| `fabric_domain` | Create domains and subdomains |
| `fabric_domain_role_assignment` | Assign domain admin and contributor roles |
| `fabric_domain_workspace_assignment` | Associate a workspace with a domain |
| `fabric_workspace_git` | Connect workspace to Azure DevOps or GitHub |
| `fabric_spark_settings` | Configure Spark pools and runtime settings |
| `fabric_environment` | Provision isolated Spark environments |

### Additional Item Resources

`fabric_notebook`, `fabric_lakehouse`, `fabric_warehouse`, `fabric_data_pipeline`, `fabric_eventhouse`, `fabric_eventstream`, `fabric_kql_database`, `fabric_report`, `fabric_semantic_model`, `fabric_ml_experiment`, `fabric_ml_model`, `fabric_sql_database`

---

## Provider Configuration

```hcl
# providers.tf
terraform {
  required_version = ">= 1.8, < 2.0"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.0"
    }
  }
}

provider "fabric" {
  # Authentication is handled via:
  # 1. Azure CLI (az login) for local development
  # 2. Managed Identity for CI/CD pipelines
  # 3. Environment variables (ARM_CLIENT_ID, ARM_TENANT_ID, etc.)
}
```

### Authentication Methods

| Method | Use Case | Configuration |
|--------|----------|---------------|
| Azure CLI | Local development | `az login --scope api://{tenant_id}/fabric_terraform_provider/.default` |
| Managed Identity | CI/CD pipelines | Set `ARM_USE_MSI=true` and `ARM_CLIENT_ID` |
| Service Principal + OIDC | GitHub Actions | Configure federated credentials on the identity |
| Client Secret | Legacy (not recommended) | Set `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` |

---

## Module Design

### Principle: Module-per-Concern

Each module encapsulates a single governance concept and handles all related resources internally:

```
modules/
├── domain/        # Domain + subdomains + role assignments
├── workspace/     # Workspace + RBAC + domain assignment + Git
└── capacity/      # Capacity data source lookup
```

### Module Contract

Every module follows the same interface pattern:

```hcl
# variables.tf — inputs with validation
# main.tf     — resource definitions
# outputs.tf  — values consumed by other modules
```

Modules never create provider blocks or backend configurations. Those belong exclusively in the environment root.

---

## State Management

### Environment-per-Directory

Each DTAP stage has its own Terraform root and its own state file:

```
environments/
├── dev/      ──► state: fabric-state-dev
├── test/     ──► state: fabric-state-test
└── prod/     ──► state: fabric-state-prod
```

**Why separate state files?**
- A failed `terraform apply` in dev cannot corrupt prod state
- Different teams can have different permissions per environment
- State locking is independent — dev deployments don't block prod
- Drift detection can be run per environment on different schedules

### Remote Backend (Recommended)

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stfabricstate"
    container_name       = "tfstate"
    key                  = "fabric-dev.tfstate"  # varies per environment
    use_azuread_auth     = true
  }
}
```

Use Azure Storage with RBAC authentication (not shared keys) for the remote backend. Enable blob versioning for state history.

---

## Variable Layering

Variables flow from general to specific:

```
modules/workspace/variables.tf     ← Module-level defaults and validation
environments/dev/variables.tf      ← Environment-level variable declarations
environments/dev/terraform.tfvars  ← Environment-specific values
```

### Example Flow

```hcl
# modules/workspace/variables.tf
variable "display_name" {
  type = string
  validation {
    condition     = can(regex("^[A-Z]+-[A-Za-z0-9]+-(?:Bronze|Silver|Gold|Reporting|Sandbox)-(?:Dev|Test|UAT|Prod)$", var.display_name))
    error_message = "Must match {Domain}-{Project}-{Layer}-{Env} pattern."
  }
}

# environments/dev/main.tf
module "fin_reporting" {
  source       = "../../modules/workspace"
  display_name = "FIN-QuarterlyFinancials-Gold-Dev"  # passes validation
  capacity_id  = module.capacity.id
  domain_id    = module.finance_domain.id
  # ...
}
```

---

## Importing Existing Resources

For organizations with existing Fabric resources that need to be brought under Terraform management:

```bash
# Import an existing workspace
terraform import 'module.fin_reporting.fabric_workspace.this' '{workspace-guid}'

# Import an existing domain
terraform import 'module.finance_domain.fabric_domain.this' '{domain-guid}'
```

After import, run `terraform plan` to identify any drift between the actual state and the desired configuration.

---

## Handling Drift

Terraform detects drift on every `plan`:

```bash
# Check for drift without applying
terraform plan -detailed-exitcode

# Exit codes:
# 0 = no changes
# 1 = error
# 2 = changes detected (drift or pending changes)
```

Schedule periodic drift detection in CI/CD (e.g., nightly `terraform plan` with Slack notification on exit code 2).

---

## Next: [Workload Identity →](06-workload-identity.md)
