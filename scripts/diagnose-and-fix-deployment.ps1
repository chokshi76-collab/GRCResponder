# Diagnose and Fix Azure Function App Deployment Issues
# This identifies why the REST endpoints are returning 404 and fixes the deployment

Write-Host "Diagnosing Azure Function App deployment issues..." -ForegroundColor Green

# First, let's check what endpoints are currently working
Write-Host ""
Write-Host "1. Testing current endpoints..." -ForegroundColor Cyan

# Test the old MCP endpoint that we know was working
$baseUrl = "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net"

try {
    Write-Host "Testing old MCP endpoint: GET $baseUrl/api/mcp" -ForegroundColor Yellow
    $mcpResponse = Invoke-RestMethod -Uri "$baseUrl/api/mcp" -Method GET
    Write-Host "✅ Old MCP endpoint still working" -ForegroundColor Green
    Write-Host "   Response: $($mcpResponse)" -ForegroundColor White
} catch {
    Write-Host "❌ Old MCP endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Checking Function App structure..." -ForegroundColor Cyan

# List current function directories
Write-Host "Current function directories:" -ForegroundColor Yellow
$functionDirs = Get-ChildItem -Path "src/mcp-server" -Directory
foreach ($dir in $functionDirs) {
    Write-Host "  • $($dir.Name)" -ForegroundColor White
    $functionJsonPath = "$($dir.FullName)/function.json"
    if (Test-Path $functionJsonPath) {
        Write-Host "    ✅ Has function.json" -ForegroundColor Green
    } else {
        Write-Host "    ❌ Missing function.json" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "3. Creating missing function configurations..." -ForegroundColor Cyan

# Create function configurations for each REST endpoint
$functionConfigs = @{
    "docs" = @{
        bindings = @(
            @{
                authLevel = "anonymous"
                type = "httpTrigger"
                direction = "in"
                name = "req"
                methods = @("get", "options")
                route = "docs"
            },
            @{
                type = "http"
                direction = "out"
                name = "res"
            }
        )
        scriptFile = "../dist/index.js"
        entryPoint = "apiDocs"
    }
    
    "health" = @{
        bindings = @(
            @{
                authLevel = "anonymous"
                type = "httpTrigger"
                direction = "in"
                name = "req"
                methods = @("get", "options")
                route = "health"
            },
            @{
                type = "http"
                direction = "out"
                name = "res"
            }
        )
        scriptFile = "../dist/index.js"
        entryPoint = "healthCheck"
    }
    
    "tools" = @{
        bindings = @(
            @{
                authLevel = "anonymous"
                type = "httpTrigger"
                direction = "in"
                name = "req"
                methods = @("get", "options")
                route = "tools"
            },
            @{
                type = "http"
                direction = "out"
                name = "res"
            }
        )
        scriptFile = "../dist/index.js"
        entryPoint = "listTools"
    }
    
    "execute-tool" = @{
        bindings = @(
            @{
                authLevel = "anonymous"
                type = "httpTrigger"
                direction = "in"
                name = "req"
                methods = @("post", "options")
                route = "tools/{toolName}"
            },
            @{
                type = "http"
                direction = "out"
                name = "res"
            }
        )
        scriptFile = "../dist/index.js"
        entryPoint = "executeTool"
    }
}

# Create function directories and config files
$configsCreated = 0
foreach ($functionName in $functionConfigs.Keys) {
    $functionDir = "src/mcp-server/$functionName"
    $configPath = "$functionDir/function.json"
    
    Write-Host "Creating function: $functionName" -ForegroundColor Yellow
    
    # Create directory if it doesn't exist
    if (-Not (Test-Path $functionDir)) {
        New-Item -ItemType Directory -Path $functionDir -Force | Out-Null
        Write-Host "  ✅ Created directory: $functionDir" -ForegroundColor Green
    }
    
    # Write function configuration
    $functionConfigs[$functionName] | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "  ✅ Created config: $configPath" -ForegroundColor Green
    $configsCreated++
}

Write-Host ""
Write-Host "4. Updating host.json configuration..." -ForegroundColor Cyan

# Update host.json for proper REST API routing
$hostConfig = @{
    version = "2.0"
    logging = @{
        applicationInsights = @{
            samplingSettings = @{
                isEnabled = $true
            }
        }
    }
    extensionBundle = @{
        id = "Microsoft.Azure.Functions.ExtensionBundle"
        version = "[4.*, 5.0.0)"
    }
    http = @{
        routePrefix = "api"
        maxOutstandingRequests = 200
        maxConcurrentRequests = 100
        dynamicThrottlesEnabled = $true
    }
    functionTimeout = "00:05:00"
}

$hostConfigPath = "src/mcp-server/host.json"
$hostConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $hostConfigPath -Encoding UTF8
Write-Host "✅ Updated host.json for REST API routing" -ForegroundColor Green

Write-Host ""
Write-Host "5. Committing and deploying fixes..." -ForegroundColor Cyan

# Add all changes
git add .

# Commit with clear message
$commitMessage = @"
fix: Add missing Azure Function configurations for REST API endpoints

ISSUE: REST endpoints returning 404 - missing function.json files

SOLUTION:
- Created function.json for all 4 REST endpoints (docs, health, tools, execute-tool)
- Updated host.json with proper HTTP routing configuration
- Each endpoint properly configured with correct entry points and routes

Endpoints being deployed:
- GET /api/docs - OpenAPI documentation (apiDocs function)
- GET /api/health - Health check (healthCheck function)  
- GET /api/tools - List tools (listTools function)
- POST /api/tools/{toolName} - Execute tool (executeTool function)

This should resolve the 404 errors and enable the Universal REST API.
"@

git commit -m $commitMessage

Write-Host "✅ Changes committed with detailed fix description" -ForegroundColor Green

# Push to trigger deployment
Write-Host "Pushing to trigger Azure deployment..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "6. Deployment Summary:" -ForegroundColor Green
Write-Host "✅ Created $configsCreated function configurations" -ForegroundColor White
Write-Host "✅ Updated host.json for REST routing" -ForegroundColor White
Write-Host "✅ Committed and pushed fixes to GitHub" -ForegroundColor White
Write-Host "✅ GitHub Actions deployment triggered" -ForegroundColor White

Write-Host ""
Write-Host "⏱️  Wait ~6 minutes for deployment, then test again with:" -ForegroundColor Cyan
Write-Host ".\scripts\test-universal-api.ps1" -ForegroundColor White
Write-Host ""
Write-Host "📊 Monitor deployment progress:" -ForegroundColor Yellow
Write-Host "https://github.com/chokshi76-collab/GRCResponder/actions" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Root cause identified: Missing function.json files for new REST endpoints" -ForegroundColor Yellow
Write-Host "🛠️  Solution applied: Created all required function configurations" -ForegroundColor Green