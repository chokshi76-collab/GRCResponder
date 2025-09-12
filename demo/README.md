# Universal AI Tool Platform - Frontend Demo

This directory contains the frontend demonstration interface for the Universal AI Tool Platform with real-time AI transparency.

## Demo Files

- **`enhanced-transparency-demo.html`** - Full-featured demo with live MCP backend integration
- **`transparency-demo.html`** - Original static demo with simulated data
- **`staticwebapp.config.json`** - Azure Static Web Apps configuration

## Features

### 🤖 Real-Time AI Transparency
- Live connection to MCP backend API (`https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api`)
- Real-time agent thoughts and decision-making process
- Tool execution monitoring and status updates

### 📄 Document Processing
- **PDF Processing** via Azure Document Intelligence
- **CSV Analysis** with statistical insights
- **File upload** with drag-and-drop interface

### 🎯 Scenario-Based Demonstrations
- **Compliance Analysis** - NERC CIP, EPA regulations
- **Financial Processing** - Financial document analysis  
- **Operations Data** - Operational metrics processing
- **Customer Journey** - Customer interaction analysis

### 🛠️ MCP Tools Integration
All 6 production MCP tools:
1. `process_pdf` - Azure Document Intelligence
2. `analyze_csv` - Statistical analysis
3. `knowledge_search` - Semantic search
4. `omnichannel_analyzer` - Customer journey analysis
5. `compliance_analyzer` - Regulatory compliance
6. `scrape_website` - Web scraping (Puppeteer)

## Local Development

### Quick Start
```bash
# Serve locally for testing
cd demo
python -m http.server 8080

# Access demo at:
# http://localhost:8080/enhanced-transparency-demo.html
```

### Testing Backend Connection
The demo automatically tests connection to the live MCP backend API:
- Health check: `/api/health`
- Tools list: `/api/tools`
- Tool execution: `/api/tools/{name}`

## Azure Deployment

### Infrastructure as Code (IaC)
- **Static Web App**: `../infrastructure/bicep/static-web-app.bicep`
- **CI/CD Pipeline**: `../.github/workflows/deploy-frontend.yml`

### Deployment Process
1. **Infrastructure Deployment** - Creates Azure Static Web App
2. **Content Deployment** - Deploys HTML/CSS/JS files
3. **Automatic SSL** - HTTPS enabled by default
4. **Custom Domain** - Configurable via Azure portal

## API Integration

### Backend Endpoints
```javascript
const API_BASE_URL = 'https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api';

// Health check
GET /health

// List available tools
GET /tools

// Execute tool
POST /tools/{toolName}
```

### CORS Configuration
The backend is configured to allow requests from:
- `https://portal.azure.com` (for testing)
- Static Web App domains (automatically configured)

## Demo Scenarios

### 1. Compliance Analysis Demo
1. Upload a PDF regulatory document
2. Watch AI agents analyze document structure
3. See real-time compliance checking
4. View generated remediation recommendations

### 2. Data Processing Demo
1. Upload CSV data file
2. Observe statistical analysis process
3. View data quality assessment
4. See actionable insights generation

### 3. Multi-Tool Orchestration
1. Upload mixed document types
2. Watch AI orchestrator decide tool sequence
3. See agent collaboration in real-time
4. View integrated analysis results

## Enterprise Features

- **🔒 Security**: HTTPS, CORS, security headers
- **📊 Monitoring**: API call tracking, tool status
- **🎯 Scalability**: Azure Static Web Apps CDN
- **🔄 CI/CD**: Automated deployment pipeline
- **📱 Responsive**: Works on desktop, tablet, mobile

## Development Notes

### File Structure
```
demo/
├── enhanced-transparency-demo.html    # Main demo interface
├── transparency-demo.html            # Original static demo
├── staticwebapp.config.json          # SWA configuration
└── README.md                         # This file
```

### API Integration Points
- Connection testing on page load
- Real-time tool status updates
- Live API response display
- Error handling and user feedback

### Styling & UX
- Modern CSS Grid layout
- Responsive design patterns
- Real-time animations
- Professional enterprise styling