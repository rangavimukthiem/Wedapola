import pool from '../config/db';

export class TechnicianService {
    async findNearby(categoryId: number, latitude: number, longitude: number, maxDistanceKm: number = 20) {
        // Find verified technicians who offer the specified service category
        // Calculate distance using Haversine formula
        const query = `
            SELECT t.id, t.user_id, t.name, t.phone, t.bio, t.rating, t.latitude, t.longitude, t.service_radius,
            (6371 * acos(cos(radians(?)) * cos(radians(t.latitude)) * cos(radians(t.longitude) - radians(?)) + sin(radians(?)) * sin(radians(t.latitude)))) AS distance
            FROM technician_profiles t
            JOIN technician_services ts ON t.id = ts.technician_id
            WHERE ts.category_id = ? 
            AND t.verification_status IN ('BASIC_VERIFIED', 'TRUSTED', 'PRO')
            AND t.is_available = TRUE
            HAVING distance <= t.service_radius AND distance <= ?
            ORDER BY distance ASC
        `;

        const [rows]: any = await pool.execute(query, [latitude, longitude, latitude, categoryId, maxDistanceKm]);
        return rows;
    }
}

export const technicianService = new TechnicianService();
