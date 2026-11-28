import { Router } from 'express';
import multer from 'multer';
import { kycController } from '../controllers/KycController';
import { authenticateToken } from '../middleware/auth';

const router = Router();
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB max per KYC document
});

router.use(authenticateToken);

router.post('/upload', upload.single('file'), kycController.uploadDocument.bind(kycController));
router.put('/details', kycController.submitKycDetails.bind(kycController));
router.post('/fcm-token', kycController.registerFcmToken.bind(kycController));
router.get('/notifications', kycController.getNotifications.bind(kycController));
router.patch('/notifications/:id/read', kycController.markNotificationRead.bind(kycController));

export default router;
