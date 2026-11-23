export interface StorageResult {
    storageKey: string;
    url: string;
}

export interface UploadedFile {
    fieldname?: string;
    originalname: string;
    encoding?: string;
    mimetype: string;
    size?: number;
    buffer: Buffer;
}

export interface StorageProvider {
    upload(file: UploadedFile, entityType: string, entityId: string): Promise<StorageResult>;
    delete(storageKey: string): Promise<boolean>;
    getUrl(storageKey: string, visibility: 'PUBLIC' | 'PRIVATE'): string;
    exists(storageKey: string): Promise<boolean>;
}
