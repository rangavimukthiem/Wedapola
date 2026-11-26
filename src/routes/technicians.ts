import { Router } from 'express';
import { technicianController } from '../controllers/TechnicianController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// Public routes for Customer Job Portal
router.get('/available', technicianController.getAvailable.bind(technicianController));
router.post('/inquiry', technicianController.submitInquiry.bind(technicianController));

// Authenticated route for mobile app
router.get('/nearby', authenticateToken, technicianController.getNearby.bind(technicianController));

export default router;
