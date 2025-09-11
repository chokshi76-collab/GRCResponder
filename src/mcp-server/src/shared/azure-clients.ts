// src/shared/azure-clients.ts
// Shared Azure Service Clients

import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import { SearchClient, AzureKeyCredential as SearchCredential } from "@azure/search-documents";
import { OpenAIClient, AzureKeyCredential as OpenAICredential } from "@azure/openai";
import { CosmosClient } from "@azure/cosmos";
import { BlobServiceClient } from "@azure/storage-blob";

export class AzureClientsManager {
    private static instance: AzureClientsManager;
    private keyVaultClient?: SecretClient;
    private searchClient?: SearchClient<any>;
    private openAIClient?: OpenAIClient;
    private cosmosClient?: CosmosClient;
    private blobServiceClient?: BlobServiceClient;
    private initialized = false;

    private constructor() {}

    static getInstance(): AzureClientsManager {
        if (!AzureClientsManager.instance) {
            AzureClientsManager.instance = new AzureClientsManager();
        }
        return AzureClientsManager.instance;
    }

    async initialize(): Promise<void> {
        if (this.initialized) return;

        try {
            // Initialize Key Vault client
            const keyVaultUrl = process.env.KEY_VAULT_URL;
            if (keyVaultUrl) {
                const credential = new DefaultAzureCredential();
                this.keyVaultClient = new SecretClient(keyVaultUrl, credential);
                console.log('Key Vault client initialized successfully');
            }

            // Initialize other clients
            await this.initializeSearchClient();
            await this.initializeOpenAIClient();
            await this.initializeCosmosClient();
            await this.initializeBlobClient();

            this.initialized = true;
            console.log('All Azure clients initialized successfully');
        } catch (error) {
            console.error('Failed to initialize Azure clients:', error);
            throw error;
        }
    }

    private async initializeSearchClient(): Promise<void> {
        try {
            const searchEndpoint = await this.getSecret('search-service-endpoint');
            const searchKey = await this.getSecret('search-service-key');
            
            if (searchEndpoint && searchKey) {
                this.searchClient = new SearchClient(
                    searchEndpoint,
                    'documents-index', // Default index name
                    new SearchCredential(searchKey)
                );
                console.log('Azure AI Search client initialized');
            }
        } catch (error) {
            console.warn('Could not initialize Search client:', error);
        }
    }

    private async initializeOpenAIClient(): Promise<void> {
        try {
            const openAIEndpoint = await this.getSecret('openai-endpoint');
            const openAIKey = await this.getSecret('openai-key');
            
            if (openAIEndpoint && openAIKey) {
                this.openAIClient = new OpenAIClient(
                    openAIEndpoint,
                    new OpenAICredential(openAIKey)
                );
                console.log('Azure OpenAI client initialized');
            }
        } catch (error) {
            console.warn('Could not initialize OpenAI client:', error);
        }
    }

    private async initializeCosmosClient(): Promise<void> {
        try {
            const cosmosEndpoint = await this.getSecret('cosmos-endpoint');
            const cosmosKey = await this.getSecret('cosmos-key');
            
            if (cosmosEndpoint && cosmosKey) {
                this.cosmosClient = new CosmosClient({
                    endpoint: cosmosEndpoint,
                    key: cosmosKey
                });
                console.log('Cosmos DB client initialized');
            }
        } catch (error) {
            console.warn('Could not initialize Cosmos client:', error);
        }
    }

    private async initializeBlobClient(): Promise<void> {
        try {
            const storageConnectionString = await this.getSecret('storage-connection-string');
            
            if (storageConnectionString) {
                this.blobServiceClient = BlobServiceClient.fromConnectionString(storageConnectionString);
                console.log('Blob Storage client initialized');
            }
        } catch (error) {
            console.warn('Could not initialize Blob Storage client:', error);
        }
    }

    private async getSecret(secretName: string): Promise<string | undefined> {
        if (!this.keyVaultClient) {
            console.warn(`Key Vault client not initialized, cannot get secret: ${secretName}`);
            return undefined;
        }

        try {
            const secret = await this.keyVaultClient.getSecret(secretName);
            return secret.value;
        } catch (error) {
            console.warn(`Could not retrieve secret ${secretName}:`, error);
            return undefined;
        }
    }

    // Getter methods for clients
    getSearchClient(): SearchClient<any> | undefined {
        return this.searchClient;
    }

    getOpenAIClient(): OpenAIClient | undefined {
        return this.openAIClient;
    }

    getCosmosClient(): CosmosClient | undefined {
        return this.cosmosClient;
    }

    getBlobServiceClient(): BlobServiceClient | undefined {
        return this.blobServiceClient;
    }

    getKeyVaultClient(): SecretClient | undefined {
        return this.keyVaultClient;
    }

    // Health check method
    async healthCheck(): Promise<{ [key: string]: boolean }> {
        return {
            keyVault: !!this.keyVaultClient,
            search: !!this.searchClient,
            openAI: !!this.openAIClient,
            cosmos: !!this.cosmosClient,
            blobStorage: !!this.blobServiceClient
        };
    }
}