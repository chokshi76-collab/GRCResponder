// src/shared/utilities-context.ts
// Utilities Industry Domain Logic and Context Detection

export class UtilitiesContextAnalyzer {
    
    // Utilities-specific field patterns and contexts
    private static readonly ENERGY_METRICS = [
        'kwh', 'kilowatt', 'mwh', 'megawatt', 'voltage', 'amperage', 'power_factor',
        'demand', 'load', 'generation', 'consumption', 'usage', 'meter_reading',
        'peak_demand', 'off_peak', 'tariff', 'rate_schedule', 'energy_charge'
    ];

    private static readonly CUSTOMER_INDICATORS = [
        'customer_id', 'account_number', 'service_address', 'billing_address',
        'customer_name', 'customer_type', 'rate_class', 'service_class',
        'connection_date', 'disconnection', 'credit_rating', 'payment_history'
    ];

    private static readonly REGULATORY_FIELDS = [
        'nerc_id', 'ferc', 'puc', 'compliance', 'audit', 'violation', 'outage',
        'reliability', 'saifi', 'saidi', 'caidi', 'environmental_impact',
        'emissions', 'renewable_credit', 'carbon_footprint', 'sustainability'
    ];

    private static readonly BILLING_DATA = [
        'bill_amount', 'billing_date', 'due_date', 'payment_date', 'late_fee',
        'deposit', 'adjustment', 'credit', 'debit', 'balance', 'arrears',
        'payment_method', 'autopay', 'budget_billing', 'levelized'
    ];

    private static readonly INFRASTRUCTURE_FIELDS = [
        'transformer', 'substation', 'feeder', 'circuit', 'pole', 'line',
        'equipment_id', 'asset_id', 'maintenance', 'inspection', 'repair',
        'outage_cause', 'restoration_time', 'crew_dispatch', 'work_order'
    ];

    static detectContext(columnNames: string[]): {
        detected_context: string[];
        regulatory_fields: string[];
        energy_metrics: string[];
        customer_indicators: string[];
        confidence_score: number;
    } {
        const normalizedColumns = columnNames.map(name => 
            name.toLowerCase().replace(/[^a-z0-9]/g, '_')
        );

        const energyMatches = this.findMatches(normalizedColumns, this.ENERGY_METRICS);
        const customerMatches = this.findMatches(normalizedColumns, this.CUSTOMER_INDICATORS);
        const regulatoryMatches = this.findMatches(normalizedColumns, this.REGULATORY_FIELDS);
        const billingMatches = this.findMatches(normalizedColumns, this.BILLING_DATA);
        const infrastructureMatches = this.findMatches(normalizedColumns, this.INFRASTRUCTURE_FIELDS);

        const detectedContext: string[] = [];
        if (energyMatches.length > 0) detectedContext.push('energy_usage');
        if (customerMatches.length > 0) detectedContext.push('customer_data');
        if (regulatoryMatches.length > 0) detectedContext.push('regulatory_compliance');
        if (billingMatches.length > 0) detectedContext.push('billing_operations');
        if (infrastructureMatches.length > 0) detectedContext.push('infrastructure_management');

        // Calculate confidence based on match ratio
        const totalMatches = energyMatches.length + customerMatches.length + 
                           regulatoryMatches.length + billingMatches.length + 
                           infrastructureMatches.length;
        const confidence = Math.min(totalMatches / columnNames.length, 1.0);

        return {
            detected_context: detectedContext,
            regulatory_fields: regulatoryMatches,
            energy_metrics: energyMatches,
            customer_indicators: customerMatches,
            confidence_score: confidence
        };
    }

    private static findMatches(columnNames: string[], patterns: string[]): string[] {
        const matches: string[] = [];
        
        for (const column of columnNames) {
            for (const pattern of patterns) {
                if (column.includes(pattern) || pattern.includes(column)) {
                    matches.push(column);
                    break;
                }
            }
        }
        
        return matches;
    }

    static generateRecommendations(context: any, dataQuality: any): string[] {
        const recommendations: string[] = [];

        // Data quality recommendations
        if (dataQuality.completeness_score < 0.8) {
            recommendations.push('Address missing data issues - completeness score is below 80%');
        }

        if (dataQuality.duplicates_found > 0) {
            recommendations.push(`Remove ${dataQuality.duplicates_found} duplicate records to improve data integrity`);
        }

        // Context-specific recommendations
        if (context.detected_context.includes('energy_usage')) {
            recommendations.push('Consider implementing time-of-use analysis for energy consumption patterns');
            recommendations.push('Validate energy metrics against meter reading schedules');
        }

        if (context.detected_context.includes('customer_data')) {
            recommendations.push('Ensure customer PII is properly masked for compliance');
            recommendations.push('Implement customer segmentation analysis for targeted services');
        }

        if (context.detected_context.includes('regulatory_compliance')) {
            recommendations.push('Schedule regular compliance audits based on regulatory requirements');
            recommendations.push('Implement automated monitoring for regulatory threshold violations');
        }

        if (context.detected_context.includes('billing_operations')) {
            recommendations.push('Analyze payment patterns to identify at-risk accounts');
            recommendations.push('Consider automated billing anomaly detection');
        }

        if (context.detected_context.includes('infrastructure_management')) {
            recommendations.push('Implement predictive maintenance based on equipment data patterns');
            recommendations.push('Correlate outage data with weather and infrastructure age');
        }

        return recommendations;
    }

    static getComplianceRequirements(detectedContext: string[]): string[] {
        const requirements: string[] = [];

        if (detectedContext.includes('customer_data')) {
            requirements.push('CCPA/GDPR compliance for customer personal information');
            requirements.push('PUC data retention and privacy requirements');
        }

        if (detectedContext.includes('energy_usage')) {
            requirements.push('FERC reporting requirements for energy data');
            requirements.push('State utility commission data accuracy standards');
        }

        if (detectedContext.includes('regulatory_compliance')) {
            requirements.push('NERC CIP compliance for critical infrastructure');
            requirements.push('Environmental reporting to EPA and state agencies');
        }

        if (detectedContext.includes('billing_operations')) {
            requirements.push('State utility commission billing accuracy requirements');
            requirements.push('Consumer protection regulations for billing disputes');
        }

        return requirements;
    }
}