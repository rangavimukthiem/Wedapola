import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import pool from '../config/db';
import { storageService } from '../services/storage/StorageService';
import { notificationService } from '../services/NotificationService';

const ALLOWED_DOC_TYPES = [
    'nic_front',
    'nic_back',
    'selfie',
    'address_proof',
    'nvq_cert',
    'police_report'
] as const;

type DocType = typeof ALLOWED_DOC_TYPES[number];

const DOC_COLUMN_MAP: Record<DocType, string> = {
    nic_front: 'nic_front_key',
    nic_back: 'nic_back_key',
    selfie: 'selfie_key',
    address_proof: 'address_proof_key',
    nvq_cert: 'nvq_cert_key',
    police_report: 'police_report_key'
};

export class KycController {
    async uploadDocument(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const docType = req.body.docType as DocType;
            const file = req.file;

            if (!file) {
                res.status(400).json({ error: 'Document file is required' });
                return;
            }

            if (!docType || !ALLOWED_DOC_TYPES.includes(docType)) {
                res.status(400).json({ error: `docType must be one of: ${ALLOWED_DOC_TYPES.join(', ')}` });
                return;
            }

            const [techRows]: any = await pool.execute(
                'SELECT id FROM technician_profiles WHERE user_id = ?',
                [userId]
            );
            if (techRows.length === 0) {
                res.status(404).json({ error: 'Technician profile not found. Create your technician profile first.' });
                return;
            }
            const techId = techRows[0].id;

            const result = await storageService.uploadFile(
                file,
                userId,
                `kyc_${docType}`,
                String(techId),
                'PRIVATE'
            );

            const col = DOC_COLUMN_MAP[docType];
            if (docType === 'police_report') {
                await pool.execute(
                    `UPDATE technician_profiles SET ${col} = ?, police_report_status = 'RECEIPT_SUBMITTED' WHERE id = ?`,
                    [result.storageKey, techId]
                );
            } else {
                await pool.execute(
                    `UPDATE technician_profiles SET ${col} = ? WHERE id = ?`,
                    [result.storageKey, techId]
                );
            }

            res.status(200).json({
                success: true,
                docType,
                storageKey: result.storageKey
            });
        } catch (error: any) {
            console.error('KYC upload error:', error);
            res.status(500).json({ error: 'Failed to upload KYC document' });
        }
    }

    async submitKycDetails(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const { nicNumber, guarantorName, guarantorPhone } = req.body;

            if (nicNumber && !/^([0-9]{9}[vVxX]|[0-9]{12})$/.test(nicNumber.trim())) {
                res.status(400).json({ error: 'Invalid Sri Lankan NIC format (expected 9 digits + V/X or 12 digits)' });
                return;
            }

            await pool.execute(
                `UPDATE technician_profiles
                 SET nic_number = COALESCE(?, nic_number),
                     guarantor_name = COALESCE(?, guarantor_name),
                     guarantor_phone = COALESCE(?, guarantor_phone)
                 WHERE user_id = ?`,
                [nicNumber?.trim() || null, guarantorName?.trim() || null, guarantorPhone?.trim() || null, userId]
            );

            res.status(200).json({ success: true, message: 'KYC details saved' });
        } catch (error: any) {
            console.error('KYC details error:', error);
            res.status(500).json({ error: 'Failed to save KYC details' });
        }
    }

    async registerFcmToken(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const { fcmToken, deviceType } = req.body;

            if (!fcmToken) {
                res.status(400).json({ error: 'fcmToken is required' });
                return;
            }

            const [techRows]: any = await pool.execute(
                'SELECT id FROM technician_profiles WHERE user_id = ?',
                [userId]
            );
            if (techRows.length === 0) {
                res.status(404).json({ error: 'Technician profile not found' });
                return;
            }

            await notificationService.registerWorkerDevice(techRows[0].id, fcmToken, deviceType || 'ANDROID');
            res.status(200).json({ success: true });
        } catch (error: any) {
            console.error('FCM registration error:', error);
            res.status(500).json({ error: 'Failed to register device token' });
        }
    }

    async getNotifications(req: AuthRequest, res: Response): Promise<void> {
        try {
            const items = await notificationService.getUserNotifications(req.user!.userId);
            res.status(200).json(items);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to load notifications' });
        }
    }

    async markNotificationRead(req: AuthRequest, res: Response): Promise<void> {
        try {
            const id = parseInt(req.params.id as string, 10);
            await notificationService.markAsRead(id, req.user!.userId);
            res.status(200).json({ success: true });
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to mark notification read' });
        }
    }
}

export const kycController = new KycController();
