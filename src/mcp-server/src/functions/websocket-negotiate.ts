// src/functions/websocket-negotiate.ts
// Azure Functions SignalR Connection Negotiation Endpoint

import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

export async function websocketNegotiate(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('WebSocket negotiation request received');

    try {
        // Extract user ID from query parameters or headers if needed
        const userId = request.query.get('userId') || request.headers.get('x-user-id');
        const sessionId = request.query.get('sessionId') || `session_${Date.now()}`;

        context.log(`Negotiating connection for user: ${userId}, session: ${sessionId}`);

        // The SignalR connection info will be provided by the Azure Functions SignalR binding
        // This is handled automatically by the runtime when we have the signalRConnectionInfo input binding
        
        // Return success - the actual connection info is handled by the binding
        return {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-user-id'
            },
            jsonBody: {
                status: 'success',
                message: 'WebSocket negotiation completed',
                sessionId: sessionId,
                userId: userId,
                timestamp: new Date().toISOString(),
                endpoints: {
                    transparency: '/api/transparency-hub',
                    negotiate: '/api/websocket-negotiate'
                }
            }
        };

    } catch (error) {
        context.error('WebSocket negotiation failed:', error);
        
        return {
            status: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            jsonBody: {
                status: 'error',
                message: 'WebSocket negotiation failed',
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            }
        };
    }
}

// Register the Azure Function
app.http('websocket-negotiate', {
    methods: ['GET', 'POST', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'websocket-negotiate',
    extraInputs: [
        {
            type: 'signalRConnectionInfo',
            name: 'connectionInfo',
            hubName: 'transparency',
            direction: 'in'
        }
    ],
    handler: websocketNegotiate,
});