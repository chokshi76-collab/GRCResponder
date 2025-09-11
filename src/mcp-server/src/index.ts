import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

// Import modular tools
import { pdfProcessor, PdfProcessingParameters } from "./tools/pdf-processor.js";
import { CSVAnalyzer } from "./tools/csv-analyzer.js";
import { KnowledgeGraphSearch } from "./tools/knowledge-search.js";
import { OmnichannelJourneyAnalyzer } from "./tools/omnichannel-analyzer.js";
import { RegulatoryComplianceAnalyzer } from "./tools/compliance-analyzer.js";

// Import shared types
import { 
    CSVAnalysisParameters, 
    KnowledgeSearchParameters, 
    OmnichannelAnalysisParameters, 
    ComplianceAnalysisParameters 
} from "./shared/mcp-types.js";

// Initialize tool instances
const csvAnalyzer = new CSVAnalyzer();
const knowledgeSearch = new KnowledgeGraphSearch();
const omnichannelAnalyzer = new OmnichannelJourneyAnalyzer();
const complianceAnalyzer = new RegulatoryComplianceAnalyzer();

// Initialize all tools on startup
Promise.all([
    csvAnalyzer.initialize(),
    knowledgeSearch.initialize(), 
    omnichannelAnalyzer.initialize(),
    complianceAnalyzer.initialize()
]).then(() => {
    console.log('All MCP tools initialized successfully');
}).catch(error => {
    console.error('Error initializing MCP tools:', error);
});

// Helper function to determine architecture type
function getArchitectureType(toolName: string): string {
    const realImplementations = ['process_pdf', 'analyze_csv', 'knowledge_search', 'omnichannel_analyzer', 'compliance_analyzer'];
    return realImplementations.includes(toolName) ? 'modular_azure_ai' : 'placeholder';
}

