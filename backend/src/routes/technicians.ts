import { Router } from 'express';
import { technicianController } from '../controllers/TechnicianController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// Nearby search is protected (only authenticated users can search)
router.get('/nearby', authenticateToken, technicianController.getNearby.bind(technicianController));

export default router;
