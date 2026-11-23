import pool from '../config/db';

export class UserService {
    async getUserProfile(userId: number, role: string) {
        const [userRows]: any = await pool.execute('SELECT id, email, role, status FROM users WHERE id = ?', [userId]);
        if (userRows.length === 0) throw new Error('User not found');
        const user = userRows[0];

        if (role === 'CUSTOMER') {
            const [profileRows]: any = await pool.execute('SELECT * FROM customer_profiles WHERE user_id = ?', [userId]);
            return { ...user, profile: profileRows[0] };
        } else if (role === 'TECHNICIAN') {
            const [profileRows]: any = await pool.execute('SELECT * FROM technician_profiles WHERE user_id = ?', [userId]);
            return { ...user, profile: profileRows[0] };
        }
        
        return user;
    }

    async updateCustomerProfile(userId: number, name: string, phone: string) {
        await pool.execute(
            'UPDATE customer_profiles SET name = ?, phone = ? WHERE user_id = ?',
            [name, phone, userId]
        );
        return this.getUserProfile(userId, 'CUSTOMER');
    }

    async updateTechnicianProfile(userId: number, data: any) {
        // Find existing or insert new profile
        const [existing]: any = await pool.execute('SELECT id FROM technician_profiles WHERE user_id = ?', [userId]);
        
        if (existing.length > 0) {
            await pool.execute(
                'UPDATE technician_profiles SET name = ?, phone = ?, bio = ?, latitude = ?, longitude = ?, service_radius = ? WHERE user_id = ?',
                [data.name, data.phone, data.bio, data.latitude, data.longitude, data.service_radius, userId]
            );
        } else {
            await pool.execute(
                'INSERT INTO technician_profiles (user_id, name, phone, bio, latitude, longitude, service_radius) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [userId, data.name, data.phone, data.bio, data.latitude, data.longitude, data.service_radius]
            );
            // Upgrade role if first time
            await pool.execute('UPDATE users SET role = "TECHNICIAN" WHERE id = ?', [userId]);
        }
        return this.getUserProfile(userId, 'TECHNICIAN');
    }
}

export const userService = new UserService();
