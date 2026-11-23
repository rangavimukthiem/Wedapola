import { Router } from 'express';
import { categoryController } from '../controllers/CategoryController';

const router = Router();

router.get('/', categoryController.getCategories.bind(categoryController));

export default router;
