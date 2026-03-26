# environments/prod/variables.tf

variable "capacity_name" {
  type        = string
  description = "Display name of the Fabric capacity for production."
}

# --- Entra ID Group IDs ---

variable "platform_admin_group_id" {
  type        = string
  description = "Object ID of the Platform Admin security group (workspace Admin role in prod)."
}

variable "finance_admin_group_id" {
  type        = string
  description = "Object ID of the Finance domain admin security group."
}

variable "finance_contributor_group_id" {
  type        = string
  description = "Object ID of the Finance domain contributor security group."
}

variable "finance_viewer_group_id" {
  type        = string
  description = "Object ID of the Finance viewer security group."
}

variable "marketing_admin_group_id" {
  type        = string
  description = "Object ID of the Marketing domain admin security group."
}

variable "marketing_viewer_group_id" {
  type        = string
  description = "Object ID of the Marketing viewer security group."
}

variable "data_engineering_group_id" {
  type        = string
  description = "Object ID of the Data Engineering team security group."
}

# --- Azure DevOps ---

variable "ado_organization" {
  type        = string
  description = "Azure DevOps organization name."
  default     = ""
}

variable "ado_project" {
  type        = string
  description = "Azure DevOps project name."
  default     = ""
}
