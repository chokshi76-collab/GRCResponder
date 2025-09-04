// src/mcp-server/src/tools/pdf-processor.ts
// Modular Azure Document Intelligence PDF Processing

import { InvocationContext } from "@azure/functions";
import { DocumentAnalysisClient, AzureKeyCredential } from "@azure/ai-form-recognizer";
import { BlobServiceClient } from "@azure/storage-blob";

export interface PdfProcessingParameters {
    file_path: string;
    analysis_type?: 'text' | 'tables' | 'layout' | 'comprehensive';
}

export interface PdfProcessingResult {
    document_id: string;
    status: 'success' | 'error';
    model_used?: string;
    analysis_type: string;
    file_path: string;
    extracted_text?: string;
    page_count?: number;
    word_count?: number;
    pages?: Array<{
        page_number: number;
        text: string;
        line_count: number;
        word_count: number;
    }>;
    tables_found?: number;
    tables?: Array<{
        table_number: number;
        row_count: number;
        column_count: number;
        cells: Array<{
            content: string;
            row_index: number;
            column_index: number;
            confidence: number;
        }>;
    }>;
    key_value_pairs_found?: number;
    key_value_pairs?: Array<{
        key: string;
        value: string;
        key_confidence: number;
        value_confidence: number;
    }>;
    confidence_score?: number;
    storage_url?: string | null;
    processed_at: string;
    message: string;
    azure_integration: 'ACTIVE' | 'FAILED';
    next_steps?: string[];
    error_type?: string;
    error_message?: string;
    troubleshooting?: string[];
}

export class PdfProcessor {
    private client: DocumentAnalysisClient | null = null;
    private blobService: BlobServiceClient | null = null;
    private isInitialized = false;

    constructor() {
        this.initialize();
    }

    private initialize(): void {
        try {
            // Initialize Azure Document Intelligence client
            const endpoint = process.env.AZURE_FORM_RECOGNIZER_ENDPOINT || process.env.DOCUMENT_INTELLIGENCE_ENDPOINT;
            const apiKey = process.env.AZURE_FORM_RECOGNIZER_KEY || process.env.DOCUMENT_INTELLIGENCE_KEY;
            
            if (endpoint && apiKey) {
                this.client = new DocumentAnalysisClient(endpoint, new AzureKeyCredential(apiKey));
            }

            // Initialize Azure Blob Storage client (optional)
            const storageConnectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
            if (storageConnectionString) {
                this.blobService = BlobServiceClient.fromConnectionString(storageConnectionString);
            }

            this.isInitialized = true;
        } catch (error) {
            console.error('Failed to initialize PDF processor:', error);
            this.isInitialized = false;
        }
    }

    private getModelId(analysisType: string): string {
        switch (analysisType) {
            case 'text':
                return 'prebuilt-read';
            case 'tables':
                return 'prebuilt-layout';
            case 'layout':
                return 'prebuilt-layout';
            case 'comprehensive':
                return 'prebuilt-document';
            default:
                return 'prebuilt-read';
        }
    }

