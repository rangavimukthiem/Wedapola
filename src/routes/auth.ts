// @ts-ignore: Express is provided by the application environment.
import { Router } from 'express';
import { authController } from '../controllers/AuthController';

const router = Router();

router.post('/google', authController.googleLogin.bind(authController));

export default router;
