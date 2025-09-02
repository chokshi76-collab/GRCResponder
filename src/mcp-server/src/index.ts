import { Context, HttpRequest, HttpResponseInit } from "@azure/functions";

// API Response interface for consistent formatting
interface ApiResponse<T = any> {
    success: boolean;
    data?: T;
    error?: string;
    timestamp: string;
    requestId?: string;
}

// Tool definition interface
interface Tool {
    name: string;
    description: string;
    parameters: {
        type: string;
        properties: Record<string, any>;
        required: string[];
    };
    examples: Array<{
        input: Record<string, any>;
        description: string;
    }>;
}

// Universal Tool Definitions
const TOOLS: Tool[] = [
    {
        name: "process_pdf",
        description: "Process PDF documents using Azure Document Intelligence to extract text, tables, forms, and document structure",
        parameters: {
            type: "object",
            properties: {
                pdf_url: {
                    type: "string",
                    description: "URL or path to the PDF file to process"
                },
                analysis_type: {
                    type: "string",
                    enum: ["layout", "document", "prebuilt-document", "prebuilt-invoice", "prebuilt-receipt"],
                    default: "document",
                    description: "Type of analysis to perform on the PDF"
                }
            },
            required: ["pdf_url"]
        },
        examples: [
            {
                input: { pdf_url: "https://example.com/document.pdf", analysis_type: "document" },
                description: "Extract all text and structure from a general document"
            },
            {
                input: { pdf_url: "https://example.com/invoice.pdf", analysis_type: "prebuilt-invoice" },
                description: "Process an invoice with specialized field extraction"
            }
        ]
    },
    {
        name: "analyze_csv",
        description: "Analyze CSV data, perform statistical analysis, and store results in SQL database for querying",
        parameters: {
            type: "object",
            properties: {
                csv_data: {
                    type: "string",
                    description: "CSV content as string or base64 encoded data"
                },
                table_name: {
                    type: "string",
                    description: "Name for the database table to store results",
                    pattern: "^[a-zA-Z][a-zA-Z0-9_]*$"
                },
                analysis_options: {
                    type: "object",
                    properties: {
                        perform_stats: { type: "boolean", default: true },
                        detect_types: { type: "boolean", default: true },
                        clean_data: { type: "boolean", default: true },
                    }
                }
            },
            required: ["csv_data"]
        },
        examples: [
            {
                input: {
                    csv_data: "name,age,salary\nJohn,30,50000\nJane,25,60000",
                    table_name: "employees",
                    analysis_options: { perform_stats: true }
                },
                description: "Analyze employee data and store with statistics"
            }
        ]
    },
    {
        name: "scrape_website",
        description: "Scrape website content using Puppeteer for compliance monitoring and document collection",
        parameters: {
            type: "object",
            properties: {
                url: {
                    type: "string",
                    format: "uri",
                    description: "Website URL to scrape"
                },
                selectors: {
                    type: "array",
                    items: { type: "string" },
                    description: "CSS selectors to extract specific content"
                },
                options: {
                    type: "object",
                    properties: {
                        wait_for: { type: "string", description: "CSS selector to wait for before scraping" },
                        screenshot: { type: "boolean", default: false },
                        pdf_export: { type: "boolean", default: false },
                        follow_links: { type: "boolean", default: false }
                    }
                }
            },
            required: ["url"]
        },
        examples: [
            {
                input: {
                    url: "https://example.com/regulations",
                    selectors: [".regulation-text", ".update-date"],
                    options: { screenshot: true }
                },
                description: "Scrape regulatory content with screenshot"
            }
        ]
    },
    {
        name: "search_documents",
        description: "Search processed documents using Azure AI Search with vector similarity and semantic search",
        parameters: {
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "Natural language search query"
                },
                filters: {
                    type: "object",
                    properties: {
                        document_type: { type: "string" },
                        date_range: {
                            type: "object",
                            properties: {
                                start: { type: "string", format: "date" },
                                end: { type: "string", format: "date" }
                            }
                        },
                        source: { type: "string" }
                    }
                },
                options: {
                    type: "object",
                    properties: {
                        top: { type: "integer", minimum: 1, maximum: 50, default: 10 },
                        include_highlights: { type: "boolean", default: true },
                        semantic_search: { type: "boolean", default: true },
                    }
                }
            },
            required: ["query"]
        },
        examples: [
            {
                input: {
                    query: "data privacy compliance requirements",
                    filters: { document_type: "regulation" },
                    options: { top: 5, semantic_search: true }
                },
                description: "Search for privacy regulations with semantic understanding"
            }
        ]
    },
    {
        name: "query_csv_data",
        description: "Query structured CSV data from SQL database using natural language or SQL",
        parameters: {
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "Natural language question or SQL query"
                },
                table_name: {
                    type: "string",
                    description: "Name of the table to query"
                },
                query_type: {
                    type: "string",
                    enum: ["natural_language", "sql"],
                    default: "natural_language",
                    description: "Type of query - natural language or direct SQL"
                },
                options: {
                    type: "object",
                    properties: {
                        limit: { type: "integer", minimum: 1, maximum: 1000, default: 100 },
                        format: { type: "string", enum: ["json", "csv", "table"], default: "json" }
                    }
                }
            },
            required: ["query"]
        },
        examples: [
            {
                input: {
                    query: "What is the average salary by department?",
                    table_name: "employees",
                    query_type: "natural_language"
                },
                description: "Natural language query for salary analysis"
            },
            {
                input: {
                    query: "SELECT department, AVG(salary) FROM employees GROUP BY department",
                    query_type: "sql"
                },
                description: "Direct SQL query for salary analysis"
            }
        ]
    }
];

