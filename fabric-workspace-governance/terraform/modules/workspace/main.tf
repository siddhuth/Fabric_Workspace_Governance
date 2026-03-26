# modules/workspace/main.tf
# Creates a Fabric workspace with RBAC assignments, domain association, and optional Git integration.

resource "fabric_workspace" "this" {
  display_name = var.display_name
  description  = var.description
  capacity_id  = var.capacity_id
}

# --- Domain Assignment ---

resource "fabric_domain_workspace_assignment" "this" {
  count = var.domain_id != null ? 1 : 0

  domain_id    = var.domain_id
  workspace_id = fabric_workspace.this.id
}

# --- RBAC Role Assignments ---

resource "fabric_workspace_role_assignment" "assignments" {
  for_each = {
    for ra in var.role_assignments : "${ra.principal_id}-${ra.role}" => ra
  }

  workspace_id   = fabric_workspace.this.id
  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type
  role           = each.value.role
}

# --- Git Integration ---

resource "fabric_workspace_git" "this" {
  count = var.git_config != null ? 1 : 0

  workspace_id = fabric_workspace.this.id

  git_provider_details = {
    git_provider_type = var.git_config.provider_type # "AzureDevOps" or "GitHub"
    organization_name = var.git_config.organization
    project_name      = var.git_config.project       # AzureDevOps only
    repository_name   = var.git_config.repository
    branch_name       = var.git_config.branch
    directory_name    = var.git_config.directory
  }

  initialization_strategy = var.git_config.initialization_strategy
}
