import { Router } from 'express';
import multer from 'multer';
import { jobController } from '../controllers/JobController';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = Router();
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 }
});

router.use(authenticateToken);

// Requests
router.post('/requests', requireRole(['CUSTOMER']), jobController.createRequest.bind(jobController));
router.get('/requests', jobController.getRequests.bind(jobController));

// Quotes
router.post('/requests/:id/quotes', requireRole(['TECHNICIAN']), jobController.submitQuote.bind(jobController));
router.put('/quotes/:id/accept', requireRole(['CUSTOMER']), jobController.acceptQuote.bind(jobController));

// Jobs Lifecycle & Reviews
router.get('/jobs', jobController.getJobs.bind(jobController));
router.patch('/jobs/:id/status', jobController.updateJobStatus.bind(jobController));
router.post('/jobs/:id/photos', requireRole(['TECHNICIAN']), upload.single('file'), jobController.uploadJobPhoto.bind(jobController));
router.post('/jobs/:id/reviews', jobController.submitReview.bind(jobController));

export default router;