// Define the tools that our Universal AI API supports
const AVAILABLE_TOOLS = [
    {
        name: "process_pdf",
        description: "Process PDF documents using Azure Document Intelligence to extract text, tables, and structure",
        parameters: {
            type: "object",
            properties: {
                file_path: {
                    type: "string",
                    description: "Path to the PDF file to process (URL or base64 data)"
                },
                analysis_type: {
                    type: "string",
                    enum: ["text", "tables", "layout", "comprehensive"],
                    description: "Type of analysis to perform on the PDF"
                }
            },
            required: ["file_path"]
        }
    },
    {
        name: "analyze_csv",
        description: "Advanced CSV analyzer with statistical analysis, data quality assessment, and utilities industry context detection",
        parameters: {
            type: "object",
            properties: {
                csv_data: {
                    type: "string",
                    description: "CSV content as string"
                },
                file_url: {
                    type: "string", 
                    description: "URL to CSV file"
                },
                analysis_type: {
                    type: "string",
                    enum: ["basic", "statistical", "utilities_context", "comprehensive"],
                    description: "Type of analysis to perform"
                },
                include_recommendations: {
                    type: "boolean",
                    description: "Whether to include actionable recommendations"
                }
            },
            required: []
        }
    },
    {
        name: "scrape_website",
        description: "Scrape website content using Puppeteer for regulatory document monitoring",
        parameters: {
            type: "object",
            properties: {
                url: {
                    type: "string",
                    format: "uri",
                    description: "URL of the website to scrape"
                },
                selectors: {
                    type: "array",
                    items: { type: "string" },
                    description: "CSS selectors for content to extract"
                },
                wait_for: {
                    type: "string",
                    description: "Element to wait for before scraping"
                },
                screenshot: {
                    type: "boolean",
                    description: "Whether to take a screenshot"
                }
            },
            required: ["url"]
        }
    },
    {
        name: "knowledge_search",
        description: "Semantic knowledge graph search using Azure OpenAI embeddings with relationship mapping and cross-document associations",
        parameters: {
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "Search query text"
                },
                search_type: {
                    type: "string",
                    enum: ["semantic", "keyword", "hybrid"],
                    description: "Type of search to perform"
                },
                max_results: {
                    type: "integer",
                    minimum: 1,
                    maximum: 50,
                    description: "Maximum number of results to return"
                },
                similarity_threshold: {
                    type: "number",
                    minimum: 0,
                    maximum: 1,
                    description: "Minimum similarity score for results"
                },
                document_types: {
                    type: "array",
                    items: { type: "string" },
                    description: "Filter by document types"
                },
                include_metadata: {
                    type: "boolean",
                    description: "Include document metadata in results"
                }
            },
            required: ["query"]
        }
    },
    {
        name: "omnichannel_analyzer",
        description: "Analyze customer journey across multiple channels with pattern recognition and sentiment analysis",
        parameters: {
            type: "object",
            properties: {
                customer_interactions: {
                    type: "array",
                    items: {
                        type: "object",
                        properties: {
                            customer_id: { type: "string" },
                            channel: { 
                                type: "string",
                                enum: ["web", "phone", "chat", "email", "mobile", "in_person"]
                            },
                            interaction_type: { type: "string" },
                            timestamp: { type: "string", format: "date-time" },
                            sentiment: { 
                                type: "string",
                                enum: ["positive", "neutral", "negative"] 
                            },
                            outcome: { type: "string" },
                            metadata: { type: "object" }
                        },
                        required: ["customer_id", "channel", "interaction_type", "timestamp"]
                    },
                    description: "Array of customer interaction records"
                },
                analysis_period: {
                    type: "object",
                    properties: {
                        start_date: { type: "string", format: "date-time" },
                        end_date: { type: "string", format: "date-time" }
                    },
                    description: "Analysis time period"
                },
                include_journey_mapping: {
                    type: "boolean",
                    description: "Include customer journey pattern analysis"
                },
                include_sentiment_analysis: {
                    type: "boolean", 
                    description: "Include sentiment analysis of interactions"
                }
            },
            required: ["customer_interactions"]
        }
    },
    {
        name: "compliance_analyzer",
        description: "Regulatory compliance analyzer for utilities industry including NERC CIP, EPA, and state utility regulations",
        parameters: {
            type: "object",
            properties: {
                compliance_domain: {
                    type: "string",
                    enum: ["nerc_cip", "epa_environmental", "state_utility", "comprehensive"],
                    description: "Compliance domain to analyze"
                },
                document_content: {
                    type: "string",
                    description: "Document content to analyze for compliance"
                },
                document_url: {
                    type: "string",
                    format: "uri",
                    description: "URL to document for compliance analysis"
                },
                audit_scope: {
                    type: "array",
                    items: { type: "string" },
                    description: "Specific areas to focus audit on"
                },
                include_remediation: {
                    type: "boolean",
                    description: "Include remediation recommendations"
                }
            },
            required: []
        }
    }
];

// Health check endpoint
app.http('health', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'health',
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        context.log('Health check requested');
        
        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                version: '1.0.0',
                service: 'PDF AI Agent Universal API',
                modular_architecture: 'ACTIVE',
                pdf_processor: 'Azure Document Intelligence Module'
            })
        };
    }
});

