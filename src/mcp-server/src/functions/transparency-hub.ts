// src/functions/transparency-hub.ts
// Azure Functions SignalR Hub for Real-time AI Transparency Broadcasting

import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { TransparencyLogger } from "../shared/transparency-logger.js";
import { TransparencyMessage } from "../shared/mcp-types.js";

export async function transparencyHub(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('Transparency Hub request received');

    try {
        const method = request.method.toUpperCase();

        // Handle CORS preflight
        if (method === 'OPTIONS') {
            return {
                status: 200,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id, x-session-id'
                }
            };
        }

        // GET: Get hub status and active sessions
        if (method === 'GET') {
            const transparencyLogger = TransparencyLogger.getInstance();
            const sessionId = request.query.get('sessionId');

            if (sessionId) {
                const sessionStats = transparencyLogger.getSessionStats(sessionId);
                if (!sessionStats) {
                    return {
                        status: 404,
                        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                        jsonBody: {
                            status: 'error',
                            message: 'Session not found',
                            sessionId
                        }
                    };
                }

                return {
                    status: 200,
                    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                    jsonBody: {
                        status: 'success',
                        message: 'Session stats retrieved',
                        session: sessionStats,
                        timestamp: new Date().toISOString()
                    }
                };
            }

            // Return hub status
            return {
                status: 200,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                jsonBody: {
                    status: 'success',
                    message: 'Transparency Hub is active',
                    activeSessionCount: transparencyLogger.getActiveSessionCount(),
                    hubName: 'transparency',
                    timestamp: new Date().toISOString(),
                    endpoints: {
                        negotiate: '/api/websocket-negotiate',
                        hub: '/api/transparency-hub',
                        broadcast: '/api/transparency-broadcast'
                    }
                }
            };
        }

        // POST: Create new transparency session
        if (method === 'POST') {
            const transparencyLogger = TransparencyLogger.getInstance();
            const body = await request.json() as any;
            const userId = body.userId || request.headers.get('x-user-id');

            const sessionId = transparencyLogger.createSession(userId);

            context.log(`Created new transparency session: ${sessionId} for user: ${userId}`);

            return {
                status: 201,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                jsonBody: {
                    status: 'success',
                    message: 'Transparency session created',
                    sessionId,
                    userId,
                    timestamp: new Date().toISOString(),
                    websocketUrl: `/api/websocket-negotiate?sessionId=${sessionId}&userId=${userId}`
                }
            };
        }

        return {
            status: 405,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            jsonBody: {
                status: 'error',
                message: 'Method not allowed',
                allowedMethods: ['GET', 'POST', 'OPTIONS']
            }
        };

    } catch (error) {
        context.error('Transparency Hub error:', error);
        
        return {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            jsonBody: {
                status: 'error',
                message: 'Transparency Hub error',
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            }
        };
    }
}

// Register the Azure Function
app.http('transparency-hub', {
    methods: ['GET', 'POST', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'transparency-hub',
    handler: transparencyHub,
});