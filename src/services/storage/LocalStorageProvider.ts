import { StorageProvider, StorageResult } from './StorageProvider';
import * as fs from 'fs';
import * as path from 'path';
import crypto from 'crypto';
import dotenv from 'dotenv';

dotenv.config();

export class LocalStorageProvider implements StorageProvider {
    private storagePath: string;
    private publicBaseUrl: string;

    constructor() {
        this.storagePath = process.env.LOCAL_STORAGE_PATH || path.join(process.cwd(), 'storage');
        this.publicBaseUrl = process.env.PUBLIC_STORAGE_BASE_URL || 'http://localhost:3000/storage';
        
        // Ensure base storage directory exists
        if (!fs.existsSync(this.storagePath)) {
            fs.mkdirSync(this.storagePath, { recursive: true });
        }
    }

    async upload(file: Express.Multer.File, entityType: string, entityId: string): Promise<StorageResult> {
        // e.g., entityType = 'technicians', entityId = '123'
        const dirPath = path.join(this.storagePath, entityType, entityId);
        
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }

        const ext = path.extname(file.originalname);
        const fileName = `${crypto.randomUUID()}${ext}`;
        const filePath = path.join(dirPath, fileName);
        
        // storageKey is a relative path that can be used universally
        // e.g. "technicians/123/uuid.jpg"
        const storageKey = `${entityType}/${entityId}/${fileName}`;

        // Write file to local disk
        fs.writeFileSync(filePath, file.buffer);

        return {
            storageKey,
            url: this.getUrl(storageKey, 'PUBLIC') // By default return public URL structure
        };
    }

    async delete(storageKey: string): Promise<boolean> {
        const filePath = path.join(this.storagePath, storageKey);
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            return true;
        }
        return false;
    }

    getUrl(storageKey: string, visibility: 'PUBLIC' | 'PRIVATE'): string {
        // For private files, we would return a secure API endpoint route instead.
        // For now, if local, we assume /storage route maps to it.
        if (visibility === 'PRIVATE') {
            return `${this.publicBaseUrl}/secure/${storageKey}`;
        }
        return `${this.publicBaseUrl}/${storageKey}`;
    }

    async exists(storageKey: string): Promise<boolean> {
        const filePath = path.join(this.storagePath, storageKey);
        return fs.existsSync(filePath);
    }
}
