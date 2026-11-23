import { Request, Response } from 'express';
import { technicianService } from '../services/TechnicianService';

export class TechnicianController {
    async getNearby(req: Request, res: Response): Promise<void> {
        try {
            const { categoryId, latitude, longitude, radius } = req.query;

            if (!categoryId || !latitude || !longitude) {
                res.status(400).json({ error: 'categoryId, latitude, and longitude are required' });
                return;
            }

            const technicians = await technicianService.findNearby(
                parseInt(categoryId as string),
                parseFloat(latitude as string),
                parseFloat(longitude as string),
                radius ? parseFloat(radius as string) : 20
            );

            res.status(200).json(technicians);
        } catch (error: any) {
            console.error('Error fetching nearby technicians:', error);
            res.status(500).json({ error: 'Failed to fetch nearby technicians' });
        }
    }
}

export const technicianController = new TechnicianController();
