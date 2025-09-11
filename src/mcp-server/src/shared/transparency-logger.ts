// src/shared/transparency-logger.ts
// Real-time AI Transparency Logger for WebSocket Broadcasting

import { InvocationContext } from "@azure/functions";
import { v4 as uuidv4 } from 'uuid';
import { 
    TransparencyMessage, 
    AgentThoughtMessage, 
    ToolExecutionMessage, 
    ProcessingStepMessage,
    DecisionPointMessage,
    CollaborationMessage,
    TransparencyConfig,
    TransparencySession,
    WebSocketConnectionInfo
} from './mcp-types.js';

export class TransparencyLogger {
    private static instance: TransparencyLogger;
    private config: TransparencyConfig;
    private activeSessions: Map<string, TransparencySession> = new Map();
    private connections: Map<string, WebSocketConnectionInfo> = new Map();
    private messageQueue: TransparencyMessage[] = [];
    private signalRConnectionString?: string;

    private constructor() {
        this.config = this.loadConfig();
        this.initializeSignalR();
    }

    public static getInstance(): TransparencyLogger {
        if (!TransparencyLogger.instance) {
            TransparencyLogger.instance = new TransparencyLogger();
        }
        return TransparencyLogger.instance;
    }

    private loadConfig(): TransparencyConfig {
        return {
            logLevel: (process.env.TRANSPARENCY_LOG_LEVEL as any) || 'detailed',
            enableAgentThoughts: true,
            enableToolExecution: true,
            enableProcessingSteps: true,
            enableDecisionPoints: true,
            enableCollaboration: true,
            maxSessionDuration: 60, // 60 minutes
            messageThrottling: {
                enabled: true,
                maxMessagesPerSecond: 10
            }
        };
    }

    private async initializeSignalR(): Promise<void> {
        try {
            this.signalRConnectionString = process.env.AZURE_SIGNALR_CONNECTION_STRING;
            if (!this.signalRConnectionString) {
                console.warn('Azure SignalR connection string not found. Transparency logging will be disabled.');
            }
        } catch (error) {
            console.error('Failed to initialize SignalR:', error);
        }
    }

    // ========================================
    // Session Management
    // ========================================

    public createSession(userId?: string): string {
        const sessionId = uuidv4();
        const session: TransparencySession = {
            sessionId,
            userId,
            startTime: new Date().toISOString(),
            status: 'active',
            totalMessages: 0,
            agents: [],
            tools: []
        };
        
        this.activeSessions.set(sessionId, session);
        return sessionId;
    }

    public endSession(sessionId: string): void {
        const session = this.activeSessions.get(sessionId);
        if (session) {
            session.status = 'completed';
            session.endTime = new Date().toISOString();
            // Keep session data for audit trail but remove from active sessions
            setTimeout(() => {
                this.activeSessions.delete(sessionId);
            }, 60000); // Keep for 1 minute after completion
        }
    }

    public getSession(sessionId: string): TransparencySession | undefined {
        return this.activeSessions.get(sessionId);
    }

    // ========================================
    // Message Broadcasting
    // ========================================

    public async broadcastAgentThought(
        sessionId: string, 
        agentName: string, 
        step: string, 
        thought: string, 
        toolCalled?: string,
        context?: InvocationContext
    ): Promise<void> {
        if (!this.config.enableAgentThoughts) return;

        const message: AgentThoughtMessage = {
            type: 'agent_thought',
            sessionId,
            agentName,
            step,
            thought,
            timestamp: new Date().toISOString(),
            toolCalled,
            metadata: {
                logLevel: this.config.logLevel
            }
        };

        await this.broadcastMessage(message, context);
        this.updateSessionStats(sessionId, agentName);
    }

    public async broadcastToolExecution(
        sessionId: string,
        toolName: string,
        status: 'starting' | 'processing' | 'complete' | 'error',
        duration?: number,
        result?: any,
        context?: InvocationContext
    ): Promise<void> {
        if (!this.config.enableToolExecution) return;

        const message: ToolExecutionMessage = {
            type: 'tool_execution',
            sessionId,
            toolName,
            status,
            duration,
            result: this.sanitizeResult(result),
            timestamp: new Date().toISOString(),
            metadata: {
                logLevel: this.config.logLevel
            }
        };

        await this.broadcastMessage(message, context);
        this.updateSessionStats(sessionId, undefined, toolName);
    }

    public async broadcastProcessingStep(
        sessionId: string,
        currentStep: number,
        totalSteps: number,
        stepName: string,
        progress: number,
        context?: InvocationContext
    ): Promise<void> {
        if (!this.config.enableProcessingSteps) return;

        const message: ProcessingStepMessage = {
            type: 'processing_step',
            sessionId,
            currentStep,
            totalSteps,
            stepName,
            progress,
            timestamp: new Date().toISOString(),
            metadata: {
                logLevel: this.config.logLevel
            }
        };

        await this.broadcastMessage(message, context);
    }

