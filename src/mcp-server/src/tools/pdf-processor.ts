// src/mcp-server/src/tools/pdf-processor.ts
// SDK-compatible version addressing Azure Document Intelligence type mismatches

import { InvocationContext } from "@azure/functions";
import { DocumentAnalysisClient, AzureKeyCredential } from "@azure/ai-form-recognizer";
import { BlobServiceClient } from "@azure/storage-blob";
import { TransparencyLogger } from "../shared/transparency-logger.js";

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
    azure_integration: 'ACTIVE' | 'FAILED' | 'NOT_CONFIGURED';
    next_steps?: string[];
    error_type?: string;
    error_message?: string;
    troubleshooting?: string[];
}

export class PdfProcessor {
    private client: DocumentAnalysisClient | null = null;
    private blobService: BlobServiceClient | null = null;
    private isInitialized = false;
    private transparencyLogger: TransparencyLogger;

    constructor() {
        this.transparencyLogger = TransparencyLogger.getInstance();
        this.initialize();
    }

    private initialize(): void {
        try {
            // Initialize Azure Document Intelligence client
            const endpoint = process.env.AZURE_FORM_RECOGNIZER_ENDPOINT || process.env.DOCUMENT_INTELLIGENCE_ENDPOINT;
            const apiKey = process.env.AZURE_FORM_RECOGNIZER_KEY || process.env.DOCUMENT_INTELLIGENCE_KEY;
            
            if (endpoint && apiKey) {
                this.client = new DocumentAnalysisClient(endpoint, new AzureKeyCredential(apiKey));
                console.log('Azure Document Intelligence client initialized successfully');
            } else {
                console.log('Azure Document Intelligence credentials not found - will return configuration guidance');
            }

            // Initialize Azure Blob Storage client (optional)
            const storageConnectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
            if (storageConnectionString) {
                this.blobService = BlobServiceClient.fromConnectionString(storageConnectionString);
                console.log('Azure Blob Storage client initialized successfully');
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

    private getModelDescription(modelId: string): string {
        switch (modelId) {
            case 'prebuilt-read':
                return 'text extraction and OCR processing';
            case 'prebuilt-layout':
                return 'document layout analysis and table detection';
            case 'prebuilt-document':
                return 'comprehensive document analysis including text, tables, and key-value pairs';
            default:
                return 'general document processing';
        }
    }

    private getAlternativeModels(analysisType: string): string[] {
        const allModels = ['prebuilt-read', 'prebuilt-layout', 'prebuilt-document'];
        const selectedModel = this.getModelId(analysisType);
        return allModels.filter(model => model !== selectedModel);
    }

    private prepareDocumentInput(filePath: string): string {
        if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
            return filePath;
        } else if (filePath.startsWith('data:')) {
            // For now, return the URL as-is and let Azure handle base64 parsing
            return filePath;
        } else {
            throw new Error('File path must be a URL or base64 data URI. For blob storage integration, please provide the full blob URL.');
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
            const jsonContent = JSON.stringify(analysisResults, null, 2);
            await blobClient.upload(
                jsonContent, 
                jsonContent.length,
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

    async processPdf(parameters: PdfProcessingParameters, context: InvocationContext, sessionId?: string): Promise<PdfProcessingResult> {
        context.log('PDF Processor: Starting processing with Azure Document Intelligence');
        
        // Initialize transparency session if not provided
        const transparencySessionId = sessionId || this.transparencyLogger.createSession();
        
        try {
            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "Document Analysis Initialization",
                "Starting PDF document analysis. Validating input parameters and determining optimal processing strategy.",
                "process_pdf",
                context
            );

            // Validate parameters
            if (!parameters.file_path) {
                await this.transparencyLogger.broadcastAgentThought(
                    transparencySessionId,
                    "PDF Document Intelligence Agent",
                    "Parameter Validation",
                    "Error: No file path provided. PDF processing requires a valid URL or base64 data.",
                    "process_pdf",
                    context
                );
                throw new Error('file_path parameter is required');
            }

            const analysisType = parameters.analysis_type || 'text';
            
            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "Analysis Strategy Selection",
                `Selected analysis type: '${analysisType}'. This determines which AI model will process the document. Text analysis uses OCR, comprehensive analysis extracts tables and key-value pairs.`,
                "process_pdf",
                context
            );

            await this.transparencyLogger.broadcastProcessingStep(
                transparencySessionId,
                1,
                5,
                "Configuration Check",
                20,
                context
            );

            // Check if Azure Document Intelligence is configured
            if (!this.isInitialized || !this.client) {
                await this.transparencyLogger.broadcastAgentThought(
                    transparencySessionId,
                    "PDF Document Intelligence Agent",
                    "Configuration Analysis",
                    "Azure Document Intelligence is not properly configured. Providing setup guidance instead of processing.",
                    "process_pdf",
                    context
                );
                return this.returnConfigurationGuidance(parameters, analysisType);
            }

            const modelId = this.getModelId(analysisType);
            
            await this.transparencyLogger.broadcastDecisionPoint(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                `Use ${modelId} model for analysis`,
                `Based on analysis type '${analysisType}', I'm selecting the ${modelId} model. This model is optimized for ${this.getModelDescription(modelId)}.`,
                this.getAlternativeModels(analysisType),
                0.95,
                context
            );

            const documentInput = this.prepareDocumentInput(parameters.file_path);

            await this.transparencyLogger.broadcastProcessingStep(
                transparencySessionId,
                2,
                5,
                "Document Preparation",
                40,
                context
            );

            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "Document Input Processing",
                `Prepared document input for Azure analysis. Document source: ${parameters.file_path.startsWith('http') ? 'URL' : 'Base64 data'}. Ready to send to Azure Document Intelligence API.`,
                "process_pdf",
                context
            );

            context.log(`Starting document analysis with model: ${modelId} for file: ${parameters.file_path}`);

            await this.transparencyLogger.broadcastToolExecution(
                transparencySessionId,
                "process_pdf",
                "starting",
                undefined,
                undefined,
                context
            );

            // Start document analysis with simplified API call
            const poller = await this.client.beginAnalyzeDocument(modelId as any, documentInput as any);

            await this.transparencyLogger.broadcastProcessingStep(
                transparencySessionId,
                3,
                5,
                "Azure AI Analysis",
                60,
                context
            );

            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "AI Processing",
                `Document submitted to Azure Document Intelligence. The AI is now analyzing the document structure, extracting text, identifying tables, and recognizing key-value pairs using advanced OCR and ML models.`,
                "process_pdf",
                context
            );

            // Wait for analysis to complete
            const startTime = Date.now();
            const result = await poller.pollUntilDone();
            const processingTime = Date.now() - startTime;
            
            if (!result) {
                await this.transparencyLogger.broadcastAgentThought(
                    transparencySessionId,
                    "PDF Document Intelligence Agent",
                    "Analysis Failure",
                    "Azure Document Intelligence returned no results. This could indicate a processing error or unsupported document format.",
                    "process_pdf",
                    context
                );
                throw new Error('Document analysis failed - no results returned');
            }

            await this.transparencyLogger.broadcastProcessingStep(
                transparencySessionId,
                4,
                5,
                "Results Processing",
                80,
                context
            );

            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "Results Analysis",
                `Azure AI analysis completed in ${processingTime}ms. Processing results to extract structured data including text content, tables, and key-value pairs. Calculating confidence scores.`,
                "process_pdf",
                context
            );

            const analysisResults = await this.processAnalysisResults(result, parameters, analysisType, modelId, context, transparencySessionId);

            await this.transparencyLogger.broadcastProcessingStep(
                transparencySessionId,
                5,
                5,
                "Analysis Complete",
                100,
                context
            );

            await this.transparencyLogger.broadcastToolExecution(
                transparencySessionId,
                "process_pdf",
                "complete",
                processingTime,
                {
                    documentId: analysisResults.document_id,
                    pageCount: analysisResults.page_count,
                    tablesFound: analysisResults.tables_found,
                    confidence: analysisResults.confidence_score
                },
                context
            );

            await this.transparencyLogger.broadcastAgentThought(
                transparencySessionId,
                "PDF Document Intelligence Agent",
                "Final Analysis Summary",
                `Document processing complete! Successfully extracted ${analysisResults.word_count} words from ${analysisResults.page_count} pages, found ${analysisResults.tables_found} tables, and ${analysisResults.key_value_pairs_found} key-value pairs with ${(analysisResults.confidence_score || 0) * 100}% confidence.`,
                "process_pdf",
                context
            );

            return analysisResults;

        } catch (error) {
            context.error('Error in PDF processing module:', error);
            
            // Broadcast error to transparency system
            if (transparencySessionId) {
                await this.transparencyLogger.broadcastAgentThought(
                    transparencySessionId,
                    "PDF Document Intelligence Agent",
                    "Error Analysis",
                    `PDF processing failed: ${error instanceof Error ? error.message : 'Unknown error'}. This could be due to network issues, unsupported document format, or Azure service configuration problems.`,
                    "process_pdf",
                    context
                );

                await this.transparencyLogger.broadcastToolExecution(
                    transparencySessionId,
                    "process_pdf",
                    "error",
                    undefined,
                    { error: error instanceof Error ? error.message : 'Unknown error' },
                    context
                );
            }
            
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

    private returnConfigurationGuidance(parameters: PdfProcessingParameters, analysisType: string): PdfProcessingResult {
        return {
            document_id: `config_guidance_${Date.now()}`,
            status: 'error',
            analysis_type: analysisType,
            file_path: parameters.file_path,
            processed_at: new Date().toISOString(),
            message: 'Azure Document Intelligence not configured - returning setup guidance',
            azure_integration: 'NOT_CONFIGURED',
            error_type: 'Configuration Required',
            error_message: 'Azure Document Intelligence credentials not found',
            troubleshooting: [
                'Set AZURE_FORM_RECOGNIZER_ENDPOINT environment variable',
                'Set AZURE_FORM_RECOGNIZER_KEY environment variable',
                'Example: AZURE_FORM_RECOGNIZER_ENDPOINT=https://your-doc-intel.cognitiveservices.azure.com/',
                'Get your key from Azure Portal > Document Intelligence resource',
                'Optional: Set AZURE_STORAGE_CONNECTION_STRING for result persistence'
            ],
            next_steps: [
                '1. Configure Azure Document Intelligence environment variables',
                '2. Restart the Function App',
                '3. Test with a sample PDF URL',
                '4. Real AI-powered document processing will be available'
            ]
        };
    }

    private async processAnalysisResults(
        result: any, 
        parameters: PdfProcessingParameters, 
        analysisType: string, 
        modelId: string, 
        context: InvocationContext,
        sessionId?: string
    ): Promise<PdfProcessingResult> {
        // Extract comprehensive results with safe property access
        const extractedText = result.content || '';
        const pageCount = result.pages?.length || 0;

        if (sessionId) {
            await this.transparencyLogger.broadcastAgentThought(
                sessionId,
                "PDF Document Intelligence Agent",
                "Raw Results Analysis",
                `Azure returned analysis results. Detected ${pageCount} pages with ${extractedText.length} characters of extracted text. Now processing structured data elements.`,
                "process_pdf",
                context
            );
        }
        
        // Process pages with safe property access
        const pages = result.pages?.map((page: any, index: number) => {
            const pageLines = page.lines?.map((line: any) => line.content || '').join('\n') || '';
            
            return {
                page_number: index + 1,
                text: pageLines,
                line_count: page.lines?.length || 0,
                word_count: pageLines.split(/\s+/).filter((word: string) => word.length > 0).length
            };
        }) || [];

        // Extract tables with safe property access and default confidence
        if (sessionId && result.tables?.length > 0) {
            await this.transparencyLogger.broadcastAgentThought(
                sessionId,
                "PDF Document Intelligence Agent",
                "Table Structure Analysis",
                `Found ${result.tables.length} tables in the document. Analyzing table structures, extracting cell content, and calculating confidence scores for each data cell.`,
                "process_pdf",
                context
            );
        }
        
        const tables = result.tables?.map((table: any, index: number) => ({
            table_number: index + 1,
            row_count: table.rowCount || 0,
            column_count: table.columnCount || 0,
            cells: table.cells?.map((cell: any) => ({
                content: cell.content || '',
                row_index: cell.rowIndex || 0,
                column_index: cell.columnIndex || 0,
                confidence: Math.round(((cell.confidence !== undefined ? cell.confidence : 0.8) || 0) * 100) / 100
            })) || []
        })) || [];

        // Extract key-value pairs with safe property access and default confidence
        if (sessionId && result.keyValuePairs?.length > 0) {
            await this.transparencyLogger.broadcastAgentThought(
                sessionId,
                "PDF Document Intelligence Agent",
                "Key-Value Pair Extraction",
                `Identified ${result.keyValuePairs.length} key-value pairs in the document. These are structured data relationships like form fields, labels with values, and document metadata.`,
                "process_pdf",
                context
            );
        }
        
        const keyValuePairs = result.keyValuePairs?.map((kvp: any) => ({
            key: kvp.key?.content || '',
            value: kvp.value?.content || '',
            key_confidence: Math.round(((kvp.key?.confidence !== undefined ? kvp.key.confidence : 0.8) || 0) * 100) / 100,
            value_confidence: Math.round(((kvp.value?.confidence !== undefined ? kvp.value.confidence : 0.8) || 0) * 100) / 100
        })) || [];

        // Calculate confidence score with safe property access and defaults
        const overallConfidence = result.pages?.reduce((sum: number, page: any) => {
            const pageConfidence = page.lines?.reduce((lineSum: number, line: any) => 
                lineSum + ((line.confidence !== undefined ? line.confidence : 0.8) || 0), 0) || 0;
            return sum + (pageConfidence / (page.lines?.length || 1));
        }, 0) / (result.pages?.length || 1) || 0.8;

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

        if (sessionId) {
            await this.transparencyLogger.broadcastAgentThought(
                sessionId,
                "PDF Document Intelligence Agent",
                "Confidence Assessment",
                `Calculated overall confidence score: ${Math.round(overallConfidence * 100)}%. This is based on Azure's ML model confidence in OCR accuracy, text recognition quality, and structural element detection. Higher scores indicate more reliable extraction.`,
                "process_pdf",
                context
            );
        }

        // Return success response
        const response: PdfProcessingResult = {
            document_id: documentId,
            status: 'success',
            model_used: modelId,
            analysis_type: analysisType,
            file_path: parameters.file_path,
            extracted_text: extractedText,
            page_count: pageCount,
            word_count: extractedText.split(/\s+/).filter((word: string) => word.length > 0).length,
            pages: pages,
            tables_found: tables.length,
            tables: tables,
            key_value_pairs_found: keyValuePairs.length,
            key_value_pairs: keyValuePairs,
            confidence_score: Math.round(overallConfidence * 100) / 100,
            storage_url: storageUrl,
            processed_at: new Date().toISOString(),
            message: `Successfully processed PDF using Azure Document Intelligence with ${modelId} model`,
            azure_integration: 'ACTIVE',
            next_steps: [
                'Document analysis complete',
                'Text extracted and structured',
                tables.length > 0 ? `${tables.length} tables detected and parsed` : 'No tables found',
                keyValuePairs.length > 0 ? `${keyValuePairs.length} key-value pairs extracted` : 'No key-value pairs detected',
                storageUrl ? 'Results stored in Azure Blob Storage' : 'Storage not configured'
            ]
        };

        context.log(`Successfully processed PDF: ${documentId}, Pages: ${pageCount}, Tables: ${tables.length}, Confidence: ${response.confidence_score}`);
        return response;
    }
}

// Export singleton instance for use in main application
export const pdfProcessor = new PdfProcessor();