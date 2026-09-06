export interface StorageResult {
    storageKey: string;
    url: string;
}

export interface StorageProvider {
    upload(file: Express.Multer.File, entityType: string, entityId: string): Promise<StorageResult>;
    delete(storageKey: string): Promise<boolean>;
    getUrl(storageKey: string, visibility: 'PUBLIC' | 'PRIVATE'): string;
    exists(storageKey: string): Promise<boolean>;
}