// API documentation endpoint
app.http('docs', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'docs',
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        context.log('API documentation requested');
        
        const openApiSpec = {
            openapi: '3.0.0',
            info: {
                title: 'PDF AI Agent Universal API',
                version: '1.0.0',
                description: 'Universal REST API for AI-powered document processing and analysis tools with modular architecture'
            },
            servers: [
                {
                    url: 'https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api',
                    description: 'Development server'
                }
            ],
            paths: {
                '/health': {
                    get: {
                        summary: 'Health check',
                        responses: {
                            '200': {
                                description: 'Service is healthy'
                            }
                        }
                    }
                },
                '/tools': {
                    get: {
                        summary: 'List available tools',
                        responses: {
                            '200': {
                                description: 'List of available tools'
                            }
                        }
                    }
                },
                '/tools/{name}': {
                    post: {
                        summary: 'Execute a tool',
                        parameters: [
                            {
                                name: 'name',
                                in: 'path',
                                required: true,
                                schema: { type: 'string' }
                            }
                        ],
                        responses: {
                            '200': {
                                description: 'Tool execution result'
                            }
                        }
                    }
                },
                '/websocket-negotiate': {
                    get: {
                        summary: 'WebSocket connection negotiation for real-time transparency',
                        parameters: [
                            {
                                name: 'sessionId',
                                in: 'query',
                                schema: { type: 'string' },
                                description: 'Transparency session ID'
                            },
                            {
                                name: 'userId',
                                in: 'query', 
                                schema: { type: 'string' },
                                description: 'User ID for connection'
                            }
                        ],
                        responses: {
                            '200': {
                                description: 'WebSocket connection information'
                            }
                        }
                    }
                },
                '/transparency-hub': {
                    get: {
                        summary: 'Get transparency hub status and session information',
                        responses: {
                            '200': {
                                description: 'Hub status and active sessions'
                            }
                        }
                    },
                    post: {
                        summary: 'Create new transparency session',
                        requestBody: {
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            userId: { type: 'string' }
                                        }
                                    }
                                }
                            }
                        },
                        responses: {
                            '201': {
                                description: 'New transparency session created'
                            }
                        }
                    }
                },
                '/transparency-broadcast': {
                    post: {
                        summary: 'Broadcast transparency messages in real-time',
                        requestBody: {
                            content: {
                                'application/json': {
                                    schema: {
                                        type: 'object',
                                        properties: {
                                            messageType: { 
                                                type: 'string',
                                                enum: ['agent_thought', 'tool_execution', 'processing_step', 'decision_point', 'collaboration']
                                            },
                                            sessionId: { type: 'string' },
                                            data: { type: 'object' }
                                        },
                                        required: ['messageType', 'sessionId', 'data']
                                    }
                                }
                            }
                        },
                        responses: {
                            '200': {
                                description: 'Message broadcast successfully'
                            }
                        }
                    }
                }
            },
            components: {
                schemas: {
                    PdfProcessingRequest: {
                        type: 'object',
                        properties: {
                            file_path: {
                                type: 'string',
                                description: 'URL or base64 data of PDF to process'
                            },
                            analysis_type: {
                                type: 'string',
                                enum: ['text', 'tables', 'layout', 'comprehensive']
                            }
                        },
                        required: ['file_path']
                    }
                }
            }
        };

        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(openApiSpec, null, 2)
        };
    }
});

// List available tools endpoint
app.http('tools', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'tools',
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        context.log('Tools list requested');
        
        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                tools: AVAILABLE_TOOLS,
                count: AVAILABLE_TOOLS.length,
                service: 'Universal AI Tool Platform with Real-Time Transparency',
                architecture: 'Complete MCP Implementation + WebSocket Transparency',
                real_tools: ['process_pdf', 'analyze_csv', 'knowledge_search', 'omnichannel_analyzer', 'compliance_analyzer'],
                placeholder_tools: ['scrape_website'],
                azure_integrations: 'Document Intelligence, OpenAI, AI Search, Key Vault, Cosmos DB',
                timestamp: new Date().toISOString()
            })
        };
    }
});

