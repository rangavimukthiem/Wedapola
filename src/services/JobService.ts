import pool from '../config/db';
import { notificationService } from './NotificationService';
import { storageService } from './storage/StorageService';
import { UploadedFile } from './storage/StorageProvider';

export class JobService {
    private async getCustomerProfileId(userId: number): Promise<number> {
        const [rows]: any = await pool.execute('SELECT id FROM customer_profiles WHERE user_id = ?', [userId]);
        if (rows.length > 0) return rows[0].id;

        const [res]: any = await pool.execute(
            'INSERT INTO customer_profiles (user_id, name) VALUES (?, ?)',
            [userId, 'Wedapola Customer']
        );
        return res.insertId;
    }

    private async getTechnicianProfileId(userId: number): Promise<number> {
        const [rows]: any = await pool.execute('SELECT id FROM technician_profiles WHERE user_id = ?', [userId]);
        if (rows.length === 0) throw new Error('Technician profile not found');
        return rows[0].id;
    }

    async createRequest(userId: number, data: any) {
        const customerId = await this.getCustomerProfileId(userId);
        const query = `
            INSERT INTO service_requests
            (customer_id, category_id, description, latitude, longitude, urgency, preferred_time, equipment_provided, near_hazard, target_technician_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const [result]: any = await pool.execute(query, [
            customerId,
            data.categoryId,
            data.description,
            data.latitude,
            data.longitude,
            data.urgency || 'MEDIUM',
            data.preferredTime || null,
            data.equipmentProvided ? 1 : 0,
            data.nearHazard ? 1 : 0,
            data.targetTechnicianId || null
        ]);

        const requestId = result.insertId;

        // Trigger async geo-dispatch notification to nearby verified workers
        await notificationService.notifyNearbyWorkers(
            requestId,
            data.categoryId,
            parseFloat(data.latitude),
            parseFloat(data.longitude),
            data.targetTechnicianId || null
        );

        return { id: requestId, ...data };
    }

    async getRequests(userId: number, role: string) {
        if (role === 'CUSTOMER') {
            const customerId = await this.getCustomerProfileId(userId);
            const [rows]: any = await pool.execute(
                `SELECT sr.*, sc.name_en AS category_name_en, sc.name_si AS category_name_si
                 FROM service_requests sr
                 JOIN service_categories sc ON sr.category_id = sc.id
                 WHERE sr.customer_id = ?
                 ORDER BY sr.created_at DESC`,
                [customerId]
            );
            return rows;
        } else if (role === 'TECHNICIAN') {
            const [rows]: any = await pool.execute(
                `SELECT sr.*, sc.name_en AS category_name_en, sc.name_si AS category_name_si
                 FROM service_requests sr
                 JOIN service_categories sc ON sr.category_id = sc.id
                 WHERE sr.status IN ('REQUESTED', 'QUOTED')
                 ORDER BY sr.created_at DESC
                 LIMIT 50`
            );
            return rows;
        }
        return [];
    }

    async submitQuote(userId: number, requestId: number, data: any) {
        const technicianId = await this.getTechnicianProfileId(userId);
        const laborCost = parseFloat(data.laborCost);
        const materialCost = parseFloat(data.materialCost || 0);
        const total = laborCost + materialCost;

        const query = `
            INSERT INTO quotes (request_id, technician_id, labor_cost, material_cost, total, description, estimated_duration_hours, available_time)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const [result]: any = await pool.execute(query, [
            requestId,
            technicianId,
            laborCost,
            materialCost,
            total,
            data.description || null,
            data.estimatedDurationHours || null,
            data.availableTime || null
        ]);

        await pool.execute('UPDATE service_requests SET status = "QUOTED" WHERE id = ? AND status = "REQUESTED"', [requestId]);

        // Notify customer
        const [reqRows]: any = await pool.execute(
            `SELECT cp.user_id FROM service_requests sr JOIN customer_profiles cp ON sr.customer_id = cp.id WHERE sr.id = ?`,
            [requestId]
        );
        if (reqRows.length > 0) {
            await notificationService.sendNotification(
                reqRows[0].user_id,
                'IN_APP',
                'QUOTE_RECEIVED',
                'New Quote Received',
                `You received a quote of LKR ${total.toFixed(2)} for request #${requestId}.`
            );
        }

        return { id: result.insertId, total };
    }

