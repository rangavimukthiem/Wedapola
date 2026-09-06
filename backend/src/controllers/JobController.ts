import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { jobService } from '../services/JobService';

export class JobController {
    async createRequest(req: AuthRequest, res: Response): Promise<void> {
        try {
            const customerId = req.user!.userId;
            const data = req.body;
            
            if (!data.categoryId || !data.description || !data.latitude || !data.longitude) {
                res.status(400).json({ error: 'Missing required fields' });
                return;
            }

            const request = await jobService.createRequest(customerId, data);
            res.status(201).json(request);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to create request' });
        }
    }

    async getRequests(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const role = req.user!.role;
            const requests = await jobService.getRequests(userId, role);
            res.status(200).json(requests);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to fetch requests' });
        }
    }

    async submitQuote(req: AuthRequest, res: Response): Promise<void> {
        try {
            const technicianId = req.user!.userId;
            const requestId = parseInt(req.params.id);
            const data = req.body;

            const quote = await jobService.submitQuote(technicianId, requestId, data);
            res.status(201).json(quote);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to submit quote' });
        }
    }

    async acceptQuote(req: AuthRequest, res: Response): Promise<void> {
        try {
            const customerId = req.user!.userId;
            const quoteId = parseInt(req.params.id);

            const job = await jobService.acceptQuote(customerId, quoteId);
            res.status(200).json(job);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to accept quote' });
        }
    }
}

export const jobController = new JobController();
