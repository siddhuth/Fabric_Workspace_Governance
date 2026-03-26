# modules/domain/variables.tf

variable "name" {
  type        = string
  description = "Display name for the domain (e.g., 'Finance', 'Marketing')."

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 64
    error_message = "Domain name must be between 2 and 64 characters."
  }
}

variable "description" {
  type        = string
  description = "Description of the domain's purpose and scope."
  default     = ""
}

variable "subdomains" {
  type        = list(string)
  description = "List of subdomain names to create under this domain."
  default     = []

  validation {
    condition     = length(var.subdomains) <= 20
    error_message = "A domain should not have more than 20 subdomains. Consider splitting into separate domains."
  }
}

variable "admin_principals" {
  type = list(object({
    principal_id   = string
    principal_type = string # "User" or "Group"
    role           = string # "Admins"
  }))
  description = "List of principals to assign the Domain Admin role."
  default     = []
}

variable "contributor_principals" {
  type = list(object({
    principal_id   = string
    principal_type = string # "User" or "Group"
    role           = string # "Contributors"
  }))
  description = "List of principals to assign the Domain Contributor role."
  default     = []
}
