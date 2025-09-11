// src/tools/knowledge-search.ts
// Tool #3: Knowledge Graph Search with Azure OpenAI Embeddings and Semantic Search

import { InvocationContext } from "@azure/functions";
import { SearchClient, SearchDocument } from "@azure/search-documents";
import { OpenAIClient } from "@azure/openai";
import { KnowledgeSearchParameters, KnowledgeSearchResult } from "../shared/mcp-types.js";
import { AzureClientsManager } from "../shared/azure-clients.js";

interface DocumentRecord extends SearchDocument {
    id: string;
    title: string;
    content: string;
    document_type: string;
    embedding?: number[];
    metadata: {
        created_date: string;
        modified_date: string;
        author?: string;
        source?: string;
        tags?: string[];
        utilities_domain?: string;
        regulation_type?: string;
        compliance_level?: string;
    };
    relationships?: Array<{
        related_document_id: string;
        relationship_type: string;
        strength: number;
    }>;
}

export class KnowledgeGraphSearch {
    private azureClients: AzureClientsManager;
    private searchClient?: SearchClient<DocumentRecord>;
    private openAIClient?: OpenAIClient;
    private readonly embeddingModel = "text-embedding-ada-002";
    private readonly indexName = "knowledge-documents";

    constructor() {
        this.azureClients = AzureClientsManager.getInstance();
    }

    async initialize(): Promise<void> {
        await this.azureClients.initialize();
        this.searchClient = this.azureClients.getSearchClient() as SearchClient<DocumentRecord>;
        this.openAIClient = this.azureClients.getOpenAIClient();
        
        // Ensure the search index exists
        await this.ensureSearchIndex();
    }

