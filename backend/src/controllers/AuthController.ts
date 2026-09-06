import { Request, Response } from 'express';
import { authService } from '../services/AuthService';

export class AuthController {
    async googleLogin(req: Request, res: Response): Promise<void> {
        try {
            const { token } = req.body;
            
            if (!token) {
                res.status(400).json({ error: 'Token is required' });
                return;
            }

            const payload = await authService.verifyGoogleToken(token);
            
            if (!payload || !payload.sub || !payload.email) {
                res.status(401).json({ error: 'Invalid Google token' });
                return;
            }

            const user = await authService.findOrCreateUser(
                payload.sub, 
                payload.email, 
                payload.name || 'User'
            );

            const tokens = authService.generateTokens(user);

            res.status(200).json({
                user: {
                    id: user.id,
                    email: user.email,
                    role: user.role,
                    status: user.status
                },
                tokens
            });
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({ error: 'Authentication failed' });
        }
    }
}

export const authController = new AuthController();
