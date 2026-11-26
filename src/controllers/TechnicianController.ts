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

    async getAvailable(req: Request, res: Response): Promise<void> {
        try {
            const { categoryId, latitude, longitude, radius, search, status } = req.query;

            const technicians = await technicianService.findAvailable({
                categoryId: categoryId ? parseInt(categoryId as string, 10) : undefined,
                latitude: latitude ? parseFloat(latitude as string) : undefined,
                longitude: longitude ? parseFloat(longitude as string) : undefined,
                maxDistanceKm: radius ? parseFloat(radius as string) : 50,
                search: search ? (search as string) : undefined,
                verificationStatus: status ? (status as string) : undefined
            });

            res.status(200).json({
                success: true,
                count: technicians.length,
                data: technicians
            });
        } catch (error: any) {
            console.error('Error fetching available technicians:', error);
            res.status(500).json({ error: 'Failed to retrieve available technicians' });
        }
    }

    async submitInquiry(req: Request, res: Response): Promise<void> {
        try {
            const { customerName, customerPhone, categoryId, technicianId, description, urgency, city } = req.body;

            if (!customerName || !customerPhone || !description) {
                res.status(400).json({ error: 'customerName, customerPhone, and description are required' });
                return;
            }

            const result = await technicianService.submitCustomerInquiry({
                customerName,
                customerPhone,
                categoryId: categoryId ? parseInt(categoryId, 10) : undefined,
                technicianId: technicianId ? parseInt(technicianId, 10) : undefined,
                description,
                urgency,
                city
            });

            res.status(201).json(result);
        } catch (error: any) {
            console.error('Error submitting customer inquiry:', error);
            res.status(500).json({ error: 'Failed to submit inquiry' });
        }
    }
}

export const technicianController = new TechnicianController();
