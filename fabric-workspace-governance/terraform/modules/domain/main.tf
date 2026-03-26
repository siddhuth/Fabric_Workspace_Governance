# modules/domain/main.tf
# Creates a Fabric domain, optional subdomains, and role assignments.

resource "fabric_domain" "this" {
  display_name = var.name
  description  = var.description
}

# --- Subdomains ---

resource "fabric_domain" "subdomains" {
  for_each = toset(var.subdomains)

  display_name     = each.value
  parent_domain_id = fabric_domain.this.id
  description      = "${each.value} subdomain of ${var.name}"
}

# --- Domain Role Assignments ---

resource "fabric_domain_role_assignment" "admins" {
  for_each = {
    for p in var.admin_principals : "${p.principal_id}-${p.role}" => p
  }

  domain_id      = fabric_domain.this.id
  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type
  role           = each.value.role
}

resource "fabric_domain_role_assignment" "contributors" {
  for_each = {
    for p in var.contributor_principals : "${p.principal_id}-${p.role}" => p
  }

  domain_id      = fabric_domain.this.id
  principal_id   = each.value.principal_id
  principal_type = each.value.principal_type
  role           = each.value.role
}
