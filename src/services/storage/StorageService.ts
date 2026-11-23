import { StorageProvider, StorageResult, UploadedFile } from './StorageProvider';
import { LocalStorageProvider } from './LocalStorageProvider';
import { S3StorageProvider } from './S3StorageProvider';
import dotenv from 'dotenv';
import pool from '../../config/db';

dotenv.config();

export class StorageService {
    private provider: StorageProvider;

    constructor() {
        const providerType = process.env.STORAGE_PROVIDER || 'local';
        
        switch(providerType) {
            case 's3':
            case 'r2':
                this.provider = new S3StorageProvider();
                break;
            case 'local':
            default:
                this.provider = new LocalStorageProvider();
        }
    }

    async uploadFile(file: UploadedFile, ownerId: number, entityType: string, entityId: string, visibility: 'PUBLIC' | 'PRIVATE'): Promise<StorageResult> {
        // 1. Upload to the actual storage provider
        const result = await this.provider.upload(file, entityType, entityId);
        
        // 2. Save metadata to database (storage_files table)
        const query = `
            INSERT INTO storage_files 
            (owner_id, entity_type, entity_id, storage_provider, storage_key, original_filename, mime_type, file_size, visibility)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        await pool.execute(query, [
            ownerId, 
            entityType, 
            entityId, 
            process.env.STORAGE_PROVIDER || 'local', 
            result.storageKey, 
            file.originalname, 
            file.mimetype, 
            file.size ?? null, 
            visibility
        ] as any);

        // Override URL based on visibility if needed
        result.url = this.provider.getUrl(result.storageKey, visibility);
        return result;
    }

    async deleteFile(storageKey: string): Promise<boolean> {
        // Remove from provider
        const deleted = await this.provider.delete(storageKey);
        
        // Remove from db
        if (deleted) {
            await pool.execute(`DELETE FROM storage_files WHERE storage_key = ?`, [storageKey]);
        }
        
        return deleted;
    }

    getFileUrl(storageKey: string, visibility: 'PUBLIC' | 'PRIVATE'): string {
        return this.provider.getUrl(storageKey, visibility);
    }
}

export const storageService = new StorageService();
