# environments/dev/variables.tf

variable "capacity_name" {
  type        = string
  description = "Display name of the Fabric capacity for this environment."
}

# --- Entra ID Group IDs ---

variable "finance_admin_group_id" {
  type        = string
  description = "Object ID of the Finance domain admin security group."
}

variable "finance_dev_group_id" {
  type        = string
  description = "Object ID of the Finance development team security group."
}

variable "marketing_admin_group_id" {
  type        = string
  description = "Object ID of the Marketing domain admin security group."
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
