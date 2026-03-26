# Governance Hierarchy

Microsoft Fabric implements a layered governance model. Understanding how each layer functions — and what it does *not* control — is essential before designing domain structures or writing Terraform.

---

## The Five Layers

### 1. Tenant

The tenant is the outermost boundary. It represents the entire Fabric estate tied to a single Entra ID (Azure AD) tenant.

**What it controls:**
- Global tenant settings via the Admin Portal
- Which users/groups can create workspaces (the `Create workspaces` tenant setting)
- Default behaviors for all capacities, domains, and workspaces
- Metadata scanning (scanner APIs) for cataloging tools

**Who manages it:** Fabric Administrators, Platform/IT owners

**Key governance action:** Restrict workspace creation to a specific security group (e.g., `Fabric Workspace Creators`) rather than allowing the entire organization to create workspaces by default.

---

### 2. Capacity

Capacities are the compute resources that power all Fabric workloads. Each capacity is an Azure resource (F-SKU) with defined compute and memory limits.

**What it controls:**
- Compute isolation between workloads
- Cost attribution and chargeback boundaries
- Performance isolation (a runaway query in one capacity cannot starve another)
- Pause/resume for cost optimization on non-production capacities

**Who manages it:** Capacity Administrators (requires UPN for users or Object ID for service principals)

**Key governance action:** Split capacities along DTAP boundaries:

| Capacity | SKU | Purpose |
|----------|-----|---------|
| `capacity-dev` | F2 | Developer sandboxes, experimentation |
| `capacity-test` | F4 | Integration testing, load testing |
| `capacity-prod` | F64 | Production workloads, consumer-facing content |

This ensures that development workloads cannot impact production performance, and enables granular cost tracking per lifecycle stage.

> **Note:** Fabric capacities are Azure resources and must be provisioned via the `azapi` or `azurerm` Terraform providers — not the `microsoft/fabric` provider. See the [Capacity module](../terraform/modules/capacity/) for the data source pattern.

---

### 3. Domain

Domains are a **metadata construct** for logically grouping workspaces. They are the primary mechanism for implementing data mesh principles in Fabric.

**What it controls:**
- Logical grouping of workspaces visible in OneLake Catalog
- Delegated tenant settings (domain admins can override specific tenant-level settings for their domain)
- Default sensitivity labels (via Purview integration)
- Discoverability and filtering in search results

**What it does NOT control:**
- Item visibility or accessibility — RBAC remains at the workspace level
- Compute allocation — that is governed by capacity assignment
- Data movement or storage — domains are purely organizational

**Who manages it:**
- **Fabric Admin** — creates domains, assigns domain admins and contributors
- **Domain Admin** — updates domain description, manages contributors, assigns workspaces (for their domain only)
- **Domain Contributor** — can assign workspaces to the domain (must also be workspace admin)

**Key governance action:** Involve business architects, CoE leads, and compliance officers in domain design. Do not let Fabric administrators design domains in isolation.

---

### 4. Subdomain

Subdomains provide a second level of hierarchy within a domain. They exist to narrow governance scope without creating a flat list of dozens of domains.

**Example:**
```
Finance (Domain)
├── Accounting (Subdomain)
├── FP&A (Subdomain)
└── Treasury (Subdomain)
```

**What it controls:**
- Finer-grained filtering in OneLake Catalog
- Further delegation of governance settings
- Location path display in search results (e.g., `Finance > Accounting > FIN-GL-Gold-Prod`)

**Key governance action:** Use subdomains when a domain would otherwise contain more than ~15-20 workspaces, or when distinct teams within a domain have different compliance requirements.

---

### 5. Workspace

Workspaces are the operational unit where Fabric items (Lakehouses, Notebooks, Pipelines, Reports, etc.) live. They are the boundary for collaboration, RBAC, and lifecycle management.

**What it controls:**
- Item storage and organization (folders, task flows)
- Role-based access (Admin, Member, Contributor, Viewer)
- Git integration (branch per workspace for CI/CD)
- Deployment pipeline stage assignment
- Spark environment and compute settings

**Who manages it:** Workspace Admins

**Key governance action:** Enforce naming conventions at creation time (via Terraform variable validation), assign to the correct domain immediately, and connect to Git for version control.

---

## Interaction Model

```
Tenant Settings ──► apply globally UNLESS overridden at domain level
                         │
Domain Settings ──► override delegated tenant settings for workspaces in this domain
                         │
Workspace Settings ──► most granular; workspace admins configure within domain/tenant bounds
```

**Delegation flow:**
1. Tenant admin defines a tenant setting (e.g., default sensitivity label)
2. Tenant admin *delegates* that setting to domain level
3. Domain admin overrides the setting for their domain
4. Workspaces within that domain inherit the domain-level override
5. Workspaces NOT in any domain continue to inherit the tenant-level default

---

## Current Delegable Tenant Settings

As of the current Fabric release, only a limited set of tenant settings can be delegated to domain admins. To find them, search for "Domains" in the Tenant Settings search bar in the Admin Portal.

The set of delegable settings is expected to grow as Fabric matures. Design your domain structure with this trajectory in mind — even if today's delegation surface is narrow, the organizational clarity domains provide is valuable on its own.

---

## Audit & Monitoring

- **Workspace-to-domain assignment changes** are tracked via the `UpdateDataDomainFoldersRelationsAsAdmin` operation in the Fabric audit log
- **Microsoft Purview Hub** (preview) provides domain-level insights including sensitivity label coverage and endorsement coverage, sliceable by domain
- **Metadata scanning APIs** (scanner APIs) enable external cataloging tools to enumerate all items across all workspaces, grouped by domain

---

## Next: [Domain Strategy →](02-domain-strategy.md)
