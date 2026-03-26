# Naming Conventions

Consistent naming is the single most impactful low-cost governance control. It enables automated workspace-to-domain assignment, makes OneLake Catalog useful at scale, and allows Terraform validation to reject non-conforming resources at `plan` time.

---

## Workspace Naming Standard

### Format

```
{Domain}-{Project}-{Layer}-{Environment}
```

### Parameters

| Parameter | Required | Description | Values |
|-----------|----------|-------------|--------|
| **Domain** | Yes | Business domain abbreviation (3-4 chars) | `FIN`, `MKT`, `HR`, `ENG`, `SALES`, `OPS`, `EXEC` |
| **Project** | Yes | Project or workload name (PascalCase) | `QuarterlyFinancials`, `CampaignAnalytics`, `DataPlatform` |
| **Layer** | Yes | Medallion architecture layer or function | `Bronze`, `Silver`, `Gold`, `Reporting`, `Sandbox` |
| **Environment** | Yes | DTAP lifecycle stage | `Dev`, `Test`, `UAT`, `Prod` |

### Examples

```
FIN-QuarterlyFinancials-Gold-Prod
FIN-QuarterlyFinancials-Gold-Dev
MKT-CampaignAnalytics-Silver-Dev
MKT-CampaignAnalytics-Gold-Prod
ENG-DataPlatform-Bronze-Prod
ENG-DataPlatform-Bronze-Test
SALES-Pipeline-Gold-Prod
HR-Workforce-Silver-Dev
EXEC-KPIDashboard-Gold-Prod
```

### Why This Order?

- **Domain first** — workspaces sort by business area in the portal, grouping related content together
- **Project second** — within a domain, workspaces sort by workload
- **Layer third** — within a project, you can see the data flow from Bronze → Silver → Gold
- **Environment last** — least frequent filter; most users work in one environment

---

## Fabric Item Naming Standard

Within a workspace, individual items (Lakehouses, Notebooks, Pipelines, etc.) follow a type-prefixed convention:

| Item Type | Prefix | Example |
|-----------|--------|---------|
| Lakehouse | `lh_` | `lh_orders_bronze` |
| Warehouse | `wh_` | `wh_sales_gold` |
| Notebook | `nb_` | `nb_transform_orders` |
| Pipeline | `pl_` | `pl_ingest_erp_orders` |
| Dataflow | `df_` | `df_dim_customers` |
| Semantic Model | `sm_` | `sm_sales_performance` |
| Report | `rpt_` | `rpt_executive_dashboard` |
| Eventstream | `es_` | `es_clickstream_ingest` |
| KQL Database | `kql_` | `kql_telemetry` |
| Eventhouse | `eh_` | `eh_realtime_analytics` |
| Environment | `env_` | `env_spark_default` |
| SQL Database | `sqldb_` | `sqldb_operational` |

### Item Naming Rules

- Use `snake_case` for all item names
- Include the medallion layer where applicable (e.g., `lh_orders_bronze`, `lh_orders_silver`)
- Keep names descriptive but concise — the workspace name already provides domain and project context
- Avoid special characters beyond underscores

---

## Domain & Subdomain Naming

Domains and subdomains use plain English names without abbreviations:

```
Finance           (domain)
├── Accounting    (subdomain)
├── FP&A          (subdomain)
└── Treasury      (subdomain)

Marketing         (domain)
├── Campaign Analytics  (subdomain)
└── Digital             (subdomain)

Engineering       (domain)
├── Data Platform       (subdomain)
└── MLOps               (subdomain)
```

The short domain abbreviation (e.g., `FIN`) is used only in workspace names, not in the domain display name itself.

---

## Enforcement via Terraform

The workspace module includes a `variable` validation block that rejects non-conforming names at `terraform plan` time:

```hcl
variable "display_name" {
  type        = string
  description = "Workspace display name. Must follow {Domain}-{Project}-{Layer}-{Environment} pattern."

  validation {
    condition = can(regex(
      "^(FIN|MKT|HR|ENG|SALES|OPS|EXEC|DATA|ANALYTICS)-[A-Z][A-Za-z0-9]+-(?:Bronze|Silver|Gold|Reporting|Sandbox)-(?:Dev|Test|UAT|Prod)$",
      var.display_name
    ))
    error_message = "Workspace name must match pattern: {Domain}-{Project}-{Layer}-{Env}. Example: FIN-QuarterlyFinancials-Gold-Prod"
  }
}
```

This ensures that no workspace can be provisioned through Terraform without conforming to the standard. See [terraform/policies/naming_validation.tf](../terraform/policies/naming_validation.tf) for the full validation module.

---

## Automated Domain Assignment

With a consistent naming convention, workspace-to-domain assignment can be automated based on the domain prefix:

| Workspace Prefix | Assigned Domain | Assigned Subdomain |
|------------------|-----------------|-------------------|
| `FIN-*` | Finance | (varies by project) |
| `MKT-*` | Marketing | (varies by project) |
| `HR-*` | HR | — |
| `ENG-*` | Engineering | (varies by project) |
| `SALES-*` | Sales | — |

This is implemented in the workspace Terraform module via the `domain_id` input variable, which links the workspace to its domain at creation time.

---

## Git Repository Naming

When connecting workspaces to Git (Azure DevOps or GitHub), align repository names with workspace names but drop the environment suffix:

| Workspace | Repository | Branch |
|-----------|------------|--------|
| `FIN-QuarterlyFinancials-Gold-Dev` | `FIN-QuarterlyFinancials-Gold` | `main` (dev), feature branches |
| `FIN-QuarterlyFinancials-Gold-Prod` | `FIN-QuarterlyFinancials-Gold` | `main` (via deployment pipeline) |

This avoids duplicating repositories per environment while keeping the naming aligned.

---

## Rollout Strategy

1. **Document and ratify** the naming standard with all stakeholders (CoE, domain owners, IT)
2. **Audit existing workspaces** using the Admin REST API or metadata scanning to identify non-conforming names
3. **Rename existing workspaces** to conform (safe operation — `GroupID` does not change, only XMLA connections are affected)
4. **Enforce via Terraform** for all new workspace provisioning
5. **Restrict manual creation** by limiting the `Create workspaces` tenant setting to a governance group
6. **Audit continuously** using the `UpdateDataDomainFoldersRelationsAsAdmin` operation and periodic metadata scans

---

## Next: [DTAP Lifecycle →](04-dtap-lifecycle.md)
