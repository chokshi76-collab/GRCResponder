// PDF AI Agent MCP Server - Azure Function App Entry Point
// Deployment timestamp: 2025-08-30 07:15:00

import { AzureFunction, Context, HttpRequest } from "@azure/functions";

// Azure Function HTTP handler
const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log('PDF AI Agent MCP Server HTTP trigger function processed a request.');

    const method = req.method?.toLowerCase();
    const path = req.params?.path || '';

    // Handle MCP protocol requests
    if (method === 'post' && path === 'tools/list') {
        context.res = {
            status: 200,
            headers: { "Content-Type": "application/json" },
            body: {
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
        return;
    }

    // Handle tool execution requests
    if (method === 'post' && path === 'tools/call') {
        const { name, arguments: args } = req.body || {};

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
                context.res = {
                    status: 400,
                    body: { error: `Unknown tool: ${name}` }
                };
                return;
        }

        context.res = {
            status: 200,
            headers: { "Content-Type": "application/json" },
            body: {
                content: [
                    {
                        type: 'text',
                        text: responseText
                    }
                ]
            }
        };
        return;
    }

    // Health check endpoint
    if (method === 'get' && !path) {
        context.res = {
            status: 200,
            headers: { "Content-Type": "application/json" },
            body: {
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
        return;
    }

    // Default response for unknown paths
    context.res = {
        status: 404,
        body: {
            error: 'Not Found',
            message: 'Available endpoints: GET /api/mcp, POST /api/mcp/tools/list, POST /api/mcp/tools/call'
        }
    };
};

export default httpTrigger;