# Azure Deployment Modes - Clean Infrastructure Guide

## Problem: Duplicate Resource Creation

**Issue:** Bicep deployments were creating duplicate resources instead of managing existing ones, leading to:
- Multiple identical Function Apps, SQL Servers, Storage Accounts
- Massive cost overruns ($800-1000/month for duplicates)
- Resource management complexity

## Root Cause: Incremental Deployment Mode

**Incorrect Default Behavior:**
```powershell
# This creates duplicates when resource names change
New-AzResourceGroupDeployment -Mode Incremental  # DEFAULT MODE
```

## Solution: Complete Deployment Mode

**Complete Mode Benefits:**
- ✅ **Creates** resources defined in template
- ✅ **Updates** existing resources to match template  
- ✅ **Deletes** resources NOT in template
- ✅ **Ensures** infrastructure matches Bicep exactly

## Updated Deployment Commands

### PowerShell (Function App Workflow):
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName ${{ env.RESOURCE_GROUP }} `
  -TemplateFile "infrastructure/bicep/main.bicep" `
  -TemplateParameterFile "environments/dev/parameters.dev.json" `
  -Mode Complete `  # 🔥 KEY FIX
  -Verbose
```

### Azure CLI (Infrastructure Workflow):
```bash
az deployment group create \
  --resource-group ${{ env.RESOURCE_GROUP_NAME }} \
  --template-file infrastructure/bicep/main.bicep \
  --parameters environments/${{ env.ENVIRONMENT_NAME }}/parameters.${{ env.ENVIRONMENT_NAME }}.json \
  --mode Complete \  # 🔥 KEY FIX
  --name "infrastructure-$(date +%Y%m%d-%H%M%S)"
```

## Deployment Modes Comparison

| Mode | Creates Resources | Updates Resources | Deletes Extra Resources | Use Case |
|------|------------------|-------------------|------------------------|----------|
| **Incremental** | ✅ Yes | ✅ Yes | ❌ **No** | Adding resources only |
| **Complete** | ✅ Yes | ✅ Yes | ✅ **Yes** | Clean infrastructure |

## Safe Deployment Process

### 1. What-If Analysis (Recommended)
```powershell
# Test deployment without changes
./scripts/deploy-infrastructure-clean.ps1 -Environment dev -WhatIf
```

### 2. Complete Deployment
```powershell
# Deploy with Complete mode
./scripts/deploy-infrastructure-clean.ps1 -Environment dev
```

### 3. Verification
```powershell
# Check final resources match template
az resource list --resource-group pdf-ai-agent-rg-dev
```

## Updated Workflows

**Files Modified:**
- ✅ `.github/workflows/deploy-function-app.yml` - Added `-Mode Complete`
- ✅ `.github/workflows/deploy-infrastructure.yml` - Added `--mode Complete`
- ✅ `scripts/deploy-infrastructure-clean.ps1` - New standalone script

## Cost Impact

**Before (Incremental Mode):**
- 3x Function Apps, 3x SQL Servers, 3x Storage Accounts
- **Cost:** $800-1000/month

**After (Complete Mode):**
- 1x Function App, 0x SQL Servers, 1x Storage Account
- **Cost:** $300-350/month
- **Savings:** $500-650/month (65-80% reduction)

## Safety Features

**What-If Analysis:**
```powershell
# See what will be deleted/created WITHOUT making changes
-WhatIf parameter
```

**Resource Protection:**
- Key Vault has soft-delete protection
- Resource groups are preserved
- Deployment history maintained

## Warning: Complete Mode Behavior

⚠️ **IMPORTANT:** Complete mode will **DELETE** any resources in the resource group that are NOT defined in your Bicep template.

**Best Practices:**
1. Always run What-If first
2. Review current resources before deployment
3. Ensure Bicep template includes ALL needed resources
4. Use separate resource groups for different environments

## Example: Clean Deployment

```powershell
# 1. Review current resources
az resource list --resource-group pdf-ai-agent-rg-dev --output table

# 2. What-If analysis
./scripts/deploy-infrastructure-clean.ps1 -Environment dev -WhatIf

# 3. Deploy if What-If looks correct
./scripts/deploy-infrastructure-clean.ps1 -Environment dev
```

This approach ensures your Azure infrastructure exactly matches your Bicep template, eliminating duplicate resource creation and reducing costs significantly.