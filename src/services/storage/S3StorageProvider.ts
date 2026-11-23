import { StorageProvider, StorageResult, UploadedFile } from './StorageProvider';
import { S3Client, PutObjectCommand, DeleteObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import crypto from 'crypto';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

export class S3StorageProvider implements StorageProvider {
    private s3: S3Client;
    private bucketName: string;
    private publicDomain: string;

    constructor() {
        this.bucketName = process.env.S3_BUCKET_NAME || 'wedapola';
        this.publicDomain = process.env.S3_PUBLIC_DOMAIN || '';
        
        this.s3 = new S3Client({
            region: 'auto', // Cloudflare R2 uses 'auto'
            endpoint: process.env.S3_ENDPOINT,
            credentials: {
                accessKeyId: process.env.S3_ACCESS_KEY_ID || '',
                secretAccessKey: process.env.S3_SECRET_ACCESS_KEY || ''
            }
        });
    }

    async upload(file: UploadedFile, entityType: string, entityId: string): Promise<StorageResult> {
        const ext = path.extname(file.originalname);
        const fileName = `${crypto.randomUUID()}${ext}`;
        // e.g. "technicians/123/uuid.jpg"
        const storageKey = `${entityType}/${entityId}/${fileName}`;

        const command = new PutObjectCommand({
            Bucket: this.bucketName,
            Key: storageKey,
            Body: file.buffer,
            ContentType: file.mimetype,
        });

        await this.s3.send(command);

        return {
            storageKey,
            url: this.getUrl(storageKey, 'PUBLIC')
        };
    }

    async delete(storageKey: string): Promise<boolean> {
        try {
            const command = new DeleteObjectCommand({
                Bucket: this.bucketName,
                Key: storageKey,
            });
            await this.s3.send(command);
            return true;
        } catch (error) {
            console.error('Failed to delete S3 object', error);
            return false;
        }
    }

    getUrl(storageKey: string, visibility: 'PUBLIC' | 'PRIVATE'): string {
        if (visibility === 'PRIVATE') {
            // In a real private scenario, we should return a presigned URL or our backend's secure route.
            // For now, we'll point back to our own backend's secure proxy route if we implement one,
            // or generate a presigned URL here (which would require making this function async).
            // Since the interface is synchronous, let's map it to a backend proxy route for now:
            return `${process.env.PUBLIC_STORAGE_BASE_URL || 'http://localhost:3000/storage'}/secure/${storageKey}`;
        }

        // Public visibility: If there's a public domain configured (e.g. pub-xxxx.r2.dev), use it.
        // Otherwise fallback to the endpoint path style.
        if (this.publicDomain) {
            return `${this.publicDomain}/${storageKey}`;
        }
        
        // Path style access (often not public by default in R2 without a domain, but we construct it)
        return `${process.env.S3_ENDPOINT}/${this.bucketName}/${storageKey}`;
    }

    async exists(storageKey: string): Promise<boolean> {
        try {
            const command = new HeadObjectCommand({
                Bucket: this.bucketName,
                Key: storageKey,
            });
            await this.s3.send(command);
            return true;
        } catch (error: any) {
            if (error.name === 'NotFound') {
                return false;
            }
            throw error;
        }
    }
}