    async acceptQuote(userId: number, quoteId: number) {
        const customerId = await this.getCustomerProfileId(userId);
        const [quotes]: any = await pool.execute('SELECT request_id, technician_id FROM quotes WHERE id = ?', [quoteId]);
        if (quotes.length === 0) throw new Error('Quote not found');
        const { request_id: requestId, technician_id: technicianId } = quotes[0];

        const [requests]: any = await pool.execute(
            'SELECT id FROM service_requests WHERE id = ? AND customer_id = ?',
            [requestId, customerId]
        );
        if (requests.length === 0) throw new Error('Unauthorized');

        await pool.execute('UPDATE quotes SET status = "ACCEPTED" WHERE id = ?', [quoteId]);
        await pool.execute('UPDATE quotes SET status = "REJECTED" WHERE request_id = ? AND id != ?', [requestId, quoteId]);

        const startPin = String(Math.floor(1000 + Math.random() * 9000));
        const [result]: any = await pool.execute(
            'INSERT INTO jobs (request_id, quote_id, technician_id, customer_id, status, start_pin) VALUES (?, ?, ?, ?, ?, ?)',
            [requestId, quoteId, technicianId, customerId, 'ACCEPTED', startPin]
        );
        const jobId = result.insertId;

        await pool.execute('UPDATE service_requests SET status = "ACCEPTED" WHERE id = ?', [requestId]);
        await pool.execute(
            'INSERT INTO job_status_history (job_id, status, notes, changed_by) VALUES (?, ?, ?, ?)',
            [jobId, 'ACCEPTED', 'Quote accepted by customer', userId]
        );

        const [techRows]: any = await pool.execute('SELECT user_id FROM technician_profiles WHERE id = ?', [technicianId]);
        if (techRows.length > 0) {
            await notificationService.sendNotification(
                techRows[0].user_id,
                'IN_APP',
                'QUOTE_ACCEPTED',
                'Quote Accepted!',
                `Your quote for request #${requestId} was accepted. Job #${jobId} is now active.`
            );
        }

        return { jobId, startPin };
    }

    async getJobs(userId: number, role: string) {
        if (role === 'CUSTOMER') {
            const customerId = await this.getCustomerProfileId(userId);
            const [rows]: any = await pool.execute(
                `SELECT j.*, tp.name AS technician_name, tp.phone AS technician_phone, q.total AS agreed_total
                 FROM jobs j
                 JOIN technician_profiles tp ON j.technician_id = tp.id
                 JOIN quotes q ON j.quote_id = q.id
                 WHERE j.customer_id = ?
                 ORDER BY j.created_at DESC`,
                [customerId]
            );
            return rows;
        } else if (role === 'TECHNICIAN') {
            const technicianId = await this.getTechnicianProfileId(userId);
            const [rows]: any = await pool.execute(
                `SELECT j.*, cp.name AS customer_name, cp.phone AS customer_phone, q.total AS agreed_total
                 FROM jobs j
                 JOIN customer_profiles cp ON j.customer_id = cp.id
                 JOIN quotes q ON j.quote_id = q.id
                 WHERE j.technician_id = ?
                 ORDER BY j.created_at DESC`,
                [technicianId]
            );
            return rows;
        }
        return [];
    }

