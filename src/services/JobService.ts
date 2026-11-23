import pool from '../config/db';

export class JobService {
    async createRequest(customerId: number, data: any) {
        const query = `
            INSERT INTO service_requests (customer_id, category_id, description, latitude, longitude, urgency, preferred_time)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;
        const [result]: any = await pool.execute(query, [
            customerId, data.categoryId, data.description, data.latitude, data.longitude, data.urgency, data.preferredTime || null
        ]);
        
        return { id: result.insertId, ...data };
    }

    async getRequests(userId: number, role: string) {
        if (role === 'CUSTOMER') {
            const [rows]: any = await pool.execute('SELECT * FROM service_requests WHERE customer_id = ? ORDER BY created_at DESC', [userId]);
            return rows;
        } else if (role === 'TECHNICIAN') {
            // Get requests nearby or matching category logic (for now, simply return all requests where status = REQUESTED for MVP)
            const [rows]: any = await pool.execute('SELECT * FROM service_requests WHERE status = "REQUESTED" ORDER BY created_at DESC');
            return rows;
        }
        return [];
    }

    async submitQuote(technicianId: number, requestId: number, data: any) {
        const query = `
            INSERT INTO quotes (request_id, technician_id, labor_cost, material_cost, total, description, estimated_duration_hours, available_time)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const total = parseFloat(data.laborCost) + parseFloat(data.materialCost);

        const [result]: any = await pool.execute(query, [
            requestId, technicianId, data.laborCost, data.materialCost, total, data.description, data.estimatedDurationHours, data.availableTime
        ]);

        await pool.execute('UPDATE service_requests SET status = "QUOTED" WHERE id = ?', [requestId]);

        return { id: result.insertId, total };
    }

    async acceptQuote(customerId: number, quoteId: number) {
        const [quotes]: any = await pool.execute('SELECT request_id FROM quotes WHERE id = ?', [quoteId]);
        if (quotes.length === 0) throw new Error('Quote not found');
        const requestId = quotes[0].request_id;

        // Verify request belongs to customer
        const [requests]: any = await pool.execute('SELECT id FROM service_requests WHERE id = ? AND customer_id = ?', [requestId, customerId]);
        if (requests.length === 0) throw new Error('Unauthorized');

        await pool.execute('UPDATE quotes SET status = "ACCEPTED" WHERE id = ?', [quoteId]);
        await pool.execute('UPDATE quotes SET status = "REJECTED" WHERE request_id = ? AND id != ?', [requestId, quoteId]);
        
        const [result]: any = await pool.execute(
            'INSERT INTO jobs (request_id, quote_id, status) VALUES (?, ?, ?)',
            [requestId, quoteId, 'ACCEPTED']
        );

        await pool.execute('UPDATE service_requests SET status = "ACCEPTED" WHERE id = ?', [requestId]);

        return { jobId: result.insertId };
    }
}

export const jobService = new JobService();
