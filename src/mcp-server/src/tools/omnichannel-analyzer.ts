// src/tools/omnichannel-analyzer.ts
// Tool #4: Omnichannel Journey Analyzer for Customer Experience Analysis

import { InvocationContext } from "@azure/functions";
import { OmnichannelAnalysisParameters, OmnichannelAnalysisResult } from "../shared/mcp-types.js";
import { AzureClientsManager } from "../shared/azure-clients.js";
import * as natural from "natural";

interface CustomerInteraction {
    customer_id: string;
    channel: 'web' | 'phone' | 'chat' | 'email' | 'mobile' | 'in_person';
    interaction_type: string;
    timestamp: string;
    sentiment?: 'positive' | 'neutral' | 'negative';
    outcome?: string;
    metadata?: Record<string, any>;
}

interface JourneyPath {
    customer_id: string;
    interactions: CustomerInteraction[];
    totalDuration: number;
    outcome: string;
}

export class OmnichannelJourneyAnalyzer {
    private azureClients: AzureClientsManager;
    private sentimentAnalyzer: any;

    constructor() {
        this.azureClients = AzureClientsManager.getInstance();
        this.initializeSentimentAnalyzer();
    }

    async initialize(): Promise<void> {
        await this.azureClients.initialize();
    }

    private initializeSentimentAnalyzer(): void {
        // Initialize sentiment analyzer using natural library
        try {
            this.sentimentAnalyzer = {
                analyze: (text: string) => {
                    const score = natural.SentimentAnalyzer.analyze(
                        natural.WordTokenizer.tokenize(text.toLowerCase())
                    );
                    if (score > 0.1) return 'positive';
                    if (score < -0.1) return 'negative';
                    return 'neutral';
                }
            };
        } catch (error) {
            console.warn('Could not initialize sentiment analyzer:', error);
            this.sentimentAnalyzer = {
                analyze: () => 'neutral'
            };
        }
    }

