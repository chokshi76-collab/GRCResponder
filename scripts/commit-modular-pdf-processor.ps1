# Navigate to repository directory
cd "C:\Users\vishrut.chokshi\OneDrive - Accenture\My Documents\UCI\Capstone 2025\GRCResponder"

# Create the tools directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "src/mcp-server/src/tools"

# Create the modular PDF processor file
# Copy the pdf-processor.ts content from the artifact to:
# src/mcp-server/src/tools/pdf-processor.ts

# Update the main index.ts file
# Copy the updated-index-modular.ts content to:
# src/mcp-server/src/index.ts

# Update package.json to add storage blob dependency
# Add "@azure/storage-blob": "^12.24.0" to dependencies

Write-Host "Files to create/update:" -ForegroundColor Yellow
Write-Host "1. src/mcp-server/src/tools/pdf-processor.ts (NEW MODULAR FILE)" -ForegroundColor Green
Write-Host "2. src/mcp-server/src/index.ts (UPDATED to use modular approach)" -ForegroundColor Cyan
Write-Host "3. src/mcp-server/package.json (ADD @azure/storage-blob dependency)" -ForegroundColor Cyan

Write-Host "`nNext steps after creating files:" -ForegroundColor Yellow
Write-Host "1. Copy artifact content to the files above"
Write-Host "2. Run the git commands below to commit and deploy"

Write-Host "`nGit commands to run after file updates:" -ForegroundColor Green
Write-Host "git add src/mcp-server/src/tools/pdf-processor.ts"
Write-Host "git add src/mcp-server/src/index.ts" 
Write-Host "git add src/mcp-server/package.json"
Write-Host ""
Write-Host "git commit -m `"PHASE 3.1: Implement modular PDF processor with real Azure Document Intelligence`""
Write-Host ""
Write-Host "# Detailed commit message:"
Write-Host "git commit -m `"PHASE 3.1: Implement modular PDF processor with real Azure Document Intelligence

- Create dedicated PDF processor module (src/tools/pdf-processor.ts)
- Replace placeholder processPdf with real Azure AI Form Recognizer SDK
- Implement comprehensive document analysis: text, tables, key-value pairs
- Add confidence scoring and metadata extraction
- Support URL and base64 input methods
- Optional Azure Blob Storage integration for persistence
- Modular architecture for easy testing and maintenance
- Updated main index.ts to use modular PDF processor
- Add @azure/storage-blob dependency for document storage

Business Impact: First real AI integration complete with modular architecture
Technical Achievement: PDF processing now uses actual Azure Document Intelligence
Architecture: Establishes pattern for modularizing remaining tools

Next: Configure Azure Document Intelligence environment variables`""

Write-Host "`ngit push origin main"

Write-Host "`n🎯 Modular Architecture Benefits:" -ForegroundColor Green
Write-Host "✅ Clean separation of concerns" 
Write-Host "✅ Easy to test PDF processor independently"
Write-Host "✅ Reusable across different applications"
Write-Host "✅ Clear interface and error handling"
Write-Host "✅ Foundation for modularizing other tools"