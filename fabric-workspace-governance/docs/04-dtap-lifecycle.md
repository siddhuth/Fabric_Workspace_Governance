# DTAP Workspace Lifecycle

DTAP (Development, Test, Acceptance/UAT, Production) is the standard lifecycle pattern for promoting Fabric content through isolated environments. This document covers the workspace isolation model, capacity allocation, and promotion flow.

---

## Environment Isolation Model

Each lifecycle stage gets its own set of workspaces, capacity, and Git branch strategy:

| Stage | Capacity SKU | Purpose | Access | Git Branch |
|-------|-------------|---------|--------|------------|
| **Dev** | F2 (pausable) | Individual developer sandboxes, experimentation | Developer team only | `feature/*` branches |
| **Test** | F4 (pausable) | Integration testing, automated validation | Dev team + QA | `develop` branch |
| **UAT** | F4 (pausable) | Business user validation, pre-production review | Business stakeholders | `release/*` branches |
| **Prod** | F64 (always-on) | Consumer-facing content, monitored workloads | Broad read access, restricted write | `main` branch |

---

## Workspace Topology Per Project

For a typical project (e.g., `FIN-QuarterlyFinancials`), the full DTAP set looks like:

```
FIN-QuarterlyFinancials-Bronze-Dev     ──► capacity-dev
FIN-QuarterlyFinancials-Bronze-Test    ──► capacity-test
FIN-QuarterlyFinancials-Bronze-Prod    ──► capacity-prod

FIN-QuarterlyFinancials-Silver-Dev     ──► capacity-dev
FIN-QuarterlyFinancials-Silver-Test    ──► capacity-test
FIN-QuarterlyFinancials-Silver-Prod    ──► capacity-prod

FIN-QuarterlyFinancials-Gold-Dev       ──► capacity-dev
FIN-QuarterlyFinancials-Gold-Test      ──► capacity-test
FIN-QuarterlyFinancials-Gold-Prod      ──► capacity-prod
```

Not every project needs every combination. Smaller projects may only require `Dev` and `Prod` workspaces.

---

## Promotion Flow

### Option A: Fabric Deployment Pipelines

Fabric's built-in deployment pipelines support up to 10 stages. Content is promoted from one workspace to the next:

```
Dev Workspace ──► Test Workspace ──► Prod Workspace
     │                  │                  │
  [develop]         [validate]        [release]
```

- Deployment pipelines handle item copying and parameter substitution
- Rules can be set per item type (e.g., always deploy Notebooks, skip Lakehouses)
- Best for teams that want a low-code promotion experience

### Option B: Git + CI/CD

For teams using Git integration, promotion follows the branch strategy:

```
feature/add-new-report ──► PR to develop ──► PR to main
         │                       │                │
    Dev Workspace          Test Workspace    Prod Workspace
    (git-connected)        (git-connected)  (git-connected)
```

- Each workspace is connected to Git and syncs with its corresponding branch
- Pull requests serve as approval gates
- The `fabric-cicd` Python library (Microsoft-backed, open-source) automates CI/CD across workspaces
- Best for teams with existing DevOps practices

---

## Capacity Management

### Cost Optimization

| Strategy | Implementation |
|----------|---------------|
| Pause non-production capacities | Schedule `az fabric capacity pause` during off-hours |
| Right-size per stage | Dev: F2, Test: F4, Prod: F64 (adjust based on workload) |
| Separate chargeback | Tag capacities with cost center metadata |
| Monitor utilization | Use Fabric Capacity Metrics app to identify over/under-provisioned capacities |

### Terraform Capacity Pattern

Capacities are Azure resources managed via the `azapi` provider. The Fabric provider references them as data sources:

```hcl
# In the azapi config (separate state)
resource "azapi_resource" "fabric_capacity" {
  type      = "Microsoft.Fabric/capacities@2023-11-01"
  name      = "capacity-prod"
  location  = "East US"
  parent_id = azurerm_resource_group.fabric.id

  body = {
    sku = { name = "F64", tier = "Fabric" }
    properties = {
      administration = {
        members = [var.capacity_admin_upn]
      }
    }
  }
}

# In the Fabric provider config
data "fabric_capacity" "prod" {
  display_name = "capacity-prod"
}
```

---

## Dev Environment Best Practices

- **One workspace per developer** for isolation — prevents one developer's uncommitted changes from affecting another
- **Connect each dev workspace to a feature branch** — enables independent development
- **Use trial or F2 capacities** — minimize cost for experimentation
- **Parameterize data connections** — dev workspaces should point to dev/test data sources, never production
- **Commit early, commit often** — Git integration is the backup mechanism for dev work

---

## Production Environment Best Practices

- **Restrict workspace Admin role** to platform team only
- **Use Member/Contributor roles** for content publishers
- **Use Viewer role** for consumers
- **Enable audit logging** for all workspace operations
- **Connect to `main` branch** — production content should only come from approved merges
- **Never make direct edits** — all changes flow through Dev → Test → Prod pipeline

---

## Next: [Terraform Architecture →](05-terraform-architecture.md)
