# Implementation steps for modular PDF processor
cd "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

Write-Host "🎯 PHASE 3.1: Implementing Modular PDF Processor with Real Azure Document Intelligence" -ForegroundColor Green

Write-Host "`n📋 Step-by-step implementation:" -ForegroundColor Cyan

Write-Host "`n1. Create tools directory:" -ForegroundColor Yellow
Write-Host "   mkdir src/mcp-server/src/tools" -ForegroundColor White

Write-Host "`n2. Create pdf-processor.ts file:" -ForegroundColor Yellow
Write-Host "   Copy the 'pdf-processor.ts' artifact content to:" -ForegroundColor White
Write-Host "   src/mcp-server/src/tools/pdf-processor.ts" -ForegroundColor Green

Write-Host "`n3. Update index.ts file:" -ForegroundColor Yellow
Write-Host "   Copy the 'index-with-modular-pdf.ts' artifact content to:" -ForegroundColor White
Write-Host "   src/mcp-server/src/index.ts" -ForegroundColor Green

Write-Host "`n4. Commit and deploy:" -ForegroundColor Yellow
Write-Host "   git add src/mcp-server/src/tools/pdf-processor.ts" -ForegroundColor White
Write-Host "   git add src/mcp-server/src/index.ts" -ForegroundColor White
Write-Host "   git commit -m 'PHASE 3.1: Implement modular PDF processor with real Azure Document Intelligence'" -ForegroundColor White
Write-Host "   git push origin main" -ForegroundColor White

Write-Host "`n🏗️ What this implementation provides:" -ForegroundColor Green
Write-Host "   ✅ Real Azure Document Intelligence integration" 
Write-Host "   ✅ Modular architecture with clean separation"
Write-Host "   ✅ Comprehensive PDF analysis (text, tables, key-value pairs)"
Write-Host "   ✅ Configuration guidance when Azure credentials not set"
Write-Host "   ✅ Optional Azure Blob Storage for result persistence"
Write-Host "   ✅ TypeScript interfaces for type safety"
Write-Host "   ✅ Detailed error handling and logging"

Write-Host "`n🔧 Configuration needed after deployment:" -ForegroundColor Cyan
Write-Host "   Set these environment variables in Azure Function App:"
Write-Host "   - AZURE_FORM_RECOGNIZER_ENDPOINT" -ForegroundColor Yellow
Write-Host "   - AZURE_FORM_RECOGNIZER_KEY" -ForegroundColor Yellow
Write-Host "   - AZURE_STORAGE_CONNECTION_STRING (optional)" -ForegroundColor Gray

Write-Host "`n🧪 Testing after deployment:" -ForegroundColor Cyan
Write-Host "   1. Without Azure credentials: Returns configuration guidance"
Write-Host "   2. With Azure credentials: Processes real PDFs with AI"
Write-Host "   3. Supports URL and base64 PDF inputs"
Write-Host "   4. Multiple analysis types: text, tables, layout, comprehensive"

Write-Host "`n🚀 Expected results:" -ForegroundColor Green
Write-Host "   - process_pdf tool will use real Azure Document Intelligence"
Write-Host "   - Other tools remain as placeholders (ready for future modularization)"
Write-Host "   - Clean modular architecture established"
Write-Host "   - Foundation set for implementing remaining 4 tools"

Write-Host "`n📊 Success metrics:" -ForegroundColor Yellow
Write-Host "   ✅ Deployment successful without TypeScript errors"
Write-Host "   ✅ Health check shows 'modular_architecture: ACTIVE'"
Write-Host "   ✅ process_pdf returns configuration guidance or real results"
Write-Host "   ✅ Other endpoints continue working as before"

Write-Host "`n🎯 Next phase preview:" -ForegroundColor Magenta
Write-Host "   After this works: Modularize CSV analyzer with SQL integration"
Write-Host "   Then: Web scraper with Puppeteer"
Write-Host "   Then: Document search with Azure AI Search"
Write-Host "   Finally: Complete Universal AI Tool Platform"

Write-Host "`n🔥 Ready to implement? Run the steps above!" -ForegroundColor Green