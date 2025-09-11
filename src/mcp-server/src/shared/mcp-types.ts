// src/shared/mcp-types.ts
// MCP Protocol Types and Interfaces

export interface MCPTool {
    name: string;
    description: string;
    inputSchema: JSONSchema;
}

export interface JSONSchema {
    type: string;
    properties: Record<string, any>;
    required?: string[];
    additionalProperties?: boolean;
}

export interface MCPToolResult {
    tool: string;
    result: any;
    timestamp: string;
    status: 'success' | 'error';
    architecture: string;
}

export interface MCPToolError {
    tool: string;
    error: {
        type: string;
        message: string;
        details?: any;
        troubleshooting?: string[];
    };
    timestamp: string;
    status: 'error';
    architecture: string;
}

// Tool #2: CSV Analyzer Types
export interface CSVAnalysisParameters {
    csv_data?: string;           // CSV content as string
    file_url?: string;           // URL to CSV file
    analysis_type?: 'basic' | 'statistical' | 'utilities_context' | 'comprehensive';
    include_recommendations?: boolean;
}

export interface CSVAnalysisResult {
    analysis_id: string;
    status: 'success' | 'error';
    file_info: {
        rows: number;
        columns: number;
        size_bytes?: number;
        encoding?: string;
    };
    column_analysis: Array<{
        name: string;
        data_type: 'string' | 'number' | 'date' | 'boolean' | 'mixed';
        missing_values: number;
        unique_values: number;
        sample_values: string[];
        utilities_context?: string; // e.g., 'energy_usage', 'customer_id', 'billing_data'
    }>;
    statistical_summary?: Array<{
        column: string;
        mean?: number;
        median?: number;
        std_dev?: number;
        min?: number;
        max?: number;
        quartiles?: [number, number, number]; // Q1, Q2, Q3
        outliers_count?: number;
    }>;
    data_quality: {
        completeness_score: number; // 0-1
        consistency_score: number;  // 0-1
        duplicates_found: number;
        data_anomalies: string[];
    };
    utilities_insights?: {
        detected_context: string[];
        regulatory_fields: string[];
        energy_metrics: string[];
        customer_indicators: string[];
        recommendations: string[];
    };
    processed_at: string;
    message: string;
}

// Tool #3: Knowledge Graph Search Types
export interface KnowledgeSearchParameters {
    query: string;
    search_type?: 'semantic' | 'keyword' | 'hybrid';
    max_results?: number;
    similarity_threshold?: number;
    document_types?: string[];
    include_metadata?: boolean;
}

export interface KnowledgeSearchResult {
    search_id: string;
    status: 'success' | 'error';
    query: string;
    search_type: string;
    results: Array<{
        document_id: string;
        title: string;
        content_snippet: string;
        similarity_score: number;
        document_type: string;
        metadata: Record<string, any>;
        relationships?: Array<{
            related_document_id: string;
            relationship_type: string;
            strength: number;
        }>;
    }>;
    total_results: number;
    processing_time_ms: number;
    embedding_model?: string;
    processed_at: string;
    message: string;
}

// Tool #4: Omnichannel Journey Analyzer Types
export interface OmnichannelAnalysisParameters {
    customer_interactions: Array<{
        customer_id: string;
        channel: 'web' | 'phone' | 'chat' | 'email' | 'mobile' | 'in_person';
        interaction_type: string;
        timestamp: string;
        sentiment?: 'positive' | 'neutral' | 'negative';
        outcome?: string;
        metadata?: Record<string, any>;
    }>;
    analysis_period?: {
        start_date: string;
        end_date: string;
    };
    include_journey_mapping?: boolean;
    include_sentiment_analysis?: boolean;
}

