// src/tools/compliance-analyzer.ts
// Tool #5: Regulatory Compliance Analyzer for Utilities Industry

import { InvocationContext } from "@azure/functions";
import { ComplianceAnalysisParameters, ComplianceAnalysisResult } from "../shared/mcp-types.js";
import { AzureClientsManager } from "../shared/azure-clients.js";

interface ComplianceRule {
    regulation: string;
    requirement: string;
    patterns: string[];
    severity: 'low' | 'medium' | 'high' | 'critical';
    category: string;
    potentialPenalty: string;
}

interface ComplianceCheck {
    rule: ComplianceRule;
    status: 'compliant' | 'non_compliant' | 'needs_review';
    findings: string[];
    evidence: string[];
    confidence: number;
}

export class RegulatoryComplianceAnalyzer {
    private azureClients: AzureClientsManager;
    private complianceRules: Map<string, ComplianceRule[]> = new Map();

    constructor() {
        this.azureClients = AzureClientsManager.getInstance();
        this.initializeComplianceRules();
    }

    async initialize(): Promise<void> {
        await this.azureClients.initialize();
    }

    async analyzeCompliance(
        parameters: ComplianceAnalysisParameters,
        context: InvocationContext
    ): Promise<ComplianceAnalysisResult> {
        context.log('Regulatory Compliance Analyzer: Starting compliance analysis');
        
        try {
            // Validate parameters
            if (!parameters.document_content && !parameters.document_url) {
                throw new Error('Either document_content or document_url parameter is required');
            }

            const complianceDomain = parameters.compliance_domain || 'comprehensive';
            const includeRemediation = parameters.include_remediation !== false;

            // Get document content
            let documentContent: string;
            if (parameters.document_content) {
                documentContent = parameters.document_content;
            } else if (parameters.document_url) {
                documentContent = await this.fetchDocumentFromURL(parameters.document_url);
            } else {
                throw new Error('No document content provided');
            }

            context.log(`Analyzing document for ${complianceDomain} compliance (${documentContent.length} characters)`);

            // Perform compliance analysis
            const analysisResult = await this.performComplianceAnalysis(
                documentContent,
                complianceDomain,
                parameters.audit_scope,
                includeRemediation,
                context
            );

            return analysisResult;

        } catch (error) {
            context.error('Error in regulatory compliance analysis:', error);
            
            return {
                analysis_id: `error_${Date.now()}`,
                status: 'error',
                compliance_domain: parameters.compliance_domain || 'unknown',
                overall_score: 0,
                risk_level: 'critical',
                compliance_checks: [],
                violations: [],
                audit_trail: [{
                    timestamp: new Date().toISOString(),
                    action: 'analysis_failed',
                    details: error instanceof Error ? error.message : 'Unknown error'
                }],
                processed_at: new Date().toISOString(),
                message: `Compliance analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`
            };
        }
    }

