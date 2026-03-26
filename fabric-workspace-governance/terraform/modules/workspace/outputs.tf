# modules/workspace/outputs.tf

output "id" {
  description = "The ID of the created workspace."
  value       = fabric_workspace.this.id
}

output "display_name" {
  description = "The display name of the workspace."
  value       = fabric_workspace.this.display_name
}
