# environments/test/variables.tf

variable "capacity_name" {
  type        = string
  description = "Display name of the Fabric capacity for test."
}

variable "finance_admin_group_id" {
  type        = string
  description = "Object ID of the Finance domain admin security group."
}

variable "qa_group_id" {
  type        = string
  description = "Object ID of the QA team security group."
}

variable "data_engineering_group_id" {
  type        = string
  description = "Object ID of the Data Engineering team security group."
}
