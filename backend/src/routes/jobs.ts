import { Router } from 'express';
import { jobController } from '../controllers/JobController';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);

// Requests
router.post('/requests', requireRole(['CUSTOMER']), jobController.createRequest.bind(jobController));
router.get('/requests', jobController.getRequests.bind(jobController));

// Quotes
router.post('/requests/:id/quotes', requireRole(['TECHNICIAN']), jobController.submitQuote.bind(jobController));
router.put('/quotes/:id/accept', requireRole(['CUSTOMER']), jobController.acceptQuote.bind(jobController));

export default router;
