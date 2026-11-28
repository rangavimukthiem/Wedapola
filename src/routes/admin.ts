import { Router } from 'express';
import { adminController } from '../controllers/AdminController';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = Router();

// Public Admin Login
router.post('/login', adminController.login.bind(adminController));

// Protected Admin Routes
router.use(authenticateToken);
router.use(requireRole(['ADMIN']));

router.get('/stats', adminController.getStats.bind(adminController));
router.get('/technicians', adminController.getTechnicians.bind(adminController));
router.post('/technicians', adminController.createTechnician.bind(adminController));
router.patch('/technicians/:id/status', adminController.updateTechnicianStatus.bind(adminController));
router.get('/inquiries', adminController.getInquiries.bind(adminController));
router.patch('/inquiries/:id/status', adminController.updateInquiryStatus.bind(adminController));
router.get('/reviews/quarantine', adminController.getQuarantinedReviews.bind(adminController));
router.patch('/reviews/:id/status', adminController.updateReviewStatus.bind(adminController));

export default router;
