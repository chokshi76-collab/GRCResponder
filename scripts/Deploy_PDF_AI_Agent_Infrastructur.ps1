# Deploy PDF AI Agent Infrastructure to Azure

# 2. Deploy the Bicep template to existing resource group
az deployment group create \
  --resource-group pdf-ai-agent-rg-dev \
  --template-file infrastructure/bicep/main.bicep \
  --parameters @infrastructure/bicep/parameters.dev.json

# 3. Get deployment outputs for later use
az deployment group show \
  --resource-group pdf-ai-agent-rg-dev \
  --name main \
  --query properties.outputs

# 4. Verify key resources were created
echo "Checking deployed resources..."
az resource list --resource-group pdf-ai-agent-rg-dev --output table

# 5. Get connection strings and endpoints (save these for MCP server config)
echo "Getting connection strings..."

# SQL Database connection string
az sql db show-connection-string \
  --client ado.net \
  --server pdf-ai-agent-sql-dev \
  --name pdf-ai-agent-db-dev

# Storage account connection string
az storage account show-connection-string \
  --resource-group pdf-ai-agent-rg-dev \
  --name pdfaiagentstorage001 \
  --query connectionString

# AI Search admin key
az search admin-key show \
  --resource-group pdf-ai-agent-rg-dev \
  --service-name pdf-ai-agent-search-dev

# Document Intelligence endpoint and key
az cognitiveservices account show \
  --resource-group pdf-ai-agent-rg-dev \
  --name pdf-ai-agent-docint-dev \
  --query properties.endpoint

az cognitiveservices account keys list \
  --resource-group pdf-ai-agent-rg-dev \
  --name pdf-ai-agent-docint-dev