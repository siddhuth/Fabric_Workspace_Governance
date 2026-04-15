# Microsoft Fabric — Workspace Governance & Platform Automation

A reference architecture and Terraform codebase for managing Microsoft Fabric workspace proliferation through automated domain hierarchies, enforced naming conventions, RBAC assignment, and CI/CD-driven infrastructure as code.

---

## Problem Statement

As organizations scale their Microsoft Fabric adoption, workspace sprawl becomes a governance challenge. Without deliberate controls:

- Workspaces are created ad-hoc with inconsistent naming, making OneLake Catalog discovery unreliable
- Domain and subdomain structures go unimplemented, leaving federated governance capabilities unused
- RBAC assignments are manual and drift from policy over time
- No audit trail exists for who provisioned what, when, or why
- DTAP (Dev/Test/Acceptance/Production) lifecycle isolation is inconsistent across teams

This repository provides a **production-ready framework** to solve these problems using the [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest) (GA, v1.3+).

---

## Repository Structure

```
fabric-workspace-governance/
├── README.md                          # This file
├── docs/
│   ├── 01-governance-hierarchy.md     # Tenant → Capacity → Domain → Workspace model
│   ├── 02-domain-strategy.md          # Source-aligned vs. consumer-aligned domains
│   ├── 03-naming-conventions.md       # Workspace & item naming standard
│   ├── 04-dtap-lifecycle.md           # Dev/Test/UAT/Prod workspace patterns
│   ├── 05-terraform-architecture.md   # Module design and provider setup
│   ├── 06-workload-identity.md        # Managed identity & auth configuration
│   └── 07-cicd-pipeline.md            # GitHub Actions / Azure DevOps automation
├── terraform/
│   ├── modules/
│   │   ├── domain/                    # Reusable domain + subdomain module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── workspace/                 # Workspace + RBAC + domain assignment module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── capacity/                  # Capacity data source helper
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── environments/
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   ├── test/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars
│   │   │   └── backend.tf
│   │   └── prod/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── backend.tf
│   └── policies/
│       └── naming_validation.tf       # Terraform validation rules for naming
├── diagrams/                          # Mermaid source files for architecture visuals
│   ├── governance-hierarchy.mermaid
│   ├── terraform-flow.mermaid
│   └── cicd-pipeline.mermaid
└── .github/
    └── workflows/
        └── terraform.yml              # GitHub Actions CI/CD pipeline
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FABRIC TENANT                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    ADMIN PORTAL                                │  │
│  │  Tenant Settings  ·  Capacity Settings  ·  Domain Delegation  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Capacity:Dev │  │ Capacity:Test│  │ Capacity:Prod│              │
│  │    (F2)      │  │    (F4)      │  │    (F64)     │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                       │
│  ┌──────┴─────────────────┴─────────────────┴───────────────────┐  │
│  │                      DOMAINS                                  │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │  │
│  │  │  Finance    │  │  Marketing  │  │  Engineering │          │  │
│  │  │  ┌────────┐ │  │  ┌────────┐ │  │  ┌────────┐ │          │  │
│  │  │  │Acctg   │ │  │  │CampaignAnalytics│  │DataPlatform│          │  │
│  │  │  │FP&A    │ │  │  │Digital │ │  │  │  MLOps │ │          │  │
│  │  │  └────────┘ │  │  └────────┘ │  │  └────────┘ │          │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘          │  │
│  │                                                               │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │              WORKSPACES (per DTAP stage)               │  │  │
│  │  │  FIN-Reporting-Gold-Dev    FIN-Reporting-Gold-Prod     │  │  │
│  │  │  MKT-Campaign-Silver-Dev  MKT-Campaign-Silver-Prod    │  │  │
│  │  │  ENG-DataPlatform-Bronze-Dev  ENG-DataPlatform-Bronze-Prod │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.8, < 2.0
- Azure CLI (`az`) for authentication
- A Microsoft Fabric Capacity (F-SKU or Trial) provisioned in Azure
- A User-Assigned Managed Identity or Service Principal with Fabric API permissions

### 1. Authenticate

```bash
# Login and cache token for the Fabric Terraform provider
az login --scope api://$(az account show --query tenantId -otsv)/fabric_terraform_provider/.default
```

### 2. Initialize a target environment

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 3. Expand to additional environments

Repeat for `test/` and `prod/` directories. Each environment references the same reusable modules with environment-specific variable overrides.

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [Governance Hierarchy](docs/01-governance-hierarchy.md) | How Tenant, Capacity, Domain, Subdomain, and Workspace layers interrelate |
| [Domain Strategy](docs/02-domain-strategy.md) | Source-aligned vs. consumer-aligned domain models and the multimodal recommendation |
| [Naming Conventions](docs/03-naming-conventions.md) | The `{Domain}-{Project}-{Layer}-{Environment}` standard with enforcement via Terraform |
| [DTAP Lifecycle](docs/04-dtap-lifecycle.md) | Workspace isolation across Dev, Test, UAT, and Production stages |
| [Terraform Architecture](docs/05-terraform-architecture.md) | Module design, provider configuration, and state management |
| [Workload Identity](docs/06-workload-identity.md) | Managed identity creation, Entra ID group membership, and tenant setting authorization |
| [CI/CD Pipeline](docs/07-cicd-pipeline.md) | GitHub Actions workflow with plan → approve → apply gates |

---

## Key Design Decisions

1. **Multimodal domain strategy** — Source-aligned domains for backend data engineering (tight governance, system-ownership scope) coexist with consumer-aligned domains for business analytics (cross-functional, broader audience).

2. **Naming convention as code** — Terraform variable validation blocks enforce the `{Domain}-{Project}-{Layer}-{Environment}` pattern at `plan` time, preventing non-conforming workspace names from ever being applied.

3. **Module-per-concern architecture** — Separate modules for `domain`, `workspace`, and `capacity` allow teams to compose infrastructure declaratively while the modules enforce organizational standards internally.

4. **Environment-per-directory** — Each DTAP stage has its own Terraform root with its own state file, preventing a failed dev change from impacting production.

5. **Workload identity over user credentials** — The CI/CD pipeline authenticates via User-Assigned Managed Identity with federated OIDC credentials, avoiding stored secrets entirely.

---

## References

- [Terraform Provider for Microsoft Fabric — Registry](https://registry.terraform.io/providers/microsoft/fabric/latest/docs)
- [Terraform Provider for Microsoft Fabric — GitHub](https://github.com/microsoft/terraform-provider-fabric)
- [Microsoft Fabric Domains — Best Practices](https://learn.microsoft.com/en-us/fabric/governance/domains-best-practices)
- [Microsoft Fabric Governance & Compliance Overview](https://learn.microsoft.com/en-us/fabric/governance/governance-compliance-overview)
- [Fabric Lifecycle Management Best Practices](https://learn.microsoft.com/en-us/fabric/cicd/best-practices-cicd)
- [Terraform Provider Blog Series — Microsoft Fabric Blog](https://blog.fabric.microsoft.com/en-us/blog/terraform-provider-for-microsoft-fabric-1-accelerating-first-steps-using-the-clis/)

---

## License

This repository is provided as a reference architecture. Adapt to your organization's requirements.