    async searchKnowledge(parameters: KnowledgeSearchParameters, context: InvocationContext): Promise<KnowledgeSearchResult> {
        context.log('Knowledge Graph Search: Starting semantic search with embeddings');
        
        try {
            // Validate parameters
            if (!parameters.query) {
                throw new Error('query parameter is required');
            }

            const searchType = parameters.search_type || 'hybrid';
            const maxResults = parameters.max_results || 10;
            const similarityThreshold = parameters.similarity_threshold || 0.7;
            const includeMetadata = parameters.include_metadata || true;

            const startTime = Date.now();

            // Perform search based on type
            let searchResults: any[];
            let embeddingModel: string | undefined;

            switch (searchType) {
                case 'semantic':
                    const result = await this.performSemanticSearch(
                        parameters.query,
                        maxResults,
                        similarityThreshold,
                        parameters.document_types,
                        context
                    );
                    searchResults = result.results;
                    embeddingModel = result.embeddingModel;
                    break;
                case 'keyword':
                    searchResults = await this.performKeywordSearch(
                        parameters.query,
                        maxResults,
                        parameters.document_types,
                        context
                    );
                    break;
                case 'hybrid':
                default:
                    const hybridResult = await this.performHybridSearch(
                        parameters.query,
                        maxResults,
                        similarityThreshold,
                        parameters.document_types,
                        context
                    );
                    searchResults = hybridResult.results;
                    embeddingModel = hybridResult.embeddingModel;
                    break;
            }

            const processingTime = Date.now() - startTime;

            // Process and format results
            const formattedResults = await this.formatSearchResults(
                searchResults,
                includeMetadata,
                context
            );

            // Build relationships graph
            const resultsWithRelationships = await this.enrichWithRelationships(
                formattedResults,
                context
            );

            return {
                search_id: `search_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                status: 'success',
                query: parameters.query,
                search_type: searchType,
                results: resultsWithRelationships,
                total_results: searchResults.length,
                processing_time_ms: processingTime,
                embedding_model: embeddingModel,
                processed_at: new Date().toISOString(),
                message: `Knowledge search completed successfully. Found ${searchResults.length} relevant documents using ${searchType} search.`
            };

        } catch (error) {
            context.error('Error in knowledge graph search:', error);
            
            return {
                search_id: `error_${Date.now()}`,
                status: 'error',
                query: parameters.query || 'unknown',
                search_type: parameters.search_type || 'unknown',
                results: [],
                total_results: 0,
                processing_time_ms: 0,
                processed_at: new Date().toISOString(),
                message: `Knowledge search failed: ${error instanceof Error ? error.message : 'Unknown error'}`
            };
        }
    }

    private async performSemanticSearch(
        query: string,
        maxResults: number,
        similarityThreshold: number,
        documentTypes?: string[],
        context?: InvocationContext
    ): Promise<{ results: any[], embeddingModel: string }> {
        
        if (!this.openAIClient) {
            throw new Error('Azure OpenAI client not initialized');
        }

        context?.log('Generating query embedding using Azure OpenAI...');

        // Generate embedding for the query
        const embeddingResponse = await this.openAIClient.getEmbeddings(
            this.embeddingModel,
            [query]
        );

        const queryEmbedding = embeddingResponse.data[0].embedding;

        // Perform vector search
        const searchOptions: any = {
            vectorQueries: [{
                kind: "vector",
                vector: queryEmbedding,
                exhaustive: true,
                fields: "embedding",
                k: maxResults
            }],
            select: ["id", "title", "content", "document_type", "metadata", "relationships"],
            top: maxResults
        };

        // Add document type filter if specified
        if (documentTypes && documentTypes.length > 0) {
            searchOptions.filter = `search.in(document_type, '${documentTypes.join(',')}')`;
        }

        if (!this.searchClient) {
            throw new Error('Search client not initialized');
        }

        const searchResponse = await this.searchClient.search("*", searchOptions);
        const results = [];

        for await (const result of searchResponse.results) {
            // Calculate similarity score (assuming it's in the search score)
            const similarityScore = result.score || 0;
            
            if (similarityScore >= similarityThreshold) {
                results.push({
                    ...result.document,
                    similarity_score: similarityScore
                });
            }
        }

        return { results, embeddingModel: this.embeddingModel };
    }

    private async performKeywordSearch(
        query: string,
        maxResults: number,
        documentTypes?: string[],
        context?: InvocationContext
    ): Promise<any[]> {
        
        if (!this.searchClient) {
            throw new Error('Search client not initialized');
        }

        context?.log('Performing keyword search...');

        const searchOptions: any = {
            searchFields: ["title", "content"],
            select: ["id", "title", "content", "document_type", "metadata", "relationships"],
            top: maxResults,
            queryType: "simple"
        };

        // Add document type filter if specified
        if (documentTypes && documentTypes.length > 0) {
            searchOptions.filter = `search.in(document_type, '${documentTypes.join(',')}')`;
        }

        const searchResponse = await this.searchClient.search(query, searchOptions);
        const results = [];

        for await (const result of searchResponse.results) {
            results.push({
                ...result.document,
                similarity_score: result.score || 0
            });
        }

        return results;
    }

    private async performHybridSearch(
        query: string,
        maxResults: number,
        similarityThreshold: number,
        documentTypes?: string[],
        context?: InvocationContext
    ): Promise<{ results: any[], embeddingModel: string }> {
        
        context?.log('Performing hybrid search (keyword + semantic)...');

        // Perform both searches in parallel
        const [semanticResults, keywordResults] = await Promise.all([
            this.performSemanticSearch(query, Math.ceil(maxResults * 0.7), similarityThreshold, documentTypes, context),
            this.performKeywordSearch(query, Math.ceil(maxResults * 0.5), documentTypes, context)
        ]);

        // Merge and deduplicate results
        const mergedResults = this.mergeSearchResults(
            semanticResults.results,
            keywordResults,
            maxResults
        );

        return { results: mergedResults, embeddingModel: semanticResults.embeddingModel };
    }

    private mergeSearchResults(semanticResults: any[], keywordResults: any[], maxResults: number): any[] {
        const resultMap = new Map<string, any>();

        // Add semantic results with higher weight
        semanticResults.forEach(result => {
            resultMap.set(result.id, {
                ...result,
                similarity_score: result.similarity_score * 1.2 // Boost semantic scores
            });
        });

        // Add keyword results, combining scores if document already exists
        keywordResults.forEach(result => {
            if (resultMap.has(result.id)) {
                const existing = resultMap.get(result.id);
                existing.similarity_score = Math.max(existing.similarity_score, result.similarity_score);
            } else {
                resultMap.set(result.id, result);
            }
        });

        // Sort by combined score and return top results
        return Array.from(resultMap.values())
            .sort((a, b) => b.similarity_score - a.similarity_score)
            .slice(0, maxResults);
    }

    private async formatSearchResults(results: any[], includeMetadata: boolean, context: InvocationContext) {
        context.log(`Formatting ${results.length} search results...`);

        return results.map(result => ({
            document_id: result.id,
            title: result.title || 'Untitled Document',
            content_snippet: this.extractSnippet(result.content, 200),
            similarity_score: Math.round(result.similarity_score * 100) / 100,
            document_type: result.document_type || 'unknown',
            metadata: includeMetadata ? result.metadata : {},
            relationships: result.relationships || []
        }));
    }

    private extractSnippet(content: string, maxLength: number): string {
        if (!content) return '';
        
        if (content.length <= maxLength) {
            return content;
        }

        // Try to break at a sentence boundary
        const truncated = content.substring(0, maxLength);
        const lastSentence = truncated.lastIndexOf('. ');
        
        if (lastSentence > maxLength * 0.5) {
            return truncated.substring(0, lastSentence + 1);
        }

        // Fall back to word boundary
        const lastSpace = truncated.lastIndexOf(' ');
        if (lastSpace > maxLength * 0.7) {
            return truncated.substring(0, lastSpace) + '...';
        }

        return truncated + '...';
    }

    private async enrichWithRelationships(results: any[], context: InvocationContext) {
        context.log('Enriching results with relationship data...');

        // For each result, find related documents
        for (const result of results) {
            if (result.relationships && result.relationships.length > 0) {
                // The relationships are already stored in the document
                continue;
            }

            // Use content similarity to find relationships (simplified approach)
            const relatedDocs = await this.findRelatedDocuments(result.document_id, 3);
            result.relationships = relatedDocs;
        }

        return results;
    }

    private async findRelatedDocuments(documentId: string, maxRelated: number = 3): Promise<any[]> {
        try {
            if (!this.searchClient) {
                return [];
            }

            // Simple approach: search for documents with similar metadata or content
            const searchOptions = {
                filter: `id ne '${documentId}'`,
                select: ["id", "title", "document_type"],
                top: maxRelated
            };

            const searchResponse = await this.searchClient.search("*", searchOptions);
            const related = [];

            for await (const result of searchResponse.results) {
                related.push({
                    related_document_id: result.document.id,
                    relationship_type: 'content_similarity',
                    strength: result.score || 0.5
                });
            }

            return related;
        } catch (error) {
            console.warn('Could not find related documents:', error);
            return [];
        }
    }

    private async ensureSearchIndex(): Promise<void> {
        try {
            // In a production environment, you would create the index with proper schema
            // For now, we'll assume the index exists or create a basic one
            console.log(`Using search index: ${this.indexName}`);
        } catch (error) {
            console.warn('Could not ensure search index exists:', error);
        }
    }

    // Method to index new documents (for future use)
    async indexDocument(
        id: string,
        title: string,
        content: string,
        documentType: string,
        metadata: any,
        context: InvocationContext
    ): Promise<void> {
        try {
            if (!this.searchClient || !this.openAIClient) {
                throw new Error('Clients not initialized');
            }

            // Generate embedding for the content
            const embeddingResponse = await this.openAIClient.getEmbeddings(
                this.embeddingModel,
                [content]
            );

            const embedding = embeddingResponse.data[0].embedding;

            // Create document record
            const document: DocumentRecord = {
                id,
                title,
                content,
                document_type: documentType,
                embedding,
                metadata: {
                    created_date: new Date().toISOString(),
                    modified_date: new Date().toISOString(),
                    ...metadata
                }
            };

            // Index the document
            await this.searchClient.uploadDocuments([document]);
            
            context.log(`Document ${id} indexed successfully`);
        } catch (error) {
            context.error(`Failed to index document ${id}:`, error);
            throw error;
        }
    }
}