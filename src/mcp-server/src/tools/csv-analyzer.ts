// src/tools/csv-analyzer.ts
// Tool #2: Advanced CSV Analyzer with Statistical Analysis and Utilities Context

import { InvocationContext } from "@azure/functions";
import * as Papa from "papaparse";
import { Matrix } from "ml-matrix";
import { CSVAnalysisParameters, CSVAnalysisResult, MCPToolResult } from "../shared/mcp-types.js";
import { UtilitiesContextAnalyzer } from "../shared/utilities-context.js";
import { AzureClientsManager } from "../shared/azure-clients.js";

export class CSVAnalyzer {
    private azureClients: AzureClientsManager;

    constructor() {
        this.azureClients = AzureClientsManager.getInstance();
    }

    async initialize(): Promise<void> {
        await this.azureClients.initialize();
    }

    async analyzeCSV(parameters: CSVAnalysisParameters, context: InvocationContext): Promise<CSVAnalysisResult> {
        context.log('CSV Analyzer: Starting analysis with utilities context detection');
        
        try {
            // Validate parameters
            if (!parameters.csv_data && !parameters.file_url) {
                throw new Error('Either csv_data or file_url parameter is required');
            }

            const analysisType = parameters.analysis_type || 'comprehensive';
            
            // Get CSV data
            let csvContent: string;
            if (parameters.csv_data) {
                csvContent = parameters.csv_data;
            } else if (parameters.file_url) {
                csvContent = await this.fetchCSVFromURL(parameters.file_url);
            } else {
                throw new Error('No CSV data provided');
            }

            // Parse CSV
            const parseResult = Papa.parse<Record<string, string>>(csvContent, {
                header: true,
                skipEmptyLines: true,
                trimHeaders: true,
                transform: (value: string) => {
                    // Clean and normalize values
                    return value.trim();
                }
            });

            if (parseResult.errors && parseResult.errors.length > 0) {
                throw new Error(`CSV parsing errors: ${parseResult.errors.map((e: any) => e.message).join(', ')}`);
            }

            const data = parseResult.data as Record<string, string>[];
            const headers = parseResult.meta?.fields || [];

            context.log(`Parsed CSV: ${data.length} rows, ${headers.length} columns`);

            // Perform analysis
            const result = await this.performAnalysis(
                data, 
                headers, 
                csvContent.length, 
                analysisType,
                parameters.include_recommendations || false,
                context
            );

            return result;

        } catch (error) {
            context.error('Error in CSV analysis:', error);
            
            return {
                analysis_id: `error_${Date.now()}`,
                status: 'error',
                file_info: { rows: 0, columns: 0 },
                column_analysis: [],
                data_quality: {
                    completeness_score: 0,
                    consistency_score: 0,
                    duplicates_found: 0,
                    data_anomalies: [error instanceof Error ? error.message : 'Unknown error']
                },
                processed_at: new Date().toISOString(),
                message: 'CSV analysis failed'
            };
        }
    }

    private async fetchCSVFromURL(url: string): Promise<string> {
        try {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            return await response.text();
        } catch (error) {
            throw new Error(`Failed to fetch CSV from URL: ${error instanceof Error ? error.message : 'Unknown error'}`);
        }
    }

