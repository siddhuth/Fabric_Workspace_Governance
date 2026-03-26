# modules/workspace/variables.tf

variable "display_name" {
  type        = string
  description = "Workspace display name. Must follow {Domain}-{Project}-{Layer}-{Environment} pattern."

  validation {
    condition = can(regex(
      "^[A-Z]+-[A-Za-z0-9]+-(?:Bronze|Silver|Gold|Reporting|Sandbox)-(?:Dev|Test|UAT|Prod)$",
      var.display_name
    ))
    error_message = <<-EOT
      Workspace name must match pattern: {Domain}-{Project}-{Layer}-{Env}
      
      Examples:
        FIN-QuarterlyFinancials-Gold-Prod
        MKT-CampaignAnalytics-Silver-Dev
        ENG-DataPlatform-Bronze-Test
      
      Domain: uppercase abbreviation (FIN, MKT, HR, ENG, etc.)
      Project: PascalCase project name
      Layer: Bronze, Silver, Gold, Reporting, or Sandbox
      Environment: Dev, Test, UAT, or Prod
    EOT
  }
}

variable "description" {
  type        = string
  description = "Workspace description."
  default     = ""
}

variable "capacity_id" {
  type        = string
  description = "The ID of the Fabric capacity to assign this workspace to."
}

variable "domain_id" {
  type        = string
  description = "The ID of the domain to associate this workspace with. Set to null to skip domain assignment."
  default     = null
}

variable "role_assignments" {
  type = list(object({
    principal_id   = string
    principal_type = string # "User", "Group", or "ServicePrincipal"
    role           = string # "Admin", "Member", "Contributor", "Viewer"
  }))
  description = "List of RBAC role assignments for this workspace."
  default     = []

  validation {
    condition = alltrue([
      for ra in var.role_assignments :
      contains(["Admin", "Member", "Contributor", "Viewer"], ra.role)
    ])
    error_message = "Role must be one of: Admin, Member, Contributor, Viewer."
  }

  validation {
    condition = alltrue([
      for ra in var.role_assignments :
      contains(["User", "Group", "ServicePrincipal"], ra.principal_type)
    ])
    error_message = "Principal type must be one of: User, Group, ServicePrincipal."
  }
}

variable "git_config" {
  type = object({
    provider_type           = string           # "AzureDevOps" or "GitHub"
    organization            = string
    project                 = optional(string)  # Required for AzureDevOps
    repository              = string
    branch                  = string
    directory               = optional(string, "/")
    initialization_strategy = optional(string, "PreferRemote")
  })
  description = "Git integration configuration. Set to null to skip Git connection."
  default     = null
}
