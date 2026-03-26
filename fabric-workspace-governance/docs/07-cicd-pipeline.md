# CI/CD Pipeline

This document describes the GitHub Actions workflow for automated Terraform deployments with approval gates. An equivalent Azure DevOps pipeline can be built from the same principles.

---

## Pipeline Flow

```
┌──────────┐    ┌──────────┐    ┌──────────────┐    ┌──────────┐    ┌──────────┐
│  Commit   │───►│  Plan    │───►│   Review     │───►│  Apply   │───►│  Verify  │
│  to PR    │    │  (auto)  │    │  (manual     │    │  (auto)  │    │  (auto)  │
│           │    │          │    │   approval)  │    │          │    │          │
└──────────┘    └──────────┘    └──────────────┘    └──────────┘    └──────────┘
     │               │                │                   │               │
  developer     terraform plan    team lead /         terraform       drift check
  pushes PR     output posted     platform team       apply           + output
                as PR comment     approves in GH                      validation
```

---

## Workflow Stages

### 1. Plan (on Pull Request)

Triggered on every PR to `main`. Runs `terraform plan` for each environment and posts the plan output as a PR comment.

**Purpose:** Let reviewers see exactly what infrastructure changes will be applied before approval.

### 2. Review (Manual Approval)

GitHub Environment protection rules require manual approval from designated reviewers before `apply` runs.

**Purpose:** Human-in-the-loop gate to prevent accidental or unauthorized changes.

### 3. Apply (on Merge to Main)

Triggered when a PR is merged to `main`. Runs `terraform apply` with the plan file generated in the previous stage.

**Purpose:** Execute the approved infrastructure changes.

### 4. Verify (Post-Apply)

Runs `terraform plan -detailed-exitcode` after apply to confirm no drift remains.

**Purpose:** Validate that the apply was successful and the state is clean.

---

## GitHub Actions Workflow

See [`.github/workflows/terraform.yml`](../.github/workflows/terraform.yml) for the full workflow implementation.

### Key Configuration

**GitHub Secrets Required:**

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Managed Identity Client ID |
| `AZURE_TENANT_ID` | Entra ID Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID (for state storage) |

**GitHub Environments Required:**

| Environment | Protection Rules |
|-------------|-----------------|
| `fabric-dev` | Auto-approve (or require 1 reviewer) |
| `fabric-test` | Require 1 reviewer |
| `fabric-prod` | Require 2 reviewers, restrict to `main` branch |

---

## Drift Detection (Scheduled)

In addition to the PR-triggered pipeline, schedule a nightly drift detection job:

```yaml
on:
  schedule:
    - cron: '0 6 * * *'  # 6 AM UTC daily

jobs:
  drift-detection:
    strategy:
      matrix:
        environment: [dev, test, prod]
    steps:
      - name: Terraform Plan (drift check)
        run: terraform plan -detailed-exitcode
        continue-on-error: true
      
      - name: Notify on drift
        if: steps.plan.outcome == 'failure'
        # Send Slack/Teams notification
```

---

## Azure DevOps Equivalent

For teams using Azure DevOps instead of GitHub Actions:

| GitHub Actions Concept | Azure DevOps Equivalent |
|----------------------|------------------------|
| Workflow YAML | Pipeline YAML (`azure-pipelines.yml`) |
| GitHub Environment | Azure DevOps Environment with approval gates |
| OIDC federated credential | Workload Identity Federation on Service Connection |
| PR comment with plan output | Pipeline artifact + PR comment via REST API |
| `actions/checkout` | `checkout` task |
| `hashicorp/setup-terraform` | `TerraformInstaller` task |

---

## Operational Runbook

### Applying an Emergency Change

1. Create a branch from `main`
2. Make the Terraform change
3. Open a PR — plan runs automatically
4. Get expedited review approval
5. Merge to `main` — apply runs automatically
6. Verify in the Fabric portal

### Rolling Back a Change

```bash
# Option 1: Revert the Git commit and re-apply
git revert <commit-sha>
git push  # triggers plan → apply pipeline

# Option 2: Target a specific resource
terraform apply -target=module.workspace_name
```

### Importing an Existing Resource

```bash
# If someone created a workspace manually, import it into state
terraform import 'module.fin_reporting.fabric_workspace.this' '<workspace-guid>'

# Then run plan to see if configuration matches
terraform plan
```

---

## Next Steps

With the CI/CD pipeline in place, the full automation loop is complete:

1. Developer defines infrastructure in Terraform
2. PR triggers plan and review
3. Approved changes are applied automatically
4. Nightly drift detection catches manual changes
5. All changes are auditable via Git history and Terraform state
