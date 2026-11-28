import { Request, Response } from 'express';
import { adminService } from '../services/AdminService';

export class AdminController {
    async login(req: Request, res: Response): Promise<void> {
        try {
            const { username, password } = req.body;
            if (!username || !password) {
                res.status(400).json({ error: 'Username and password are required' });
                return;
            }

            const result = await adminService.authenticate(username, password);
            res.status(200).json(result);
        } catch (error: any) {
            res.status(401).json({ error: error.message || 'Authentication failed' });
        }
    }

    async getStats(req: Request, res: Response): Promise<void> {
        try {
            const stats = await adminService.getStats();
            res.status(200).json(stats);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to retrieve stats' });
        }
    }

    async getTechnicians(req: Request, res: Response): Promise<void> {
        try {
            const { status, search } = req.query;
            const technicians = await adminService.getTechnicians(status as string, search as string);
            res.status(200).json(technicians);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to retrieve technicians' });
        }
    }

    async createTechnician(req: Request, res: Response): Promise<void> {
        try {
            const { name, phone, nicNumber, bio, verificationStatus, categoryId, latitude, longitude } = req.body;
            if (!name || !phone) {
                res.status(400).json({ error: 'Name and phone are required' });
                return;
            }

            const result = await adminService.createTechnician({
                name,
                phone,
                nicNumber,
                bio,
                verificationStatus,
                categoryId: categoryId ? parseInt(categoryId, 10) : undefined,
                latitude: latitude ? parseFloat(latitude) : undefined,
                longitude: longitude ? parseFloat(longitude) : undefined
            });

            res.status(201).json(result);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to create technician' });
        }
    }

    async updateTechnicianStatus(req: Request, res: Response): Promise<void> {
        try {
            const id = parseInt(req.params.id as string, 10);
            const { status } = req.body;
            if (!status) {
                res.status(400).json({ error: 'Status is required' });
                return;
            }

            const result = await adminService.updateTechnicianStatus(id, status);
            res.status(200).json(result);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to update technician status' });
        }
    }

    async getInquiries(req: Request, res: Response): Promise<void> {
        try {
            const inquiries = await adminService.getInquiries();
            res.status(200).json(inquiries);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to retrieve inquiries' });
        }
    }

    async updateInquiryStatus(req: Request, res: Response): Promise<void> {
        try {
            const id = parseInt(req.params.id as string, 10);
            const { status } = req.body;
            const result = await adminService.updateInquiryStatus(id, status);
            res.status(200).json(result);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to update inquiry status' });
        }
    }

    async getQuarantinedReviews(req: Request, res: Response): Promise<void> {
        try {
            const reviews = await adminService.getQuarantinedReviews();
            res.status(200).json(reviews);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to retrieve quarantined reviews' });
        }
    }

    async updateReviewStatus(req: Request, res: Response): Promise<void> {
        try {
            const id = parseInt(req.params.id as string, 10);
            const { status } = req.body;
            if (!['PUBLISHED', 'QUARANTINED', 'DISPUTED'].includes(status)) {
                res.status(400).json({ error: 'Invalid review status' });
                return;
            }
            const result = await adminService.updateReviewStatus(id, status);
            res.status(200).json(result);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to update review status' });
        }
    }
}

export const adminController = new AdminController();
