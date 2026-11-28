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
            const requestId = parseInt(req.params.id as string, 10);
            const data = req.body;

            const quote = await jobService.submitQuote(technicianId, requestId, data);
            res.status(201).json(quote);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to submit quote' });
        }
    }

    async acceptQuote(req: AuthRequest, res: Response): Promise<void> {
        try {
            const customerId = req.user!.userId;
            const quoteId = parseInt(req.params.id as string, 10);

            const job = await jobService.acceptQuote(customerId, quoteId);
            res.status(200).json(job);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to accept quote' });
        }
    }

    async getJobs(req: AuthRequest, res: Response): Promise<void> {
        try {
            const jobs = await jobService.getJobs(req.user!.userId, req.user!.role);
            res.status(200).json(jobs);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to fetch jobs' });
        }
    }

    async updateJobStatus(req: AuthRequest, res: Response): Promise<void> {
        try {
            const jobId = parseInt(req.params.id as string, 10);
            const { status, startPin, notes } = req.body;
            if (!status) {
                res.status(400).json({ error: 'status is required' });
                return;
            }
            const result = await jobService.updateJobStatus(jobId, req.user!.userId, req.user!.role, status, { startPin, notes });
            res.status(200).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message || 'Failed to update job status' });
        }
    }

    async uploadJobPhoto(req: AuthRequest, res: Response): Promise<void> {
        try {
            const jobId = parseInt(req.params.id as string, 10);
            const photoType = (req.body.photoType === 'after' ? 'after' : 'before') as 'before' | 'after';
            if (!req.file) {
                res.status(400).json({ error: 'Photo file is required' });
                return;
            }
            const result = await jobService.uploadJobPhoto(jobId, req.user!.userId, photoType, req.file);
            res.status(200).json(result);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to upload photo' });
        }
    }

    async submitReview(req: AuthRequest, res: Response): Promise<void> {
        try {
            const jobId = parseInt(req.params.id as string, 10);
            const { rating, behaviorTags, comment } = req.body;
            if (!rating || rating < 1 || rating > 5) {
                res.status(400).json({ error: 'rating between 1 and 5 is required' });
                return;
            }
            const reviewerRole = req.user!.role === 'TECHNICIAN' ? 'TECHNICIAN' : 'CUSTOMER';
            const result = await jobService.submitReview(jobId, req.user!.userId, reviewerRole, {
                rating: parseInt(rating, 10),
                behaviorTags,
                comment
            });
            res.status(201).json(result);
        } catch (error: any) {
            res.status(500).json({ error: error.message || 'Failed to submit review' });
        }
    }
}

export const jobController = new JobController();
