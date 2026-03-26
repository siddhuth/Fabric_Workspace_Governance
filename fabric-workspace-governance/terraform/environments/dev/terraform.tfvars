# environments/dev/terraform.tfvars
# Replace placeholder values with your actual Entra ID group Object IDs and org details.

capacity_name = "capacity-dev"

# Entra ID Security Group Object IDs
finance_admin_group_id    = "00000000-0000-0000-0000-000000000001"
finance_dev_group_id      = "00000000-0000-0000-0000-000000000002"
marketing_admin_group_id  = "00000000-0000-0000-0000-000000000003"
data_engineering_group_id = "00000000-0000-0000-0000-000000000004"

# Azure DevOps (leave empty if using GitHub)
ado_organization = "your-org"
ado_project      = "your-project"