export interface OmnichannelAnalysisResult {
    analysis_id: string;
    status: 'success' | 'error';
    period: {
        start_date: string;
        end_date: string;
        total_interactions: number;
    };
    channel_analysis: Array<{
        channel: string;
        interaction_count: number;
        average_sentiment: number;
        effectiveness_score: number;
        common_interaction_types: string[];
    }>;
    journey_patterns: Array<{
        pattern_id: string;
        path: string[];
        frequency: number;
        success_rate: number;
        average_duration_hours: number;
    }>;
    customer_insights: {
        satisfaction_correlation: Record<string, number>;
        dropout_points: string[];
        preferred_channels: string[];
        peak_interaction_times: string[];
    };
    recommendations: string[];
    processed_at: string;
    message: string;
}

// Tool #5: Regulatory Compliance Analyzer Types
export interface ComplianceAnalysisParameters {
    compliance_domain: 'nerc_cip' | 'epa_environmental' | 'state_utility' | 'comprehensive';
    document_content?: string;
    document_url?: string;
    audit_scope?: string[];
    include_remediation?: boolean;
}

export interface ComplianceAnalysisResult {
    analysis_id: string;
    status: 'success' | 'error';
    compliance_domain: string;
    overall_score: number; // 0-100
    risk_level: 'low' | 'medium' | 'high' | 'critical';
    compliance_checks: Array<{
        regulation: string;
        requirement: string;
        status: 'compliant' | 'non_compliant' | 'needs_review';
        severity: 'low' | 'medium' | 'high' | 'critical';
        findings: string[];
        evidence?: string[];
    }>;
    violations: Array<{
        violation_id: string;
        regulation: string;
        description: string;
        severity: string;
        potential_penalty: string;
        remediation_priority: number;
    }>;
    audit_trail: Array<{
        timestamp: string;
        action: string;
        details: string;
        user?: string;
    }>;
    remediation_plan?: Array<{
        action: string;
        priority: number;
        estimated_cost: string;
        timeline: string;
        responsible_party: string;
    }>;
    processed_at: string;
    message: string;
}

// ========================================
// WebSocket Real-Time Transparency Types
// ========================================

export interface AgentThoughtMessage {
    type: 'agent_thought';
    sessionId: string;
    agentName: string;
    step: string;
    thought: string;
    timestamp: string;
    toolCalled?: string;
    metadata?: Record<string, any>;
}

export interface ToolExecutionMessage {
    type: 'tool_execution';
    sessionId: string;
    toolName: string;
    status: 'starting' | 'processing' | 'complete' | 'error';
    duration?: number;
    result?: any;
    timestamp: string;
    metadata?: Record<string, any>;
}

export interface ProcessingStepMessage {
    type: 'processing_step';
    sessionId: string;
    currentStep: number;
    totalSteps: number;
    stepName: string;
    progress: number;
    timestamp: string;
    metadata?: Record<string, any>;
}

export interface DecisionPointMessage {
    type: 'decision_point';
    sessionId: string;
    agentName: string;
    decision: string;
    reasoning: string;
    alternatives: string[];
    confidence: number;
    timestamp: string;
}

export interface CollaborationMessage {
    type: 'collaboration';
    sessionId: string;
    fromAgent: string;
    toAgent: string;
    message: string;
    collaborationType: 'request' | 'response' | 'handoff' | 'consultation';
    timestamp: string;
}

export type TransparencyMessage = 
    | AgentThoughtMessage 
    | ToolExecutionMessage 
    | ProcessingStepMessage 
    | DecisionPointMessage 
    | CollaborationMessage;

export interface TransparencySession {
    sessionId: string;
    userId?: string;
    startTime: string;
    endTime?: string;
    status: 'active' | 'completed' | 'error';
    totalMessages: number;
    agents: string[];
    tools: string[];
}

export interface WebSocketConnectionInfo {
    connectionId: string;
    sessionId: string;
    userId?: string;
    connectedAt: string;
    lastActivity: string;
}

// Configuration types
export interface TransparencyConfig {
    logLevel: 'basic' | 'detailed' | 'verbose';
    enableAgentThoughts: boolean;
    enableToolExecution: boolean;
    enableProcessingSteps: boolean;
    enableDecisionPoints: boolean;
    enableCollaboration: boolean;
    maxSessionDuration: number; // in minutes
    messageThrottling: {
        enabled: boolean;
        maxMessagesPerSecond: number;
    };
}