# modules/domain/outputs.tf

output "id" {
  description = "The ID of the created domain."
  value       = fabric_domain.this.id
}

output "name" {
  description = "The display name of the domain."
  value       = fabric_domain.this.display_name
}

output "subdomain_ids" {
  description = "Map of subdomain name to subdomain ID."
  value       = { for k, v in fabric_domain.subdomains : k => v.id }
}
