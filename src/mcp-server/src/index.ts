import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

// Import modular PDF processor
import { pdfProcessor, PdfProcessingParameters } from "./tools/pdf-processor.js";

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
        description: "Analyze CSV data and store results in SQL database with intelligent data profiling",
        parameters: {
            type: "object",
            properties: {
                file_path: {
                    type: "string",
                    description: "Path to the CSV file to analyze"
                },
                table_name: {
                    type: "string",
                    description: "Name for the database table to store results"
                },
                analysis_options: {
                    type: "array",
                    items: {
                        type: "string",
                        enum: ["statistics", "data_quality", "patterns", "outliers"]
                    },
                    description: "Types of analysis to perform"
                }
            },
            required: ["file_path", "table_name"]
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
        name: "search_documents",
        description: "Search documents using Azure AI Search with vector similarity and semantic search",
        parameters: {
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "Search query text"
                },
                filters: {
                    type: "object",
                    description: "Search filters to apply"
                },
                top_k: {
                    type: "integer",
                    minimum: 1,
                    maximum: 100,
                    description: "Number of results to return"
                },
                search_type: {
                    type: "string",
                    enum: ["vector", "text", "hybrid"],
                    description: "Type of search to perform"
                }
            },
            required: ["query"]
        }
    },
    {
        name: "query_csv_data",
        description: "Query CSV data stored in SQL database using natural language",
        parameters: {
            type: "object",
            properties: {
                table_name: {
                    type: "string",
                    description: "Name of the database table to query"
                },
                query: {
                    type: "string",
                    description: "Natural language query or SQL query"
                },
                query_type: {
                    type: "string",
                    enum: ["natural_language", "sql"],
                    description: "Type of query being provided"
                }
            },
            required: ["table_name", "query"]
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
                service: 'PDF AI Agent Universal API'
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
                description: 'Universal REST API for AI-powered document processing and analysis tools'
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
                service: 'PDF AI Agent Universal API',
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
                    // Use modular PDF processor
                    result = await pdfProcessor.processPdf(parameters as PdfProcessingParameters, context);
                    break;
                case 'analyze_csv':
                    result = await analyzeCsv(parameters, context);
                    break;
                case 'scrape_website':
                    result = await scrapeWebsite(parameters, context);
                    break;
                case 'search_documents':
                    result = await searchDocuments(parameters, context);
                    break;
                case 'query_csv_data':
                    result = await queryCsvData(parameters, context);
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
                    status: 'success'
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
        next_steps: 'Replace with SQL database integration'
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
        next_steps: 'Replace with Puppeteer implementation'
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
        next_steps: 'Replace with Azure AI Search SDK integration'
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
        next_steps: 'Replace with SQL database query implementation'
    };
}