    async updateJobStatus(
        jobId: number,
        userId: number,
        role: string,
        status: string,
        options: { startPin?: string; notes?: string } = {}
    ) {
        const [jobs]: any = await pool.execute('SELECT * FROM jobs WHERE id = ?', [jobId]);
        if (jobs.length === 0) throw new Error('Job not found');
        const job = jobs[0];

        if (role === 'TECHNICIAN') {
            const techId = await this.getTechnicianProfileId(userId);
            if (job.technician_id !== techId) throw new Error('Unauthorized');
        } else if (role === 'CUSTOMER') {
            const custId = await this.getCustomerProfileId(userId);
            if (job.customer_id !== custId) throw new Error('Unauthorized');
        }

        if (status === 'IN_PROGRESS') {
            if (job.start_pin && options.startPin !== job.start_pin) {
                throw new Error('Invalid start PIN provided by customer');
            }
            await pool.execute('UPDATE jobs SET status = ?, started_time = CURRENT_TIMESTAMP WHERE id = ?', [status, jobId]);
        } else if (status === 'COMPLETED') {
            await pool.execute('UPDATE jobs SET status = ?, completed_time = CURRENT_TIMESTAMP WHERE id = ?', [status, jobId]);
        } else {
            await pool.execute('UPDATE jobs SET status = ? WHERE id = ?', [status, jobId]);
        }

        await pool.execute('UPDATE service_requests SET status = ? WHERE id = ?', [status, job.request_id]);
        await pool.execute(
            'INSERT INTO job_status_history (job_id, status, notes, changed_by) VALUES (?, ?, ?, ?)',
            [jobId, status, options.notes || null, userId]
        );

        return { success: true, jobId, status };
    }

    async uploadJobPhoto(jobId: number, userId: number, photoType: 'before' | 'after', file: UploadedFile) {
        const [jobs]: any = await pool.execute('SELECT id FROM jobs WHERE id = ?', [jobId]);
        if (jobs.length === 0) throw new Error('Job not found');

        const result = await storageService.uploadFile(
            file,
            userId,
            `job_${photoType}_photo`,
            String(jobId),
            'PRIVATE'
        );

        const col = photoType === 'before' ? 'before_photo_key' : 'after_photo_key';
        await pool.execute(`UPDATE jobs SET ${col} = ? WHERE id = ?`, [result.storageKey, jobId]);

        return { success: true, photoType, storageKey: result.storageKey };
    }

    async submitReview(
        jobId: number,
        userId: number,
        role: 'CUSTOMER' | 'TECHNICIAN',
        data: { rating: number; behaviorTags?: string[]; comment?: string }
    ) {
        const [jobs]: any = await pool.execute(
            `SELECT j.*, cp.user_id AS customer_user_id, tp.user_id AS technician_user_id
             FROM jobs j
             JOIN customer_profiles cp ON j.customer_id = cp.id
             JOIN technician_profiles tp ON j.technician_id = tp.id
             WHERE j.id = ?`,
            [jobId]
        );
        if (jobs.length === 0) throw new Error('Job not found');
        const job = jobs[0];

        const targetUserId = role === 'CUSTOMER' ? job.technician_user_id : job.customer_user_id;
        // Hold 1-star or 2-star reviews in 24-hour admin quarantine queue
        const reviewStatus = data.rating <= 2 ? 'QUARANTINED' : 'PUBLISHED';

        const [result]: any = await pool.execute(
            `INSERT INTO reviews (job_id, reviewer_role, reviewer_id, target_id, rating, behavior_tags, comment, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                jobId,
                role,
                userId,
                targetUserId,
                data.rating,
                JSON.stringify(data.behaviorTags || []),
                data.comment || null,
                reviewStatus
            ]
        );

        if (role === 'CUSTOMER') {
            await pool.execute('UPDATE jobs SET status = "REVIEWED" WHERE id = ?', [jobId]);
            await pool.execute('UPDATE service_requests SET status = "REVIEWED" WHERE id = ?', [job.request_id]);

            if (reviewStatus === 'PUBLISHED') {
                await pool.execute(
                    `UPDATE technician_profiles tp
                     SET tp.rating = (SELECT COALESCE(AVG(r.rating), 0) FROM reviews r WHERE r.target_id = tp.user_id AND r.reviewer_role = 'CUSTOMER' AND r.status = 'PUBLISHED'),
                         tp.total_reviews = (SELECT COUNT(*) FROM reviews r WHERE r.target_id = tp.user_id AND r.reviewer_role = 'CUSTOMER' AND r.status = 'PUBLISHED'),
                         tp.completed_jobs_count = tp.completed_jobs_count + 1
                     WHERE tp.id = ?`,
                    [job.technician_id]
                );
            }
        }

        return {
            reviewId: result.insertId,
            status: reviewStatus,
            quarantined: reviewStatus === 'QUARANTINED'
        };
    }
}

export const jobService = new JobService();
