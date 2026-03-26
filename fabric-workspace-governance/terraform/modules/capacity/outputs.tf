# modules/capacity/outputs.tf

output "id" {
  description = "The ID of the Fabric capacity."
  value       = data.fabric_capacity.this.id
}