// Utility function to create consistent API responses
function createResponse<T>(
    success: boolean,
    data?: T,
    error?: string,
    status: number = 200,
    requestId?: string
): HttpResponseInit {
    const response: ApiResponse<T> = {
        success,
        data,
        error,
        timestamp: new Date().toISOString(),
        requestId
    };

    return {
        status,
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        },
        body: JSON.stringify(response, null, 2)
    };
}

// API Documentation endpoint
export async function apiDocs(request: HttpRequest, context: Context): Promise<HttpResponseInit> {
    const openApiSpec = {
        openapi: "3.0.0",
        info: {
            title: "PDF AI Agent - Universal AI Tool Platform",
            version: "1.0.0",
            description: "Universal REST API for AI-powered document processing, compliance monitoring, and data analysis. Compatible with any AI model or application.",
            contact: {
                name: "PDF AI Agent API",
                url: "https://github.com/chokshi76-collab/GRCResponder"
            }
        },
        servers: [
            {
                url: "https://func-pdfai-dev-tjqwgu4v.azurewebsites.net/api",
                description: "Development Environment"
            }
        ],
        paths: {
            "/tools": {
                get: {
                    summary: "List all available tools",
                    description: "Returns a list of all available AI tools with their descriptions and parameters",
                    responses: {
                        "200": {
                            description: "List of available tools",
                            content: {
                                "application/json": {
                                    schema: {
                                        type: "object",
                                        properties: {
                                            success: { type: "boolean" },
                                            data: {
                                                type: "object",
                                                properties: {
                                                    tools: {
                                                        type: "array",
                                                        items: { $ref: "#/components/schemas/Tool" }
                                                    },
                                                    total_count: { type: "integer" }
                                                }
                                            },
                                            timestamp: { type: "string", format: "date-time" }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/tools/{toolName}": {
                post: {
                    summary: "Execute a specific tool",
                    description: "Execute any of the available AI tools with the provided parameters",
                    parameters: [
                        {
                            name: "toolName",
                            in: "path",
                            required: true,
                            schema: { type: "string" },
                            description: "Name of the tool to execute"
                        }
                    ],
                    requestBody: {
                        required: true,
                        content: {
                            "application/json": {
                                schema: {
                                    type: "object",
                                    description: "Tool-specific parameters"
                                }
                            }
                        }
                    },
                    responses: {
                        "200": {
                            description: "Tool execution result",
                            content: {
                                "application/json": {
                                    schema: { $ref: "#/components/schemas/ApiResponse" }
                                }
                            }
                        },
                        "400": {
                            description: "Invalid parameters or tool not found"
                        },
                        "500": {
                            description: "Internal server error"
                        }
                    }
                }
            }
        },
        components: {
            schemas: {
                Tool: {
                    type: "object",
                    properties: {
                        name: { type: "string" },
                        description: { type: "string" },
                        parameters: { type: "object" },
                        examples: {
                            type: "array",
                            items: {
                                type: "object",
                                properties: {
                                    input: { type: "object" },
                                    description: { type: "string" }
                                }
                            }
                        }
                    }
                },
                ApiResponse: {
                    type: "object",
                    properties: {
                        success: { type: "boolean" },
                        data: { type: "object" },
                        error: { type: "string" },
                        timestamp: { type: "string", format: "date-time" },
                        requestId: { type: "string" }
                    }
                }
            }
        }
    };

    return createResponse(true, openApiSpec);
}

// List all tools endpoint
export async function listTools(request: HttpRequest, context: Context): Promise<HttpResponseInit> {
    try {
        const toolsData = {
            tools: TOOLS,
            total_count: TOOLS.length,
            categories: ["document_processing", "data_analysis", "web_scraping", "search", "database"],
            api_version: "1.0.0"
        };

        return createResponse(true, toolsData, undefined, 200, context.invocationId);
    } catch (error) {
        return createResponse(false, null, `Failed to list tools: ${error.message}`, 500, context.invocationId);
    }
}

// Execute tool endpoint
export async function executeTool(request: HttpRequest, context: Context): Promise<HttpResponseInit> {
    try {
        const toolName = context.bindingData?.toolName;
        const requestBody = await request.json() || {};

        // Find the requested tool
        const tool = TOOLS.find(t => t.name === toolName);
        if (!tool) {
            return createResponse(false, null, `Tool '${toolName}' not found. Available tools: ${TOOLS.map(t => t.name).join(', ')}`, 404, context.invocationId);
        }

        // Execute tool logic (placeholder implementations ready for Azure SDK integration)
        let result: any;

        switch (toolName) {
            case "process_pdf":
                result = {
                    tool: "process_pdf",
                    status: "ready_for_implementation",
                    input: requestBody,
                    message: "PDF processing endpoint ready for Azure Document Intelligence SDK integration",
                    next_steps: [
                        "Install @azure/ai-form-recognizer package",
                        "Implement Document Intelligence client",
                        "Add PDF analysis logic",
                        "Return structured document data"
                    ],
                    placeholder_response: {
                        document_id: `doc_${Date.now()}`,
                        pages: 1,
                        extracted_text: "Sample extracted text would appear here...",
                        tables_found: 0,
                        forms_found: 0,
                        confidence_score: 0.95
                    }
                };
                break;

            case "analyze_csv":
                result = {
                    tool: "analyze_csv",
                    status: "ready_for_implementation",
                    input: requestBody,
                    message: "CSV analysis endpoint ready for SQL database integration",
                    next_steps: [
                        "Install mssql package",
                        "Implement database connection",
                        "Add CSV parsing and analysis",
                        "Store results in SQL database"
                    ],
                    placeholder_response: {
                        table_created: requestBody.table_name || "csv_data_" + Date.now(),
                        rows_processed: 100,
                        columns_detected: 5,
                        data_types: { "id": "integer", "name": "string", "value": "number" },
                        statistics: { "mean_value": 42.5, "max_value": 100, "min_value": 1 }
                    }
                };
                break;

            case "scrape_website":
                result = {
                    tool: "scrape_website",
                    status: "ready_for_implementation",
                    input: requestBody,
                    message: "Web scraping endpoint ready for Puppeteer integration",
                    next_steps: [
                        "Install puppeteer package",
                        "Implement browser automation",
                        "Add content extraction logic",
                        "Return scraped data"
                    ],
                    placeholder_response: {
                        url_scraped: requestBody.url,
                        content_length: 1024,
                        elements_found: 15,
                        screenshot_url: "https://example.com/screenshot.png",
                        scraped_at: new Date().toISOString()
                    }
                };
                break;

            case "search_documents":
                result = {
                    tool: "search_documents",
                    status: "ready_for_implementation",
                    input: requestBody,
                    message: "Document search endpoint ready for Azure AI Search integration",
                    next_steps: [
                        "Install @azure/search-documents package",
                        "Implement search client",
                        "Add vector similarity search",
                        "Return ranked results"
                    ],
                    placeholder_response: {
                        query: requestBody.query,
                        results_found: 5,
                        results: [
                            { document_id: "doc1", title: "Sample Document", score: 0.89, highlights: ["relevant text..."] },
                            { document_id: "doc2", title: "Another Document", score: 0.76, highlights: ["matching content..."] }
                        ],
                        search_time_ms: 45
                    }
                };
                break;

            case "query_csv_data":
                result = {
                    tool: "query_csv_data",
                    status: "ready_for_implementation",
                    input: requestBody,
                    message: "CSV querying endpoint ready for SQL database integration",
                    next_steps: [
                        "Implement natural language to SQL conversion",
                        "Add database query execution",
                        "Format results based on requested format",
                        "Return query results"
                    ],
                    placeholder_response: {
                        query_executed: requestBody.query,
                        sql_generated: "SELECT * FROM table WHERE condition",
                        rows_returned: 10,
                        execution_time_ms: 23,
                        data: [
                            { id: 1, name: "Sample Row 1", value: 100 },
                            { id: 2, name: "Sample Row 2", value: 200 }
                        ]
                    }
                };
                break;

            default:
                return createResponse(false, null, `Tool '${toolName}' not implemented`, 501, context.invocationId);
        }

        return createResponse(true, result, undefined, 200, context.invocationId);

    } catch (error) {
        return createResponse(false, null, `Tool execution failed: ${error.message}`, 500, context.invocationId);
    }
}

// Health check endpoint
export async function healthCheck(request: HttpRequest, context: Context): Promise<HttpResponseInit> {
    const healthData = {
        status: "healthy",
        service: "PDF AI Agent Universal API",
        version: "1.0.0",
        environment: "development",
        tools_available: TOOLS.length,
        azure_services: {
            document_intelligence: "configured",
            ai_search: "configured",
            sql_database: "configured",
            storage_account: "configured",
            key_vault: "configured"
        },
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    };

    return createResponse(true, healthData, undefined, 200, context.invocationId);
}