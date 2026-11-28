import pool from '../config/db';
import { getFirebaseMessaging } from './FirebaseAdmin';

export type NotificationChannel = 'PUSH' | 'WHATSAPP' | 'SMS' | 'IN_APP';

export class NotificationService {
    async sendNotification(
        userId: number,
        channel: NotificationChannel,
        type: string,
        title: string,
        body: string
    ) {
        let deliveredByPush = false;

        try {
            deliveredByPush = await this.sendPushToUser(userId, title, body, { type });
        } catch (err) {
            console.warn('Failed to send FCM notification:', err);
        }

        try {
            await pool.execute(
                `INSERT INTO notifications (user_id, channel, type, title, body) VALUES (?, ?, ?, ?, ?)`,
                [userId, deliveredByPush ? 'PUSH' : channel === 'PUSH' ? 'IN_APP' : channel, type, title, body]
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

    private async sendPushToUser(userId: number, title: string, body: string, data: Record<string, string>) {
        const firebaseMessaging = getFirebaseMessaging();
        if (!firebaseMessaging) return false;

        const [rows]: any = await pool.execute(
            `SELECT wd.fcm_token
             FROM worker_devices wd
             JOIN technician_profiles tp ON tp.id = wd.worker_id
             WHERE tp.user_id = ?`,
            [userId]
        );
        const tokens: string[] = rows.map((row: any) => row.fcm_token);
        if (tokens.length === 0) return false;

        for (let offset = 0; offset < tokens.length; offset += 500) {
            const batch = tokens.slice(offset, offset + 500);
            const response = await firebaseMessaging.sendEachForMulticast({
                tokens: batch,
                notification: { title, body },
                data,
                android: { priority: 'high' },
                apns: { payload: { aps: { sound: 'default' } } },
            });

            for (let i = 0; i < response.responses.length; i++) {
                const result = response.responses[i];
                if (!result.success && (
                    result.error?.code === 'messaging/registration-token-not-registered' ||
                    result.error?.code === 'messaging/invalid-registration-token'
                )) {
                    await pool.execute('DELETE FROM worker_devices WHERE fcm_token = ?', [batch[i]]);
                }
            }

            if (response.successCount > 0) return true;
        }

        return false;
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

            await Promise.all(workers.map((w) => this.sendNotification(
                    w.user_id,
                    'IN_APP',
                    'NEW_JOB_LEAD',
                    'New Job Nearby • අලුත් වැඩක්!',
                    `Request #${requestId} is available in your service area. Open Wedapola to submit a quote.`
                )));

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