    private async performAnalysis(
        data: any[],
        headers: string[],
        fileSizeBytes: number,
        analysisType: string,
        includeRecommendations: boolean,
        context: InvocationContext
    ): Promise<CSVAnalysisResult> {
        
        const analysisId = `csv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Basic file info
        const fileInfo = {
            rows: data.length,
            columns: headers.length,
            size_bytes: fileSizeBytes,
            encoding: 'utf-8'
        };

        // Column analysis
        const columnAnalysis = await this.analyzeColumns(data, headers, context);
        
        // Statistical analysis (for numerical columns)
        let statisticalSummary = undefined;
        if (analysisType === 'statistical' || analysisType === 'comprehensive') {
            statisticalSummary = this.performStatisticalAnalysis(data, headers, context);
        }

        // Data quality assessment
        const dataQuality = this.assessDataQuality(data, headers, context);

        // Utilities context detection
        let utilitiesInsights = undefined;
        if (analysisType === 'utilities_context' || analysisType === 'comprehensive') {
            utilitiesInsights = this.analyzeUtilitiesContext(headers, columnAnalysis, dataQuality);
        }

        // Generate recommendations if requested
        const recommendations = includeRecommendations ? 
            UtilitiesContextAnalyzer.generateRecommendations(utilitiesInsights, dataQuality) : undefined;

        return {
            analysis_id: analysisId,
            status: 'success',
            file_info: fileInfo,
            column_analysis: columnAnalysis,
            statistical_summary: statisticalSummary,
            data_quality: dataQuality,
            utilities_insights: utilitiesInsights,
            processed_at: new Date().toISOString(),
            message: `CSV analysis completed successfully using ${analysisType} analysis. Processed ${data.length} rows across ${headers.length} columns.`
        };
    }

    private async analyzeColumns(data: any[], headers: string[], context: InvocationContext) {
        context.log('Analyzing column characteristics and data types...');
        
        return headers.map(header => {
            const columnData = data.map(row => row[header]).filter(val => val !== null && val !== undefined && val !== '');
            const allValues = data.map(row => row[header]);
            
            // Determine data type
            const dataType = this.inferDataType(columnData);
            
            // Calculate statistics
            const missingValues = allValues.length - columnData.length;
            const uniqueValues = new Set(columnData).size;
            const sampleValues = [...new Set(columnData)].slice(0, 5);
            
            // Detect utilities context for this column
            const utilitiesContext = this.detectColumnContext(header);

            return {
                name: header,
                data_type: dataType,
                missing_values: missingValues,
                unique_values: uniqueValues,
                sample_values: sampleValues.map(v => String(v)),
                utilities_context: utilitiesContext
            };
        });
    }

    private inferDataType(values: any[]): 'string' | 'number' | 'date' | 'boolean' | 'mixed' {
        if (values.length === 0) return 'string';

        let numberCount = 0;
        let dateCount = 0;
        let booleanCount = 0;
        
        for (const value of values.slice(0, 100)) { // Sample first 100 values
            const str = String(value).toLowerCase().trim();
            
            // Check if boolean
            if (str === 'true' || str === 'false' || str === 'yes' || str === 'no' || str === '1' || str === '0') {
                booleanCount++;
            }
            // Check if number
            else if (!isNaN(Number(value)) && !isNaN(parseFloat(value))) {
                numberCount++;
            }
            // Check if date
            else if (!isNaN(Date.parse(value))) {
                dateCount++;
            }
        }

        const total = Math.min(values.length, 100);
        if (numberCount / total > 0.8) return 'number';
        if (dateCount / total > 0.8) return 'date';
        if (booleanCount / total > 0.8) return 'boolean';
        if ((numberCount + dateCount + booleanCount) / total > 0.5) return 'mixed';
        
        return 'string';
    }

    private detectColumnContext(columnName: string): string | undefined {
        const name = columnName.toLowerCase().replace(/[^a-z0-9]/g, '_');
        
        // Energy-related patterns
        if (name.includes('kwh') || name.includes('energy') || name.includes('power') || 
            name.includes('usage') || name.includes('consumption') || name.includes('demand')) {
            return 'energy_usage';
        }
        
        // Customer-related patterns
        if (name.includes('customer') || name.includes('account') || name.includes('service_address')) {
            return 'customer_data';
        }
        
        // Billing-related patterns
        if (name.includes('bill') || name.includes('charge') || name.includes('payment') || 
            name.includes('amount') || name.includes('balance')) {
            return 'billing_data';
        }
        
        // Regulatory patterns
        if (name.includes('compliance') || name.includes('audit') || name.includes('violation') ||
            name.includes('outage') || name.includes('reliability')) {
            return 'regulatory_compliance';
        }
        
        return undefined;
    }

    private performStatisticalAnalysis(data: any[], headers: string[], context: InvocationContext) {
        context.log('Performing statistical analysis on numerical columns...');
        
        const numericalColumns = headers.filter(header => {
            const values = data.map(row => row[header]).filter(val => val !== null && val !== undefined && val !== '');
            return values.length > 0 && this.inferDataType(values) === 'number';
        });

        return numericalColumns.map(column => {
            const values = data
                .map(row => parseFloat(row[column]))
                .filter(val => !isNaN(val));

            if (values.length === 0) return null;

            // Sort values for quantile calculations
            const sortedValues = values.sort((a, b) => a - b);
            
            // Calculate statistics
            const mean = values.reduce((sum, val) => sum + val, 0) / values.length;
            const median = this.calculateMedian(sortedValues);
            const stdDev = Math.sqrt(values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length);
            const min = Math.min(...values);
            const max = Math.max(...values);
            
            // Calculate quartiles
            const q1 = this.calculatePercentile(sortedValues, 25);
            const q3 = this.calculatePercentile(sortedValues, 75);
            const iqr = q3 - q1;
            
            // Detect outliers using IQR method
            const outlierThresholdLow = q1 - 1.5 * iqr;
            const outlierThresholdHigh = q3 + 1.5 * iqr;
            const outliers = values.filter(val => val < outlierThresholdLow || val > outlierThresholdHigh);

            return {
                column,
                mean: Math.round(mean * 100) / 100,
                median,
                std_dev: Math.round(stdDev * 100) / 100,
                min,
                max,
                quartiles: [q1, median, q3] as [number, number, number],
                outliers_count: outliers.length
            };
        }).filter(stat => stat !== null);
    }

    private calculateMedian(sortedValues: number[]): number {
        const n = sortedValues.length;
        if (n === 0) return 0;
        if (n % 2 === 0) {
            return (sortedValues[n / 2 - 1] + sortedValues[n / 2]) / 2;
        } else {
            return sortedValues[Math.floor(n / 2)];
        }
    }

    private calculatePercentile(sortedValues: number[], percentile: number): number {
        if (sortedValues.length === 0) return 0;
        const index = (percentile / 100) * (sortedValues.length - 1);
        const lower = Math.floor(index);
        const upper = Math.ceil(index);
        const weight = index % 1;
        
        if (lower === upper) {
            return sortedValues[lower];
        } else {
            return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
        }
    }

    private assessDataQuality(data: any[], headers: string[], context: InvocationContext) {
        context.log('Assessing data quality metrics...');
        
        let totalCells = data.length * headers.length;
        let missingCells = 0;
        let inconsistentCells = 0;
        let duplicateRows = 0;
        const anomalies: string[] = [];

        // Count missing values
        for (const row of data) {
            for (const header of headers) {
                const value = row[header];
                if (value === null || value === undefined || value === '') {
                    missingCells++;
                }
            }
        }

        // Detect duplicate rows
        const rowStrings = data.map(row => JSON.stringify(row));
        const uniqueRows = new Set(rowStrings);
        duplicateRows = rowStrings.length - uniqueRows.size;

        // Detect data type inconsistencies within columns
        for (const header of headers) {
            const values = data.map(row => row[header]).filter(val => val !== null && val !== undefined && val !== '');
            const expectedType = this.inferDataType(values);
            
            let inconsistentCount = 0;
            for (const value of values) {
                const actualType = this.inferDataType([value]);
                if (actualType !== expectedType && expectedType !== 'mixed') {
                    inconsistentCount++;
                }
            }
            
            if (inconsistentCount / values.length > 0.1) { // More than 10% inconsistent
                anomalies.push(`Column '${header}' has ${inconsistentCount} values inconsistent with expected type ${expectedType}`);
                inconsistentCells += inconsistentCount;
            }
        }

        // Calculate scores
        const completenessScore = Math.max(0, (totalCells - missingCells) / totalCells);
        const consistencyScore = Math.max(0, (totalCells - inconsistentCells) / totalCells);

        return {
            completeness_score: Math.round(completenessScore * 100) / 100,
            consistency_score: Math.round(consistencyScore * 100) / 100,
            duplicates_found: duplicateRows,
            data_anomalies: anomalies
        };
    }

    private analyzeUtilitiesContext(headers: string[], columnAnalysis: any[], dataQuality: any) {
        const contextAnalysis = UtilitiesContextAnalyzer.detectContext(headers);
        const recommendations = UtilitiesContextAnalyzer.generateRecommendations(contextAnalysis, dataQuality);
        
        return {
            ...contextAnalysis,
            recommendations
        };
    }

    // Store analysis results in Cosmos DB (optional)
    private async storeResults(analysisResult: CSVAnalysisResult, context: InvocationContext): Promise<void> {
        try {
            const cosmosClient = this.azureClients.getCosmosClient();
            if (!cosmosClient) {
                context.log('Cosmos DB client not available, skipping storage');
                return;
            }

            const database = cosmosClient.database('utilities-analytics');
            const container = database.container('csv-analyses');
            
            await container.items.create({
                id: analysisResult.analysis_id,
                ...analysisResult,
                stored_at: new Date().toISOString()
            });
            
            context.log(`Analysis results stored in Cosmos DB: ${analysisResult.analysis_id}`);
        } catch (error) {
            context.warn('Could not store results in Cosmos DB:', error);
        }
    }
}