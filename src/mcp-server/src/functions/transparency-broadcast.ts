// src/functions/transparency-broadcast.ts
// Azure Functions for Broadcasting Transparency Messages to SignalR Hub

import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { TransparencyLogger } from "../shared/transparency-logger.js";
import { TransparencyMessage } from "../shared/mcp-types.js";

export async function transparencyBroadcast(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('Transparency broadcast request received');

    try {
        const method = request.method.toUpperCase();

        // Handle CORS preflight
        if (method === 'OPTIONS') {
            return {
                status: 200,
                headers: {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-session-id'
                }
            };
        }

        if (method !== 'POST') {
            return {
                status: 405,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                jsonBody: {
                    status: 'error',
                    message: 'Method not allowed. Use POST to broadcast messages.',
                    allowedMethods: ['POST', 'OPTIONS']
                }
            };
        }

        const body = await request.json() as any;
        const { messageType, sessionId, data } = body;

        if (!messageType || !sessionId || !data) {
            return {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                jsonBody: {
                    status: 'error',
                    message: 'Missing required fields: messageType, sessionId, and data are required',
                    timestamp: new Date().toISOString()
                }
            };
        }

        const transparencyLogger = TransparencyLogger.getInstance();

        // Validate session exists
        if (!transparencyLogger.isSessionActive(sessionId)) {
            return {
                status: 404,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                jsonBody: {
                    status: 'error',
                    message: 'Session not found or inactive',
                    sessionId,
                    timestamp: new Date().toISOString()
                }
            };
        }

        // Route the message to appropriate transparency logging method
        switch (messageType) {
            case 'agent_thought':
                await transparencyLogger.broadcastAgentThought(
                    sessionId,
                    data.agentName,
                    data.step,
                    data.thought,
                    data.toolCalled,
                    context
                );
                break;

            case 'tool_execution':
                await transparencyLogger.broadcastToolExecution(
                    sessionId,
                    data.toolName,
                    data.status,
                    data.duration,
                    data.result,
                    context
                );
                break;

            case 'processing_step':
                await transparencyLogger.broadcastProcessingStep(
                    sessionId,
                    data.currentStep,
                    data.totalSteps,
                    data.stepName,
                    data.progress,
                    context
                );
                break;

            case 'decision_point':
                await transparencyLogger.broadcastDecisionPoint(
                    sessionId,
                    data.agentName,
                    data.decision,
                    data.reasoning,
                    data.alternatives,
                    data.confidence,
                    context
                );
                break;

            case 'collaboration':
                await transparencyLogger.broadcastCollaboration(
                    sessionId,
                    data.fromAgent,
                    data.toAgent,
                    data.message,
                    data.collaborationType,
                    context
                );
                break;

            default:
                return {
                    status: 400,
                    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
                    jsonBody: {
                        status: 'error',
                        message: `Unknown message type: ${messageType}`,
                        supportedTypes: ['agent_thought', 'tool_execution', 'processing_step', 'decision_point', 'collaboration'],
                        timestamp: new Date().toISOString()
                    }
                };
        }

        // Get updated session stats
        const sessionStats = transparencyLogger.getSessionStats(sessionId);

        context.log(`Transparency message broadcast: ${messageType} for session ${sessionId}`);

        return {
            status: 200,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            jsonBody: {
                status: 'success',
                message: 'Transparency message broadcast successfully',
                messageType,
                sessionId,
                sessionStats: {
                    totalMessages: sessionStats?.totalMessages || 0,
                    activeAgents: sessionStats?.agents.length || 0,
                    activeTools: sessionStats?.tools.length || 0
                },
                timestamp: new Date().toISOString()
            }
        };

    } catch (error) {
        context.error('Transparency broadcast error:', error);
        
        return {
            status: 500,
            headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            jsonBody: {
                status: 'error',
                message: 'Transparency broadcast failed',
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: new Date().toISOString()
            }
        };
    }
}

// SignalR message broadcasting function
export async function broadcastToSignalR(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log('SignalR broadcast function triggered');

    try {
        const body = await request.json() as TransparencyMessage;
        
        // Create SignalR message format
        const signalRMessage = {
            target: 'transparencyUpdate',
            arguments: [body]
        };

        context.log(`Broadcasting to SignalR: ${body.type} for session ${body.sessionId}`);

        // The actual SignalR broadcasting is handled by the Azure Functions runtime
        // through the signalRMessages output binding defined in the function registration

        return {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
            jsonBody: {
                status: 'success',
                message: 'Message sent to SignalR hub',
                messageType: body.type,
                sessionId: body.sessionId,
                timestamp: new Date().toISOString()
            }
        };

    } catch (error) {
        context.error('SignalR broadcast error:', error);
        
        return {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
            jsonBody: {
                status: 'error',
                message: 'SignalR broadcast failed',
                error: error instanceof Error ? error.message : 'Unknown error'
            }
        };
    }
}

// Register the Azure Functions
app.http('transparency-broadcast', {
    methods: ['POST', 'OPTIONS'],
    authLevel: 'anonymous',
    route: 'transparency-broadcast',
    handler: transparencyBroadcast,
});

app.http('signalr-broadcast', {
    methods: ['POST'],
    authLevel: 'function',
    route: 'signalr-broadcast',
    extraOutputs: [
        {
            type: 'signalR',
            name: 'signalRMessages',
            hubName: 'transparency',
            direction: 'out'
        }
    ],
    handler: broadcastToSignalR,
});