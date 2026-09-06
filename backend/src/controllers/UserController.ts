import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { userService } from '../services/UserService';

export class UserController {
    async getMe(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const role = req.user!.role;
            const profile = await userService.getUserProfile(userId, role);
            res.status(200).json(profile);
        } catch (error: any) {
            res.status(404).json({ error: error.message });
        }
    }

    async updateCustomerProfile(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const { name, phone } = req.body;
            
            if (!name) {
                res.status(400).json({ error: 'Name is required' });
                return;
            }

            const updatedProfile = await userService.updateCustomerProfile(userId, name, phone);
            res.status(200).json(updatedProfile);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to update profile' });
        }
    }

    async updateTechnicianProfile(req: AuthRequest, res: Response): Promise<void> {
        try {
            const userId = req.user!.userId;
            const { name, phone, bio, latitude, longitude, service_radius } = req.body;

            if (!name || latitude === undefined || longitude === undefined) {
                res.status(400).json({ error: 'Name and location are required' });
                return;
            }

            const updatedProfile = await userService.updateTechnicianProfile(userId, {
                name, phone, bio, latitude, longitude, service_radius: service_radius || 10
            });
            
            res.status(200).json(updatedProfile);
        } catch (error: any) {
            res.status(500).json({ error: 'Failed to update profile' });
        }
    }
}

export const userController = new UserController();