    async analyzeOmnichannelJourney(
        parameters: OmnichannelAnalysisParameters,
        context: InvocationContext
    ): Promise<OmnichannelAnalysisResult> {
        context.log('Omnichannel Journey Analyzer: Starting customer journey analysis');
        
        try {
            // Validate parameters
            if (!parameters.customer_interactions || parameters.customer_interactions.length === 0) {
                throw new Error('customer_interactions parameter is required and must not be empty');
            }

            const interactions = parameters.customer_interactions;
            const includeSentiment = parameters.include_sentiment_analysis !== false;
            const includeJourneyMapping = parameters.include_journey_mapping !== false;

            // Determine analysis period
            const timestamps = interactions.map(i => new Date(i.timestamp));
            const startDate = parameters.analysis_period?.start_date 
                ? new Date(parameters.analysis_period.start_date)
                : new Date(Math.min(...timestamps.map(d => d.getTime())));
            const endDate = parameters.analysis_period?.end_date
                ? new Date(parameters.analysis_period.end_date)
                : new Date(Math.max(...timestamps.map(d => d.getTime())));

            // Filter interactions by period
            const filteredInteractions = interactions.filter(interaction => {
                const timestamp = new Date(interaction.timestamp);
                return timestamp >= startDate && timestamp <= endDate;
            });

            context.log(`Analyzing ${filteredInteractions.length} interactions in period ${startDate.toISOString()} to ${endDate.toISOString()}`);

            // Perform channel analysis
            const channelAnalysis = await this.analyzeChannels(filteredInteractions, includeSentiment, context);

            // Perform journey pattern analysis
            let journeyPatterns: any[] = [];
            if (includeJourneyMapping) {
                journeyPatterns = await this.analyzeJourneyPatterns(filteredInteractions, context);
            }

            // Generate customer insights
            const customerInsights = await this.generateCustomerInsights(filteredInteractions, journeyPatterns, context);

            // Generate recommendations
            const recommendations = this.generateRecommendations(channelAnalysis, journeyPatterns, customerInsights);

            return {
                analysis_id: `omnichannel_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                status: 'success',
                period: {
                    start_date: startDate.toISOString(),
                    end_date: endDate.toISOString(),
                    total_interactions: filteredInteractions.length
                },
                channel_analysis: channelAnalysis,
                journey_patterns: journeyPatterns,
                customer_insights: customerInsights,
                recommendations,
                processed_at: new Date().toISOString(),
                message: `Omnichannel journey analysis completed successfully. Analyzed ${filteredInteractions.length} interactions across ${new Set(filteredInteractions.map(i => i.channel)).size} channels.`
            };

        } catch (error) {
            context.error('Error in omnichannel journey analysis:', error);
            
            return {
                analysis_id: `error_${Date.now()}`,
                status: 'error',
                period: {
                    start_date: new Date().toISOString(),
                    end_date: new Date().toISOString(),
                    total_interactions: 0
                },
                channel_analysis: [],
                journey_patterns: [],
                customer_insights: {
                    satisfaction_correlation: {},
                    dropout_points: [],
                    preferred_channels: [],
                    peak_interaction_times: []
                },
                recommendations: [],
                processed_at: new Date().toISOString(),
                message: `Omnichannel journey analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`
            };
        }
    }

    private async analyzeChannels(
        interactions: CustomerInteraction[],
        includeSentiment: boolean,
        context: InvocationContext
    ) {
        context.log('Analyzing channel performance and characteristics...');

        const channelGroups = this.groupBy(interactions, 'channel');
        const analysis = [];

        for (const [channel, channelInteractions] of Object.entries(channelGroups)) {
            const interactionCount = channelInteractions.length;
            
            // Calculate sentiment metrics
            let averageSentiment = 0;
            if (includeSentiment) {
                const sentiments = channelInteractions.map(interaction => {
                    if (interaction.sentiment) {
                        return this.sentimentToScore(interaction.sentiment);
                    }
                    // Analyze interaction content if available
                    const content = interaction.metadata?.content || interaction.interaction_type;
                    const detectedSentiment = this.sentimentAnalyzer.analyze(content);
                    return this.sentimentToScore(detectedSentiment);
                });
                averageSentiment = sentiments.reduce((sum, score) => sum + score, 0) / sentiments.length;
            }

            // Calculate effectiveness score
            const successfulOutcomes = channelInteractions.filter(i => 
                i.outcome && ['resolved', 'completed', 'successful', 'satisfied'].some(success => 
                    i.outcome!.toLowerCase().includes(success)
                )
            ).length;
            const effectivenessScore = interactionCount > 0 ? successfulOutcomes / interactionCount : 0;

            // Get common interaction types
            const interactionTypes = this.getTopItems(
                channelInteractions.map(i => i.interaction_type),
                5
            );

            analysis.push({
                channel,
                interaction_count: interactionCount,
                average_sentiment: Math.round(averageSentiment * 100) / 100,
                effectiveness_score: Math.round(effectivenessScore * 100) / 100,
                common_interaction_types: interactionTypes
            });
        }

        return analysis.sort((a, b) => b.interaction_count - a.interaction_count);
    }

    private async analyzeJourneyPatterns(
        interactions: CustomerInteraction[],
        context: InvocationContext
    ) {
        context.log('Analyzing customer journey patterns...');

        // Group interactions by customer
        const customerJourneys = this.groupBy(interactions, 'customer_id');
        const patterns = new Map<string, JourneyPath[]>();

        // Extract journey paths for each customer
        for (const [customerId, customerInteractions] of Object.entries(customerJourneys)) {
            const sortedInteractions = customerInteractions.sort(
                (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
            );

            const path = sortedInteractions.map(i => i.channel);
            const pathKey = path.join(' -> ');
            
            if (!patterns.has(pathKey)) {
                patterns.set(pathKey, []);
            }

            const totalDuration = this.calculateJourneyDuration(sortedInteractions);
            const outcome = this.determineJourneyOutcome(sortedInteractions);

            patterns.get(pathKey)!.push({
                customer_id: customerId,
                interactions: sortedInteractions,
                totalDuration,
                outcome
            });
        }

        // Analyze pattern frequency and success rates
        const patternAnalysis = [];
        for (const [pathKey, journeys] of patterns.entries()) {
            const frequency = journeys.length;
            const successfulJourneys = journeys.filter(j => 
                ['resolved', 'completed', 'successful', 'satisfied'].some(success => 
                    j.outcome.toLowerCase().includes(success)
                )
            ).length;
            const successRate = frequency > 0 ? successfulJourneys / frequency : 0;
            const averageDuration = journeys.reduce((sum, j) => sum + j.totalDuration, 0) / journeys.length;

            patternAnalysis.push({
                pattern_id: `pattern_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
                path: pathKey.split(' -> '),
                frequency,
                success_rate: Math.round(successRate * 100) / 100,
                average_duration_hours: Math.round(averageDuration / (1000 * 60 * 60) * 100) / 100
            });
        }

