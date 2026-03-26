# Domain Strategy

Choosing a domain structure is one of the most consequential governance decisions in a Fabric deployment. This document presents the two primary paradigms, their tradeoffs, and the recommended hybrid approach.

---

## Two Paradigms

### Source-Aligned Domains

Domains are organized around the **origin of data** — the source systems and ingestion pipelines that feed the platform.

```
ERP-Domain/
├── ERP-Orders-Bronze-Dev
├── ERP-Orders-Bronze-Prod
├── ERP-Inventory-Silver-Dev
└── ERP-Inventory-Silver-Prod

CRM-Domain/
├── CRM-Contacts-Bronze-Dev
├── CRM-Contacts-Bronze-Prod
└── CRM-Opportunities-Silver-Prod

HRIS-Domain/
├── HRIS-Employees-Bronze-Dev
└── HRIS-Employees-Silver-Prod
```

**Strengths:**
- Governance scope mirrors system ownership (the team that owns the ERP owns the ERP domain)
- Tight control over data quality at ingestion
- Clear accountability for pipeline failures
- Natural fit for data engineering teams

**Weaknesses:**
- Business consumers don't think in terms of source systems
- Cross-functional analytics (e.g., "customer 360") span multiple source domains
- Can lead to domain proliferation as the source system landscape grows
- Discoverability suffers for non-technical users

---

### Consumer-Aligned Domains

Domains are organized around **business value and process** — the use cases and audiences that consume the data.

```
Sales-Domain/
├── Sales-Pipeline-Gold-Dev
├── Sales-Pipeline-Gold-Prod
├── Sales-Forecasting-Gold-Dev
└── Sales-Forecasting-Gold-Prod

Marketing-Domain/
├── MKT-Campaign-Analytics-Gold-Dev
├── MKT-Campaign-Analytics-Gold-Prod
└── MKT-Attribution-Gold-Prod

Executive-Domain/
├── EXEC-KPI-Dashboard-Gold-Prod
└── EXEC-Board-Reporting-Gold-Prod
```

**Strengths:**
- Aligns with how business users discover and consume data
- Data products can be cross-functional (pulling from multiple sources)
- Natural fit for analytics, BI, and reporting teams
- Scales with business process, not with the number of source systems

**Weaknesses:**
- Governance ownership is less clear (who "owns" a cross-functional data product?)
- May create tension between source data stewards and consumer-facing teams
- Backend data work (ETL, data quality) doesn't map cleanly to consumer domains

---

## Recommended: Multimodal Strategy

In practice, few organizations can conform fully to either paradigm. The recommended approach is to **allow both types to coexist**:

```
┌─────────────────────────────────────────────────────────────┐
│                    FABRIC TENANT                            │
│                                                             │
│  SOURCE-ALIGNED DOMAINS          CONSUMER-ALIGNED DOMAINS   │
│  (Backend / Data Engineering)    (Analytics / BI / Reports) │
│                                                             │
│  ┌──────────────┐                ┌──────────────┐          │
│  │ ERP-Domain   │ ──────────►    │ Sales-Domain │          │
│  │ (Bronze/     │   curated      │ (Gold layer  │          │
│  │  Silver)     │   data         │  analytics)  │          │
│  └──────────────┘   products     └──────────────┘          │
│                                                             │
│  ┌──────────────┐                ┌──────────────┐          │
│  │ CRM-Domain   │ ──────────►    │ Marketing    │          │
│  │ (Bronze/     │                │ Domain       │          │
│  │  Silver)     │                │ (Gold layer) │          │
│  └──────────────┘                └──────────────┘          │
│                                                             │
│  ┌──────────────┐                ┌──────────────┐          │
│  │ HRIS-Domain  │ ──────────►    │ Executive    │          │
│  │ (Bronze/     │                │ Domain       │          │
│  │  Silver)     │                │ (Gold layer) │          │
│  └──────────────┘                └──────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

**How it works:**
- **Source-aligned domains** own the Bronze and Silver layers. Heavy governance, data engineering ownership, tight access control.
- **Consumer-aligned domains** own the Gold layer and reporting workspaces. Broader access, business-facing governance, domain admins are business owners.
- Data flows from source-aligned workspaces to consumer-aligned workspaces via Fabric pipelines, shortcuts, or mirroring.
- Each domain type has its own governance posture, delegated settings, and admin structure.

---

## Domain Design Checklist

Before creating domains, answer these questions with stakeholders:

| Question | Impact |
|----------|--------|
| What are the major business units or functions? | Determines top-level domain count |
| Do any units have distinct compliance requirements? | May require separate domains for setting delegation |
| How many workspaces will each domain contain? | If > 15-20, consider subdomains |
| Who should be the domain admin? | Should be a business owner, not IT by default |
| Which domain contributors need workspace assignment rights? | Contributors must also be workspace admins |
| Will you use a source-aligned, consumer-aligned, or multimodal structure? | Drives naming convention and workspace organization |

---

## Domain Sizing Guidelines

| Indicator | Action |
|-----------|--------|
| A domain has 1-5 workspaces | Consider merging with a related domain |
| A domain has 6-15 workspaces | Healthy size, no subdomains needed |
| A domain has 16-30 workspaces | Introduce subdomains for manageability |
| A domain has 30+ workspaces | Split into separate domains or add aggressive subdomain hierarchy |

---

## Common Organizational Structures Mapped to Domains

| Org Structure | Domain Design | Example |
|---------------|---------------|---------|
| Functional (Finance, HR, Sales) | One domain per function | `Finance`, `HR`, `Sales` |
| Product-based | One domain per product line | `ProductA`, `ProductB` |
| Regional | One domain per geography | `AMER`, `EMEA`, `APAC` |
| Process-based | One domain per value chain stage | `Procurement`, `Manufacturing`, `Distribution` |
| Hybrid | Mix of the above | `Finance` (functional) + `EMEA-Sales` (regional + functional) |

---

## Terraform Implementation

Domains and subdomains are managed through the `domain` module:

```hcl
module "finance_domain" {
  source = "../../modules/domain"

  name        = "Finance"
  description = "Finance department data assets"
  subdomains  = ["Accounting", "FP&A", "Treasury"]

  admin_principals = [
    { principal_id = var.finance_admin_group_id, principal_type = "Group", role = "Admins" },
  ]

  contributor_principals = [
    { principal_id = var.finance_contributor_group_id, principal_type = "Group", role = "Contributors" },
  ]
}
```

See [terraform/modules/domain/](../terraform/modules/domain/) for the full module implementation.

---

## Next: [Naming Conventions →](03-naming-conventions.md)