// Execute tool endpoint
app.http('execute-tool', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'tools/{name}',
    handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
        const toolName = request.params.name;
        context.log(`Tool execution requested: ${toolName}`);
        
        // Validate tool exists
        const tool = AVAILABLE_TOOLS.find(t => t.name === toolName);
        if (!tool) {
            return {
                status: 404,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    error: 'Tool not found',
                    available_tools: AVAILABLE_TOOLS.map(t => t.name)
                })
            };
        }

        // Parse request body
        let parameters = {};
        try {
            const bodyText = await request.text();
            if (bodyText) {
                const requestBody = JSON.parse(bodyText);
                parameters = requestBody.parameters || {};
            }
        } catch (error) {
            return {
                status: 400,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    error: 'Invalid JSON in request body',
                    details: error instanceof Error ? error.message : String(error)
                })
            };
        }

        // Execute the tool
        let result;
        try {
            switch (toolName) {
                case 'process_pdf':
                    // Use modular PDF processor with real Azure Document Intelligence
                    context.log('Using modular PDF processor with Azure Document Intelligence');
                    result = await pdfProcessor.processPdf(parameters as PdfProcessingParameters, context);
                    break;
                case 'analyze_csv':
                    context.log('Using advanced CSV analyzer with utilities context');
                    result = await csvAnalyzer.analyzeCSV(parameters as CSVAnalysisParameters, context);
                    break;
                case 'scrape_website':
                    context.log('Using web scraper - placeholder implementation');
                    result = { message: 'Web scraping functionality - placeholder implementation', status: 'placeholder' };
                    break;
                case 'knowledge_search':
                    context.log('Using knowledge graph search with Azure OpenAI embeddings');
                    result = await knowledgeSearch.searchKnowledge(parameters as KnowledgeSearchParameters, context);
                    break;
                case 'omnichannel_analyzer':
                    context.log('Using omnichannel journey analyzer');
                    result = await omnichannelAnalyzer.analyzeOmnichannelJourney(parameters as OmnichannelAnalysisParameters, context);
                    break;
                case 'compliance_analyzer':
                    context.log('Using regulatory compliance analyzer');
                    result = await complianceAnalyzer.analyzeCompliance(parameters as ComplianceAnalysisParameters, context);
                    break;
                default:
                    throw new Error(`Tool ${toolName} not implemented`);
            }

            return {
                status: 200,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    tool: toolName,
                    result: result,
                    timestamp: new Date().toISOString(),
                    status: 'success',
                    architecture: getArchitectureType(toolName)
                })
            };

        } catch (error) {
            context.error(`Error executing tool ${toolName}:`, error);
            return {
                status: 500,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    error: 'Tool execution failed',
                    tool: toolName,
                    details: error instanceof Error ? error.message : String(error),
                    timestamp: new Date().toISOString()
                })
            };
        }
    }
});

// Placeholder tool implementations (remaining tools to be modularized in future steps)
async function analyzeCsv(parameters: any, context: InvocationContext) {
    context.log('Analyzing CSV with parameters:', parameters);
    
    return {
        message: 'CSV analysis completed (placeholder)',
        file_path: parameters.file_path || 'unknown',
        table_name: parameters.table_name || 'unknown',
        rows_processed: 1000,
        columns_analyzed: 15,
        data_quality_score: 0.87,
        anomalies_detected: 3,
        status: 'placeholder_mode',
        next_steps: 'Replace with modular SQL database integration'
    };
}

async function scrapeWebsite(parameters: any, context: InvocationContext) {
    context.log('Scraping website with parameters:', parameters);
    
    return {
        message: 'Website scraping completed (placeholder)',
        url: parameters.url || 'unknown',
        content_extracted: 'Sample scraped content...',
        elements_found: parameters.selectors?.length || 0,
        screenshot_taken: parameters.screenshot || false,
        timestamp: new Date().toISOString(),
        status: 'placeholder_mode',
        next_steps: 'Replace with modular Puppeteer implementation'
    };
}

async function searchDocuments(parameters: any, context: InvocationContext) {
    context.log('Searching documents with parameters:', parameters);
    
    return {
        message: 'Document search completed (placeholder)',
        query: parameters.query || 'unknown',
        results_found: 10,
        top_k: parameters.top_k || 10,
        search_type: parameters.search_type || 'hybrid',
        results: [
            { id: '1', title: 'Sample Document 1', score: 0.95 },
            { id: '2', title: 'Sample Document 2', score: 0.87 }
        ],
        status: 'placeholder_mode',
        next_steps: 'Replace with modular Azure AI Search SDK integration'
    };
}

async function queryCsvData(parameters: any, context: InvocationContext) {
    context.log('Querying CSV data with parameters:', parameters);
    
    return {
        message: 'CSV query completed (placeholder)',
        table_name: parameters.table_name || 'unknown',
        query: parameters.query || 'unknown',
        query_type: parameters.query_type || 'natural_language',
        rows_returned: 25,
        results: [
            { column1: 'value1', column2: 'value2' },
            { column1: 'value3', column2: 'value4' }
        ],
        status: 'placeholder_mode',
        next_steps: 'Replace with modular SQL database query implementation'
    };
}