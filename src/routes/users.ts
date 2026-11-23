import { Router } from 'express';
import { userController } from '../controllers/UserController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// All user routes require authentication
router.use(authenticateToken);

router.get('/me', userController.getMe.bind(userController));
router.put('/customer-profile', userController.updateCustomerProfile.bind(userController));
router.put('/technician-profile', userController.updateTechnicianProfile.bind(userController));

export default router;