        return patternAnalysis
            .sort((a, b) => b.frequency - a.frequency)
            .slice(0, 10); // Top 10 patterns
    }

    private async generateCustomerInsights(
        interactions: CustomerInteraction[],
        journeyPatterns: any[],
        context: InvocationContext
    ) {
        context.log('Generating customer insights and correlations...');

        // Satisfaction correlation analysis
        const satisfactionCorrelation: Record<string, number> = {};
        const channels = [...new Set(interactions.map(i => i.channel))];
        
        for (const channel of channels) {
            const channelInteractions = interactions.filter(i => i.channel === channel);
            const satisfactionScores = channelInteractions
                .filter(i => i.outcome)
                .map(i => this.outcomeToScore(i.outcome!));
            
            if (satisfactionScores.length > 0) {
                satisfactionCorrelation[channel] = satisfactionScores.reduce((sum, score) => sum + score, 0) / satisfactionScores.length;
            }
        }

        // Identify dropout points (patterns with low success rates)
        const dropoutPoints = journeyPatterns
            .filter(pattern => pattern.success_rate < 0.5)
            .map(pattern => pattern.path[pattern.path.length - 1])
            .filter((channel, index, arr) => arr.indexOf(channel) === index);

        // Preferred channels (highest interaction count + satisfaction)
        const channelPreferences = channels.map(channel => {
            const count = interactions.filter(i => i.channel === channel).length;
            const satisfaction = satisfactionCorrelation[channel] || 0;
            return { channel, score: count * satisfaction };
        }).sort((a, b) => b.score - a.score);

        const preferredChannels = channelPreferences.slice(0, 3).map(cp => cp.channel);

        // Peak interaction times
        const hourCounts = new Array(24).fill(0);
        interactions.forEach(interaction => {
            const hour = new Date(interaction.timestamp).getHours();
            hourCounts[hour]++;
        });

        const peakHours = hourCounts
            .map((count, hour) => ({ hour, count }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 3)
            .map(ph => `${ph.hour}:00-${ph.hour + 1}:00`);

        return {
            satisfaction_correlation: satisfactionCorrelation,
            dropout_points: dropoutPoints,
            preferred_channels: preferredChannels,
            peak_interaction_times: peakHours
        };
    }

    private generateRecommendations(
        channelAnalysis: any[],
        journeyPatterns: any[],
        customerInsights: any
    ): string[] {
        const recommendations: string[] = [];

        // Channel performance recommendations
        const lowPerformingChannels = channelAnalysis.filter(ca => ca.effectiveness_score < 0.6);
        if (lowPerformingChannels.length > 0) {
            recommendations.push(`Improve performance for low-effectiveness channels: ${lowPerformingChannels.map(c => c.channel).join(', ')}`);
        }

        const highSentimentChannels = channelAnalysis.filter(ca => ca.average_sentiment > 0.7);
        if (highSentimentChannels.length > 0) {
            recommendations.push(`Leverage best practices from high-satisfaction channels: ${highSentimentChannels.map(c => c.channel).join(', ')}`);
        }

        // Journey pattern recommendations
        const longJourneys = journeyPatterns.filter(jp => jp.average_duration_hours > 24);
        if (longJourneys.length > 0) {
            recommendations.push('Optimize lengthy customer journeys to reduce resolution time');
        }

        const unsuccessfulPatterns = journeyPatterns.filter(jp => jp.success_rate < 0.5);
        if (unsuccessfulPatterns.length > 0) {
            recommendations.push('Address common failure patterns to improve customer success rates');
        }

        // Customer insights recommendations
        if (customerInsights.dropout_points.length > 0) {
            recommendations.push(`Focus retention efforts on dropout-prone channels: ${customerInsights.dropout_points.join(', ')}`);
        }

        if (customerInsights.preferred_channels.length > 0) {
            recommendations.push(`Enhance capacity during peak times: ${customerInsights.peak_interaction_times.join(', ')}`);
        }

        // Add utilities-specific recommendations
        recommendations.push('Implement proactive outage notifications to reduce inbound support contacts');
        recommendations.push('Consider self-service options for common billing and usage inquiries');
        recommendations.push('Integrate real-time service status into customer portal and mobile app');

        return recommendations;
    }

    // Utility methods
    private groupBy<T>(array: T[], key: keyof T): Record<string, T[]> {
        return array.reduce((groups, item) => {
            const group = String(item[key]);
            if (!groups[group]) {
                groups[group] = [];
            }
            groups[group].push(item);
            return groups;
        }, {} as Record<string, T[]>);
    }

    private getTopItems(items: string[], limit: number): string[] {
        const counts = new Map<string, number>();
        items.forEach(item => {
            counts.set(item, (counts.get(item) || 0) + 1);
        });

        return Array.from(counts.entries())
            .sort((a, b) => b[1] - a[1])
            .slice(0, limit)
            .map(([item]) => item);
    }

    private sentimentToScore(sentiment: string): number {
        switch (sentiment) {
            case 'positive': return 1;
            case 'negative': return -1;
            case 'neutral': default: return 0;
        }
    }

    private outcomeToScore(outcome: string): number {
        const lowerOutcome = outcome.toLowerCase();
        if (['resolved', 'completed', 'successful', 'satisfied'].some(success => lowerOutcome.includes(success))) {
            return 1;
        }
        if (['failed', 'unresolved', 'cancelled', 'unsatisfied'].some(failure => lowerOutcome.includes(failure))) {
            return -1;
        }
        return 0;
    }

    private calculateJourneyDuration(interactions: CustomerInteraction[]): number {
        if (interactions.length < 2) return 0;
        
        const firstTimestamp = new Date(interactions[0].timestamp).getTime();
        const lastTimestamp = new Date(interactions[interactions.length - 1].timestamp).getTime();
        
        return lastTimestamp - firstTimestamp;
    }

    private determineJourneyOutcome(interactions: CustomerInteraction[]): string {
        // Look for explicit outcomes in the last few interactions
        const recentInteractions = interactions.slice(-3);
        
        for (const interaction of recentInteractions.reverse()) {
            if (interaction.outcome) {
                return interaction.outcome;
            }
        }

        // Default outcome based on interaction patterns
        const lastInteraction = interactions[interactions.length - 1];
        if (lastInteraction.interaction_type.toLowerCase().includes('complete') ||
            lastInteraction.interaction_type.toLowerCase().includes('resolve')) {
            return 'completed';
        }

        return 'unknown';
    }
}