    public async broadcastDecisionPoint(
        sessionId: string,
        agentName: string,
        decision: string,
        reasoning: string,
        alternatives: string[],
        confidence: number,
        context?: InvocationContext
    ): Promise<void> {
        if (!this.config.enableDecisionPoints) return;

        const message: DecisionPointMessage = {
            type: 'decision_point',
            sessionId,
            agentName,
            decision,
            reasoning,
            alternatives,
            confidence,
            timestamp: new Date().toISOString()
        };

        await this.broadcastMessage(message, context);
        this.updateSessionStats(sessionId, agentName);
    }

    public async broadcastCollaboration(
        sessionId: string,
        fromAgent: string,
        toAgent: string,
        message: string,
        collaborationType: 'request' | 'response' | 'handoff' | 'consultation',
        context?: InvocationContext
    ): Promise<void> {
        if (!this.config.enableCollaboration) return;

        const collabMessage: CollaborationMessage = {
            type: 'collaboration',
            sessionId,
            fromAgent,
            toAgent,
            message,
            collaborationType,
            timestamp: new Date().toISOString()
        };

        await this.broadcastMessage(collabMessage, context);
        this.updateSessionStats(sessionId, fromAgent);
        this.updateSessionStats(sessionId, toAgent);
    }

    // ========================================
    // Internal Broadcasting Logic
    // ========================================

    private async broadcastMessage(message: TransparencyMessage, context?: InvocationContext): Promise<void> {
        try {
            // Apply message throttling
            if (this.config.messageThrottling.enabled) {
                if (!this.shouldAllowMessage()) {
                    context?.log(`Message throttled: ${message.type}`);
                    return;
                }
            }

            // Queue message for potential batching
            this.messageQueue.push(message);

            // Broadcast immediately for now (can be optimized later with batching)
            await this.sendToSignalR(message, context);

            context?.log(`Transparency message broadcast: ${message.type} for session ${message.sessionId}`);
        } catch (error) {
            context?.error('Failed to broadcast transparency message:', error);
        }
    }

    private async sendToSignalR(message: TransparencyMessage, context?: InvocationContext): Promise<void> {
        try {
            if (!this.signalRConnectionString) {
                context?.warn('SignalR not configured, storing message for offline processing');
                return;
            }

            // Use Azure Functions SignalR output binding
            // This will be handled by the calling Azure Function with SignalR output binding
            context?.log(`Broadcasting to SignalR hub: transparency, message type: ${message.type}`);
            
            // The actual SignalR broadcast will be handled by the calling function
            // using the signalRMessages output binding
        } catch (error) {
            context?.error('SignalR broadcast failed:', error);
        }
    }

    private shouldAllowMessage(): boolean {
        // Simple throttling implementation
        // In production, you'd use a more sophisticated rate limiting algorithm
        return true; // For now, allow all messages
    }

    private sanitizeResult(result: any): any {
        if (!result) return result;
        
        // Remove sensitive information from results before broadcasting
        if (typeof result === 'object') {
            const sanitized = { ...result };
            
            // Remove common sensitive fields
            delete sanitized.password;
            delete sanitized.key;
            delete sanitized.secret;
            delete sanitized.token;
            delete sanitized.connectionString;
            
            // Truncate large content for performance
            if (sanitized.content && sanitized.content.length > 1000) {
                sanitized.content = sanitized.content.substring(0, 1000) + '... (truncated)';
            }
            
            return sanitized;
        }
        
        return result;
    }

    private updateSessionStats(sessionId: string, agentName?: string, toolName?: string): void {
        const session = this.activeSessions.get(sessionId);
        if (!session) return;

        session.totalMessages++;
        
        if (agentName && !session.agents.includes(agentName)) {
            session.agents.push(agentName);
        }
        
        if (toolName && !session.tools.includes(toolName)) {
            session.tools.push(toolName);
        }
    }

    // ========================================
    // Utility Methods
    // ========================================

    public getActiveSessionCount(): number {
        return this.activeSessions.size;
    }

    public getSessionStats(sessionId: string): TransparencySession | undefined {
        return this.activeSessions.get(sessionId);
    }

    public isSessionActive(sessionId: string): boolean {
        const session = this.activeSessions.get(sessionId);
        return session?.status === 'active';
    }

    // Helper method for Azure Functions to get messages for SignalR output binding
    public createSignalRMessage(message: TransparencyMessage) {
        return {
            target: 'transparencyUpdate',
            arguments: [message]
        };
    }
}