    private async fetchDocumentFromURL(url: string): Promise<string> {
        try {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            return await response.text();
        } catch (error) {
            throw new Error(`Failed to fetch document from URL: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    private async performComplianceAnalysis(
        documentContent: string,
        complianceDomain: string,
        auditScope?: string[],
        includeRemediation: boolean = true,
        context?: InvocationContext
    ): Promise<ComplianceAnalysisResult> {
        
        const analysisId = `compliance_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const auditTrail = [{
            timestamp: new Date().toISOString(),
            action: 'analysis_started',
            details: `Starting ${complianceDomain} compliance analysis`
        }];

        // Get applicable compliance rules
        const applicableRules = this.getApplicableRules(complianceDomain, auditScope);
        context?.log(`Applying ${applicableRules.length} compliance rules for ${complianceDomain}`);

        // Perform compliance checks
        const complianceChecks = await this.runComplianceChecks(
            documentContent,
            applicableRules,
            context
        );

        // Calculate overall compliance score
        const overallScore = this.calculateComplianceScore(complianceChecks);
        const riskLevel = this.determineRiskLevel(overallScore, complianceChecks);

        // Identify violations
        const violations = this.identifyViolations(complianceChecks);

        // Generate remediation plan if requested
        let remediationPlan = undefined;
        if (includeRemediation && violations.length > 0) {
            remediationPlan = this.generateRemediationPlan(violations, complianceChecks);
        }

        auditTrail.push({
            timestamp: new Date().toISOString(),
            action: 'analysis_completed',
            details: `Found ${violations.length} violations with overall score ${overallScore}`
        });

        return {
            analysis_id: analysisId,
            status: 'success',
            compliance_domain: complianceDomain,
            overall_score: overallScore,
            risk_level: riskLevel,
            compliance_checks: complianceChecks.map(check => ({
                regulation: check.rule.regulation,
                requirement: check.rule.requirement,
                status: check.status,
                severity: check.rule.severity,
                findings: check.findings,
                evidence: check.evidence
            })),
            violations,
            audit_trail: auditTrail,
            remediation_plan: remediationPlan,
            processed_at: new Date().toISOString(),
            message: `Compliance analysis completed. Overall score: ${overallScore}/100, Risk level: ${riskLevel}, Found ${violations.length} violations.`
        };
    }

    private initializeComplianceRules(): void {
        // NERC CIP (North American Electric Reliability Corporation Critical Infrastructure Protection)
        this.complianceRules.set('nerc_cip', [
            {
                regulation: 'NERC CIP-002',
                requirement: 'Critical Asset Identification',
                patterns: ['critical asset', 'bulk electric system', 'control center', 'transmission'],
                severity: 'critical',
                category: 'asset_management',
                potentialPenalty: '$1,000,000 per day'
            },
            {
                regulation: 'NERC CIP-003',
                requirement: 'Security Management Controls',
                patterns: ['security policy', 'security manager', 'training', 'access control'],
                severity: 'high',
                category: 'security_management',
                potentialPenalty: '$1,000,000 per day'
            },
            {
                regulation: 'NERC CIP-004',
                requirement: 'Personnel & Training',
                patterns: ['background check', 'training record', 'security awareness', 'personnel access'],
                severity: 'high',
                category: 'personnel_security',
                potentialPenalty: '$500,000 per day'
            },
            {
                regulation: 'NERC CIP-005',
                requirement: 'Electronic Security Perimeters',
                patterns: ['firewall', 'network security', 'electronic perimeter', 'remote access'],
                severity: 'critical',
                category: 'network_security',
                potentialPenalty: '$1,000,000 per day'
            }
        ]);

        // EPA Environmental Regulations
        this.complianceRules.set('epa_environmental', [
            {
                regulation: 'Clean Air Act',
                requirement: 'Emissions Monitoring and Reporting',
                patterns: ['emissions', 'air quality', 'monitoring', 'nox', 'sox', 'particulate'],
                severity: 'high',
                category: 'emissions',
                potentialPenalty: '$37,500 per day per violation'
            },
            {
                regulation: 'Clean Water Act',
                requirement: 'Water Discharge Permits',
                patterns: ['water discharge', 'npdes', 'pollution', 'water quality', 'effluent'],
                severity: 'high',
                category: 'water_quality',
                potentialPenalty: '$37,500 per day per violation'
            },
            {
                regulation: 'Resource Conservation and Recovery Act',
                requirement: 'Hazardous Waste Management',
                patterns: ['hazardous waste', 'waste disposal', 'rcra', 'toxic substances'],
                severity: 'critical',
                category: 'waste_management',
                potentialPenalty: '$70,000 per day per violation'
            }
        ]);

        // State Utility Regulations (Generic)
        this.complianceRules.set('state_utility', [
            {
                regulation: 'PUC Rate Setting',
                requirement: 'Rate Structure Documentation',
                patterns: ['rate schedule', 'tariff', 'rate case', 'cost of service'],
                severity: 'medium',
                category: 'rate_regulation',
                potentialPenalty: 'Rate adjustment or refund'
            },
            {
                regulation: 'Service Quality Standards',
                requirement: 'Reliability and Service Metrics',
                patterns: ['outage duration', 'saifi', 'saidi', 'caidi', 'reliability'],
                severity: 'medium',
                category: 'service_quality',
                potentialPenalty: 'Financial penalties or rate adjustments'
            },
            {
                regulation: 'Consumer Protection',
                requirement: 'Billing and Disconnection Procedures',
                patterns: ['billing accuracy', 'disconnection notice', 'payment arrangements', 'consumer rights'],
                severity: 'medium',
                category: 'consumer_protection',
                potentialPenalty: 'Fines and customer refunds'
            }
        ]);
    }

    private getApplicableRules(complianceDomain: string, auditScope?: string[]): ComplianceRule[] {
        let rules: ComplianceRule[] = [];

        if (complianceDomain === 'comprehensive') {
            // Apply all rules
            for (const ruleSet of this.complianceRules.values()) {
                rules.push(...ruleSet);
            }
        } else {
            rules = this.complianceRules.get(complianceDomain) || [];
        }

        // Filter by audit scope if specified
        if (auditScope && auditScope.length > 0) {
            rules = rules.filter(rule => 
                auditScope.some(scope => 
                    rule.category.includes(scope) || 
                    rule.regulation.toLowerCase().includes(scope.toLowerCase())
                )
            );
        }

        return rules;
    }

    private async runComplianceChecks(
        documentContent: string,
        rules: ComplianceRule[],
        context?: InvocationContext
    ): Promise<ComplianceCheck[]> {
        
        const checks: ComplianceCheck[] = [];
        const lowerContent = documentContent.toLowerCase();

        for (const rule of rules) {
            context?.log(`Checking compliance rule: ${rule.regulation} - ${rule.requirement}`);

            const findings: string[] = [];
            const evidence: string[] = [];
            let matchCount = 0;

            // Check for pattern matches
            for (const pattern of rule.patterns) {
                const regex = new RegExp(pattern.toLowerCase(), 'gi');
                const matches = documentContent.match(regex);
                
                if (matches) {
                    matchCount += matches.length;
                    findings.push(`Found ${matches.length} references to "${pattern}"`);
                    
                    // Extract evidence (context around matches)
                    const evidenceMatches = this.extractEvidence(documentContent, pattern);
                    evidence.push(...evidenceMatches);
                }
            }

            // Determine compliance status
            let status: 'compliant' | 'non_compliant' | 'needs_review';
            let confidence = 0;

            if (matchCount === 0) {
                status = 'non_compliant';
                confidence = 0.9; // High confidence if no evidence found
                findings.push(`No evidence found for ${rule.requirement}`);
            } else if (matchCount < rule.patterns.length) {
                status = 'needs_review';
                confidence = 0.6;
                findings.push(`Partial compliance detected - manual review recommended`);
            } else {
                status = 'compliant';
                confidence = Math.min(0.9, matchCount / (rule.patterns.length * 2));
                findings.push(`Evidence found for all required patterns`);
            }

            checks.push({
                rule,
                status,
                findings,
                evidence: evidence.slice(0, 5), // Limit evidence to 5 examples
                confidence
            });
        }

        return checks;
    }

    private extractEvidence(content: string, pattern: string): string[] {
        const regex = new RegExp(`.{0,50}${pattern}.{0,50}`, 'gi');
        const matches = content.match(regex);
        return matches ? matches.map(match => match.trim()) : [];
    }

    private calculateComplianceScore(checks: ComplianceCheck[]): number {
        if (checks.length === 0) return 0;

        let totalWeight = 0;
        let weightedScore = 0;

        for (const check of checks) {
            // Weight by severity
            const weight = this.getSeverityWeight(check.rule.severity);
            totalWeight += weight;

            // Score based on compliance status
            let score = 0;
            switch (check.status) {
                case 'compliant':
                    score = 100;
                    break;
                case 'needs_review':
                    score = 50;
                    break;
                case 'non_compliant':
                    score = 0;
                    break;
            }

            weightedScore += score * weight * check.confidence;
        }

        return Math.round((weightedScore / totalWeight) * 100) / 100;
    }

    private getSeverityWeight(severity: string): number {
        switch (severity) {
            case 'critical': return 4;
            case 'high': return 3;
            case 'medium': return 2;
            case 'low': return 1;
            default: return 1;
        }
    }

    private determineRiskLevel(score: number, checks: ComplianceCheck[]): 'low' | 'medium' | 'high' | 'critical' {
        // Check for critical violations
        const criticalViolations = checks.filter(check => 
            check.rule.severity === 'critical' && check.status === 'non_compliant'
        );

        if (criticalViolations.length > 0) return 'critical';
        if (score < 50) return 'high';
        if (score < 75) return 'medium';
        return 'low';
    }

    private identifyViolations(checks: ComplianceCheck[]) {
        return checks
            .filter(check => check.status === 'non_compliant')
            .map((check, index) => ({
                violation_id: `violation_${Date.now()}_${index}`,
                regulation: check.rule.regulation,
                description: check.rule.requirement,
                severity: check.rule.severity,
                potential_penalty: check.rule.potentialPenalty,
                remediation_priority: this.getSeverityWeight(check.rule.severity)
            }));
    }

    private generateRemediationPlan(violations: any[], checks: ComplianceCheck[]) {
        const plan = violations
            .sort((a, b) => b.remediation_priority - a.remediation_priority)
            .map((violation, index) => {
                const timelineMap = {
                    'critical': '30 days',
                    'high': '90 days',
                    'medium': '180 days',
                    'low': '365 days'
                };

                const costMap = {
                    'critical': '$50,000 - $500,000',
                    'high': '$25,000 - $250,000',
                    'medium': '$10,000 - $100,000',
                    'low': '$5,000 - $50,000'
                };

                return {
                    action: `Address ${violation.description} compliance gap`,
                    priority: violation.remediation_priority,
                    estimated_cost: costMap[violation.severity as keyof typeof costMap] || 'TBD',
                    timeline: timelineMap[violation.severity as keyof typeof timelineMap] || 'TBD',
                    responsible_party: this.getResponsibleParty(violation.regulation)
                };
            });

        return plan;
    }

    private getResponsibleParty(regulation: string): string {
        if (regulation.includes('NERC')) return 'IT Security / Operations';
        if (regulation.includes('EPA') || regulation.includes('Clean')) return 'Environmental Compliance';
        if (regulation.includes('PUC') || regulation.includes('Rate')) return 'Regulatory Affairs';
        return 'Compliance Officer';
    }
}