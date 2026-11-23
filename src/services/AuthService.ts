import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import pool from '../config/db';

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export class AuthService {
    async verifyGoogleToken(token: string) {
        const ticket = await client.verifyIdToken({
            idToken: token,
            audience: process.env.GOOGLE_CLIENT_ID,
        });
        const payload = ticket.getPayload();
        return payload;
    }

    async findOrCreateUser(googleUserId: string, email: string, name: string) {
        // Find existing user
        const [rows]: any = await pool.execute(
            'SELECT * FROM users WHERE google_user_id = ?',
            [googleUserId]
        );

        if (rows.length > 0) {
            return rows[0];
        }

        // Create new user
        const [result]: any = await pool.execute(
            'INSERT INTO users (google_user_id, email, role) VALUES (?, ?, ?)',
            [googleUserId, email, 'CUSTOMER']
        );

        const userId = result.insertId;

        // Create initial customer profile
        await pool.execute(
            'INSERT INTO customer_profiles (user_id, name) VALUES (?, ?)',
            [userId, name]
        );

        // Fetch newly created user
        const [newUser]: any = await pool.execute(
            'SELECT * FROM users WHERE id = ?',
            [userId]
        );

        return newUser[0];
    }

    generateTokens(user: any) {
        const payload = {
            userId: user.id,
            role: user.role,
        };

        const accessToken = jwt.sign(
            payload, 
            process.env.JWT_SECRET || 'dev_jwt_secret', 
            { expiresIn: '15m' }
        );

        const refreshToken = jwt.sign(
            payload, 
            process.env.JWT_REFRESH_SECRET || 'dev_refresh_secret', 
            { expiresIn: '7d' }
        );

        return { accessToken, refreshToken };
    }
}

export const authService = new AuthService();
