// PDF AI Agent MCP Server - Azure Function App Entry Point
// Deployment timestamp: 2025-08-30 08:00:00

import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';

// Azure Function HTTP handler
async function httpTrigger(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('PDF AI Agent MCP Server HTTP trigger function processed a request.');

    const method = request.method.toLowerCase();
    const pathSegments = request.url.split('/');
    const path = pathSegments[pathSegments.length - 1] || '';

    // Handle MCP protocol requests
    if (method === 'post' && path === 'list') {
        return {
            status: 200,
            headers: { "Content-Type": "application/json" },
            jsonBody: {
                tools: [
                    {
                        name: 'process_pdf',
                        description: 'Process PDF documents using Azure Document Intelligence',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                pdf_url: {
                                    type: 'string',
                                    description: 'URL or path to the PDF file'
                                }
                            },
                            required: ['pdf_url']
                        }
                    },
                    {
                        name: 'analyze_csv',
                        description: 'Analyze CSV data and store in SQL database',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                csv_data: {
                                    type: 'string',
                                    description: 'CSV content to analyze'
                                }
                            },
                            required: ['csv_data']
                        }
                    },
                    {
                        name: 'scrape_website',
                        description: 'Scrape website content using Puppeteer',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                url: {
                                    type: 'string',
                                    description: 'Website URL to scrape'
                                }
                            },
                            required: ['url']
                        }
                    },
                    {
                        name: 'search_documents',
                        description: 'Search documents using Azure AI Search',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                query: {
                                    type: 'string',
                                    description: 'Search query'
                                }
                            },
                            required: ['query']
                        }
                    },
                    {
                        name: 'query_csv_data',
                        description: 'Query CSV data from SQL database',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                sql_query: {
                                    type: 'string',
                                    description: 'SQL query to execute'
                                }
                            },
                            required: ['sql_query']
                        }
                    }
                ]
            }
        };
    }

    // Handle tool execution requests
    if (method === 'post' && path === 'call') {
        const body = await request.json();
        const { name, arguments: args } = body || {};

        let responseText = '';
        switch (name) {
            case 'process_pdf':
                responseText = 'PDF processing tool - Azure Document Intelligence integration coming soon';
                break;
            case 'analyze_csv':
                responseText = 'CSV analysis tool - Azure SQL integration coming soon';
                break;
            case 'scrape_website':
                responseText = 'Web scraping tool - Puppeteer integration coming soon';
                break;
            case 'search_documents':
                responseText = 'Document search tool - Azure AI Search integration coming soon';
                break;
            case 'query_csv_data':
                responseText = 'CSV query tool - SQL database integration coming soon';
                break;
            default:
                return {
                    status: 400,
                    jsonBody: { error: `Unknown tool: ${name}` }
                };
        }

        return {
            status: 200,
            headers: { "Content-Type": "application/json" },
            jsonBody: {
                content: [
                    {
                        type: 'text',
                        text: responseText
                    }
                ]
            }
        };
    }

    // Health check endpoint
    if (method === 'get') {
        return {
            status: 200,
            headers: { "Content-Type": "application/json" },
            jsonBody: {
                status: 'healthy',
                service: 'PDF AI Agent MCP Server',
                version: '1.0.0',
                timestamp: new Date().toISOString(),
                available_endpoints: [
                    'GET /api/mcp - Health check',
                    'POST /api/mcp/tools/list - List available tools',
                    'POST /api/mcp/tools/call - Execute tool'
                ]
            }
        };
    }

    // Default response for unknown paths
    return {
        status: 404,
        jsonBody: {
            error: 'Not Found',
            message: 'Available endpoints: GET /api/mcp, POST /api/mcp/tools/list, POST /api/mcp/tools/call'
        }
    };
}

// Register the HTTP trigger
app.http('mcp', {
    methods: ['GET', 'POST'],
    route: 'mcp/{*path}',
    authLevel: 'anonymous',
    handler: httpTrigger
});