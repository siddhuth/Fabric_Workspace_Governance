# Workload Identity Configuration

Terraform automation in CI/CD requires a non-interactive identity that can authenticate to the Fabric APIs. This document covers the recommended setup using a User-Assigned Managed Identity with federated OIDC credentials.

---

## Architecture

```
GitHub Actions / Azure DevOps
        │
        │ OIDC token exchange (no stored secrets)
        ▼
User-Assigned Managed Identity
        │
        │ Member of Entra ID Security Group
        ▼
"Fabric Workload Identities" Security Group
        │
        │ Authorized in Fabric Admin Portal tenant settings
        ▼
Fabric REST APIs (used by Terraform Provider)
```

---

## Step-by-Step Setup

### 1. Create the Managed Identity

```bash
# Set variables
export MANAGEMENT_SUB="<your-azure-subscription-id>"
export RG_NAME="rg-fabric-terraform"
export LOCATION="eastus"
export MI_NAME="mi-fabric-terraform"

# Create resource group and managed identity
az account set --subscription $MANAGEMENT_SUB
az group create --name $RG_NAME --location $LOCATION
az identity create --name $MI_NAME --resource-group $RG_NAME --location $LOCATION

# Capture IDs
export MI_OBJECT_ID=$(az identity show --name $MI_NAME --resource-group $RG_NAME --query principalId -otsv)
export MI_CLIENT_ID=$(az identity show --name $MI_NAME --resource-group $RG_NAME --query clientId -otsv)

echo "Managed Identity Object ID: $MI_OBJECT_ID"
echo "Managed Identity Client ID: $MI_CLIENT_ID"
```

### 2. Create an Entra ID Security Group

```bash
export FABRIC_GROUP_NAME="Fabric Workload Identities"
export FABRIC_GROUP_DESC="Service Principals and Managed Identities used for Fabric automation."
export FABRIC_GROUP_NICK="FabricWorkloadIdentities"

# Create group and add the managed identity
az ad group create \
  --display-name "$FABRIC_GROUP_NAME" \
  --description "$FABRIC_GROUP_DESC" \
  --mail-nickname "$FABRIC_GROUP_NICK"

az ad group member add \
  --group "$FABRIC_GROUP_NAME" \
  --member-id "$MI_OBJECT_ID"

export FABRIC_GROUP_ID=$(az ad group show --group "$FABRIC_GROUP_NAME" --query id -otsv)
echo "Security Group ID: $FABRIC_GROUP_ID"
```

### 3. Authorize in Fabric Admin Portal

Navigate to the **Fabric Admin Portal → Tenant Settings** and enable the following settings for the `Fabric Workload Identities` security group:

| Tenant Setting | Required | Purpose |
|---------------|----------|---------|
| Service principals can use Fabric APIs | Yes | Allows the managed identity to call Fabric REST APIs |
| Service principals can access admin APIs | Yes (if managing domains/tenant settings) | Required for domain creation and admin operations |
| Allow service principals to create and use profiles | Recommended | Enables profile-based operations |

### 4. Grant Capacity Access

The managed identity must be a Capacity Administrator or Contributor for any capacity it will manage:

1. Azure Portal → Navigate to the Fabric Capacity resource
2. Settings → Capacity administrators
3. Add the Managed Identity by its Object ID
4. Save

Alternatively, automate this via the Azure REST API or the `azapi` Terraform provider.

### 5. Configure Federated Credentials (for GitHub Actions)

```bash
# Create federated credential for GitHub Actions
az identity federated-credential create \
  --name "github-actions-main" \
  --identity-name $MI_NAME \
  --resource-group $RG_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:<org>/<repo>:ref:refs/heads/main" \
  --audiences "api://AzureADTokenExchange"

# For pull request workflows
az identity federated-credential create \
  --name "github-actions-pr" \
  --identity-name $MI_NAME \
  --resource-group $RG_NAME \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:<org>/<repo>:pull_request" \
  --audiences "api://AzureADTokenExchange"
```

### 6. Create Remote State Storage

```bash
export STORAGE_PREFIX="stfabrictf"
export STORAGE_NAME="${STORAGE_PREFIX}$(az group show --name $RG_NAME --query id -otsv | sha1sum | cut -c1-8)"

az storage account create \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --min-tls-version TLS1_2 \
  --sku Standard_LRS \
  --https-only true \
  --allow-shared-key-access false \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME \
  --auth-mode login

# Grant the managed identity Storage Blob Data Contributor on the state container
az role assignment create \
  --assignee-object-id $MI_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$MANAGEMENT_SUB/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_NAME"
```

---

## Local Development Authentication

For local development, authenticate using the Azure CLI:

```bash
az login --scope api://$(az account show --query tenantId -otsv)/fabric_terraform_provider/.default
```

If you do not have an Azure subscription, add `--allow-no-subscriptions` and `--tenant`:

```bash
az login --allow-no-subscriptions --tenant <your-tenant-id> \
  --scope api://<your-tenant-id>/fabric_terraform_provider/.default
```

---

## Security Considerations

| Practice | Rationale |
|----------|-----------|
| Use Managed Identity over Service Principal + secret | No secret to rotate or leak |
| Use OIDC federated credentials for CI/CD | No stored credentials in GitHub/ADO |
| Restrict the security group to automation identities only | Prevents accidental human use of the automation path |
| Use separate identities per environment | A compromised dev identity cannot affect prod |
| Enable blob versioning on the state storage account | State history for recovery |
| Enforce RBAC-only auth on the storage account | Shared keys are a security anti-pattern |

---

## Next: [CI/CD Pipeline →](07-cicd-pipeline.md)
