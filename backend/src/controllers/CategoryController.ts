import { Request, Response } from 'express';
import { categoryService } from '../services/CategoryService';

export class CategoryController {
    async getCategories(req: Request, res: Response): Promise<void> {
        try {
            const categories = await categoryService.getCategories();
            res.status(200).json(categories);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to fetch categories' });
        }
    }
}

export const categoryController = new CategoryController();
