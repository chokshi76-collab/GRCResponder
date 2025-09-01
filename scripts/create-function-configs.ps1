# Create Azure Function configurations for Universal REST API endpoints
# This creates the proper function.json files for each REST endpoint

Write-Host "Creating Azure Function configurations for Universal REST API..." -ForegroundColor Green

# Create function configurations for each endpoint
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
foreach ($functionName in $functionConfigs.Keys) {
    $functionDir = "src/mcp-server/$functionName"
    $configPath = "$functionDir/function.json"
    
    Write-Host "Creating function configuration: $functionName" -ForegroundColor Yellow
    
    # Create directory if it doesn't exist
    if (-Not (Test-Path $functionDir)) {
        New-Item -ItemType Directory -Path $functionDir -Force | Out-Null
    }
    
    # Write function configuration
    $functionConfigs[$functionName] | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "  ✅ Created: $configPath" -ForegroundColor White
}

# Remove old MCP-specific function directory
$oldMcpDir = "src/mcp-server/mcp"
if (Test-Path $oldMcpDir) {
    Write-Host "Removing old MCP-specific function directory..." -ForegroundColor Yellow
    Remove-Item -Path $oldMcpDir -Recurse -Force
    Write-Host "  ✅ Removed: $oldMcpDir" -ForegroundColor White
}

# Update host.json for better API performance
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
Write-Host "Updating host.json for optimal API performance..." -ForegroundColor Yellow
$hostConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $hostConfigPath -Encoding UTF8
Write-Host "  ✅ Updated: $hostConfigPath" -ForegroundColor White

Write-Host ""
Write-Host "✅ All Azure Function configurations created!" -ForegroundColor Green
Write-Host ""
Write-Host "Function Endpoints Configured:" -ForegroundColor Cyan
Write-Host "• GET  /api/docs        - OpenAPI documentation" -ForegroundColor White
Write-Host "• GET  /api/health      - Service health check" -ForegroundColor White
Write-Host "• GET  /api/tools       - List all tools" -ForegroundColor White
Write-Host "• POST /api/tools/{name} - Execute specific tool" -ForegroundColor White
Write-Host ""
Write-Host "Ready for final deployment!" -ForegroundColor Yellow