# environments/prod/terraform.tfvars
# Replace placeholder values with your actual Entra ID group Object IDs.

capacity_name = "capacity-prod"

# Entra ID Security Group Object IDs
platform_admin_group_id     = "00000000-0000-0000-0000-000000000010"
finance_admin_group_id      = "00000000-0000-0000-0000-000000000001"
finance_contributor_group_id = "00000000-0000-0000-0000-000000000005"
finance_viewer_group_id     = "00000000-0000-0000-0000-000000000006"
marketing_admin_group_id    = "00000000-0000-0000-0000-000000000003"
marketing_viewer_group_id   = "00000000-0000-0000-0000-000000000007"
data_engineering_group_id   = "00000000-0000-0000-0000-000000000004"

# Azure DevOps
ado_organization = "your-org"
ado_project      = "your-project"