    private prepareDocumentInput(filePath: string): string | Buffer {
        if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
            return filePath;
        } else if (filePath.startsWith('data:')) {
            const base64Data = filePath.split(',')[1];
            return Buffer.from(base64Data, 'base64');
        } else {
            throw new Error('File path must be a URL or base64 data. For blob storage integration, please provide the full blob URL.');
        }
    }

    private async storeResults(documentId: string, analysisResults: any, context: InvocationContext): Promise<string | null> {
        if (!this.blobService) {
            return null;
        }

        try {
            const containerClient = this.blobService.getContainerClient('processed-documents');
            await containerClient.createIfNotExists();
            
            const blobClient = containerClient.getBlockBlobClient(`${documentId}_analysis.json`);
            await blobClient.upload(
                JSON.stringify(analysisResults, null, 2), 
                JSON.stringify(analysisResults).length,
                {
                    blobHTTPHeaders: {
                        blobContentType: 'application/json'
                    }
                }
            );
            
            context.log(`Analysis results stored in blob storage: ${documentId}`);
            return blobClient.url;
        } catch (storageError) {
            context.log(`Warning: Could not store in blob storage: ${storageError}`);
            return null;
        }
    }

    async processPdf(parameters: PdfProcessingParameters, context: InvocationContext): Promise<PdfProcessingResult> {
        context.log('Processing PDF with Azure Document Intelligence:', parameters);
        
        try {
            // Validate initialization
            if (!this.isInitialized || !this.client) {
                throw new Error('Azure Document Intelligence not properly configured. Please set AZURE_FORM_RECOGNIZER_ENDPOINT and AZURE_FORM_RECOGNIZER_KEY environment variables.');
            }

            // Validate required parameters
            if (!parameters.file_path) {
                throw new Error('file_path parameter is required');
            }

            const analysisType = parameters.analysis_type || 'text';
            const modelId = this.getModelId(analysisType);
            const documentInput = this.prepareDocumentInput(parameters.file_path);

            context.log(`Starting document analysis with model: ${modelId} for file: ${parameters.file_path}`);

            // Start document analysis
            const poller = await this.client.beginAnalyzeDocument(
                modelId as any,
                documentInput,
                {
                    onProgress: (state) => {
                        context.log(`Analysis progress: ${state.status}`);
                    }
                }
            );

            // Wait for analysis to complete
            const result = await poller.pollUntilDone();
            
            if (!result) {
                throw new Error('Document analysis failed - no results returned');
            }

            // Extract comprehensive results
            const extractedText = result.content || '';
            const pageCount = result.pages?.length || 0;
            
            // Process pages
            const pages = result.pages?.map((page, index) => {
                const pageLines = page.lines?.map(line => line.content).join('\n') || '';
                
                return {
                    page_number: index + 1,
                    text: pageLines,
                    line_count: page.lines?.length || 0,
                    word_count: pageLines.split(/\s+/).filter(word => word.length > 0).length
                };
            }) || [];

            // Extract tables
            const tables = result.tables?.map((table, index) => ({
                table_number: index + 1,
                row_count: table.rowCount || 0,
                column_count: table.columnCount || 0,
                cells: table.cells?.map(cell => ({
                    content: cell.content || '',
                    row_index: cell.rowIndex,
                    column_index: cell.columnIndex,
                    confidence: Math.round((cell.confidence || 0) * 100) / 100
                })) || []
            })) || [];

            // Extract key-value pairs
            const keyValuePairs = result.keyValuePairs?.map(kvp => ({
                key: kvp.key?.content || '',
                value: kvp.value?.content || '',
                key_confidence: Math.round((kvp.key?.confidence || 0) * 100) / 100,
                value_confidence: Math.round((kvp.value?.confidence || 0) * 100) / 100
            })) || [];

            // Calculate confidence score
            const overallConfidence = result.pages?.reduce((sum, page) => {
                const pageConfidence = page.lines?.reduce((lineSum, line) => 
                    lineSum + (line.confidence || 0), 0) || 0;
                return sum + (pageConfidence / (page.lines?.length || 1));
            }, 0) / (result.pages?.length || 1) || 0;

            // Generate document ID
            const documentId = `doc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

            // Store results (optional)
            const analysisResults = {
                documentId,
                filePath: parameters.file_path,
                modelId,
                extractedText,
                pages,
                tables,
                keyValuePairs,
                confidence: Math.round(overallConfidence * 100) / 100,
                processedAt: new Date().toISOString()
            };
            
            const storageUrl = await this.storeResults(documentId, analysisResults, context);

            // Return success response
            const response: PdfProcessingResult = {
                document_id: documentId,
                status: 'success',
                model_used: modelId,
                analysis_type: analysisType,
                file_path: parameters.file_path,
                extracted_text: extractedText,
                page_count: pageCount,
                word_count: extractedText.split(/\s+/).filter(word => word.length > 0).length,
                pages: pages,
                tables_found: tables.length,
                tables: tables,
                key_value_pairs_found: keyValuePairs.length,
                key_value_pairs: keyValuePairs,
                confidence_score: Math.round(overallConfidence * 100) / 100,
                storage_url: storageUrl,
                processed_at: new Date().toISOString(),
                message: `Successfully processed PDF using Azure Document Intelligence`,
                azure_integration: 'ACTIVE',
                next_steps: [
                    'Document analysis complete',
                    'Text extracted and structured',
                    tables.length > 0 ? 'Tables detected and parsed' : 'No tables found',
                    keyValuePairs.length > 0 ? 'Key-value pairs extracted' : 'No key-value pairs detected',
                    storageUrl ? 'Results stored in Azure Blob Storage' : 'Storage not configured'
                ]
            };

            context.log(`Successfully processed PDF: ${documentId}, Pages: ${pageCount}, Tables: ${tables.length}`);
            return response;

        } catch (error) {
            context.error('Error in PDF processing module:', error);
            
            return {
                document_id: `error_${Date.now()}`,
                status: 'error',
                analysis_type: parameters.analysis_type || 'unknown',
                file_path: parameters.file_path || 'unknown',
                processed_at: new Date().toISOString(),
                message: 'PDF processing failed',
                azure_integration: 'FAILED',
                error_type: 'Azure Document Intelligence Error',
                error_message: error instanceof Error ? error.message : 'Unknown error occurred',
                troubleshooting: [
                    'Check if AZURE_FORM_RECOGNIZER_ENDPOINT is set correctly',
                    'Verify AZURE_FORM_RECOGNIZER_KEY is valid',
                    'Ensure the file URL is accessible',
                    'Check if the file format is supported (PDF, images)',
                    'Verify Azure Document Intelligence service is active'
                ]
            };
        }
    }
}

// Export singleton instance for use in main application
export const pdfProcessor = new PdfProcessor();