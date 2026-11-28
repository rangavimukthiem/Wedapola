import pool from '../config/db';

export type NotificationChannel = 'PUSH' | 'WHATSAPP' | 'SMS' | 'IN_APP';

export class NotificationService {
    async sendNotification(
        userId: number,
        channel: NotificationChannel,
        type: string,
        title: string,
        body: string
    ) {
        try {
            await pool.execute(
                `INSERT INTO notifications (user_id, channel, type, title, body) VALUES (?, ?, ?, ?, ?)`,
                [userId, channel, type, title, body]
            );
        } catch (err) {
            console.warn('Failed to persist notification:', err);
        }
    }

    async registerWorkerDevice(workerId: number, fcmToken: string, deviceType: 'ANDROID' | 'IOS' | 'WEB' = 'ANDROID') {
        await pool.execute(
            `INSERT INTO worker_devices (worker_id, fcm_token, device_type)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE worker_id = VALUES(worker_id), device_type = VALUES(device_type), updated_at = CURRENT_TIMESTAMP`,
            [workerId, fcmToken, deviceType]
        );
        return { success: true };
    }

    async notifyNearbyWorkers(
        requestId: number,
        categoryId: number,
        latitude: number,
        longitude: number,
        targetTechnicianId?: number | null
    ) {
        try {
            let workers: any[] = [];
            if (targetTechnicianId) {
                const [rows]: any = await pool.execute(
                    `SELECT t.id, t.user_id, t.name, t.phone
                     FROM technician_profiles t
                     WHERE t.id = ? AND t.is_available = TRUE`,
                    [targetTechnicianId]
                );
                workers = rows;
            } else {
                const [rows]: any = await pool.execute(
                    `SELECT t.id, t.user_id, t.name, t.phone,
                            (6371 * acos(LEAST(1.0, GREATEST(-1.0, cos(radians(?)) * cos(radians(t.latitude)) * cos(radians(t.longitude) - radians(?)) + sin(radians(?)) * sin(radians(t.latitude)))))) AS distance_km
                     FROM technician_profiles t
                     JOIN technician_services ts ON t.id = ts.technician_id
                     WHERE ts.category_id = ?
                       AND t.is_available = TRUE
                       AND t.verification_status IN ('BASIC_VERIFIED', 'TRUSTED', 'PRO')
                     HAVING distance_km <= t.service_radius
                     ORDER BY t.rating DESC, distance_km ASC
                     LIMIT 20`,
                    [latitude, longitude, latitude, categoryId]
                );
                workers = rows;
            }

            for (const w of workers) {
                const channel: NotificationChannel = process.env.FIREBASE_PROJECT_ID ? 'PUSH' : 'IN_APP';
                await this.sendNotification(
                    w.user_id,
                    channel,
                    'NEW_JOB_LEAD',
                    'New Job Nearby • අලුත් වැඩක්!',
                    `Request #${requestId} is available in your service area. Open Wedapola to submit a quote.`
                );
            }

            return { notifiedCount: workers.length };
        } catch (err) {
            console.warn('Geo-dispatch notification skipped/failed:', err);
            return { notifiedCount: 0 };
        }
    }

    async getUserNotifications(userId: number) {
        const [rows]: any = await pool.execute(
            `SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50`,
            [userId]
        );
        return rows;
    }

    async markAsRead(notificationId: number, userId: number) {
        await pool.execute(
            `UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?`,
            [notificationId, userId]
        );
        return { success: true };
    }
}

export const notificationService = new NotificationService();
