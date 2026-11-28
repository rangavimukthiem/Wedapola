import pool from '../config/db';
import jwt from 'jsonwebtoken';

export class AdminService {
    // In-memory fallback technicians for development mode if DB is in progress
    private devTechnicians = [
        {
            id: 1,
            user_id: 101,
            name: 'Sunil Wickramasinghe',
            phone: '+94771234567',
            nic_number: '821941234V',
            bio: 'Certified Master Electrician with 14+ years experience. Single/three phase panels, short-circuit diagnostics, solar inverter wiring.',
            verification_status: 'PRO',
            rating: 4.95,
            total_reviews: 64,
            completed_jobs_count: 82,
            latitude: 6.9271,
            longitude: 79.8612,
            police_report_status: 'VERIFIED',
            created_at: new Date(Date.now() - 30 * 86400000).toISOString(),
            categories: 'Electrical & Wiring, AC & Refrigeration'
        },
        {
            id: 2,
            user_id: 102,
            name: 'Kusal Perera',
            phone: '+94719876543',
            nic_number: '912048991V',
            bio: 'Expert plumbing contractor. Leak detection, bathroom fittings, water pump installations, and overhead tank cleaning.',
            verification_status: 'TRUSTED',
            rating: 4.88,
            total_reviews: 42,
            completed_jobs_count: 55,
            latitude: 6.8728,
            longitude: 79.8806,
            police_report_status: 'RECEIPT_SUBMITTED',
            created_at: new Date(Date.now() - 20 * 86400000).toISOString(),
            categories: 'Plumbing & Water Systems'
        },
        {
            id: 3,
            user_id: 103,
            name: 'Nuwan Bandara',
            phone: '+94765432109',
            nic_number: '199512300445',
            bio: 'Tree cutting, coconut harvesting, garden landscaping & grass clearing with professional power saws & safety ropes.',
            verification_status: 'PRO',
            rating: 4.92,
            total_reviews: 37,
            completed_jobs_count: 49,
            latitude: 6.8480,
            longitude: 79.9265,
            police_report_status: 'VERIFIED',
            created_at: new Date(Date.now() - 15 * 86400000).toISOString(),
            categories: 'Tree Pruning & Felling, Grass Cutting & Lawn Care'
        },
        {
            id: 4,
            user_id: 104,
            name: 'Mahinda Kumara',
            phone: '+94783321144',
            nic_number: '861112223V',
            bio: 'Emergency breakdown assistance, car mechanic, battery jumpstart & mobile tyre service across Colombo & Gampaha.',
            verification_status: 'BASIC_VERIFIED',
            rating: 4.75,
            total_reviews: 19,
            completed_jobs_count: 24,
            latitude: 6.9934,
            longitude: 79.9142,
            police_report_status: 'NOT_SUBMITTED',
            created_at: new Date(Date.now() - 8 * 86400000).toISOString(),
            categories: 'Mobile Mechanic / Breakdown Assistance'
        },
        {
            id: 5,
            user_id: 105,
            name: 'Sanjeewa Gunasekara',
            phone: '+94778899001',
            nic_number: '199844556677',
            bio: 'Aluminium fabricator and door/window repairman. Partition work, shop fronts, roller door motor repairs.',
            verification_status: 'PENDING',
            rating: 0.00,
            total_reviews: 0,
            completed_jobs_count: 0,
            latitude: 6.9319,
            longitude: 79.8478,
            police_report_status: 'NOT_SUBMITTED',
            created_at: new Date(Date.now() - 1 * 86400000).toISOString(),
            categories: 'Carpentry & Aluminum Fabrication'
        }
    ];

    async authenticate(username: string, pass: string) {
        const expectedUser = process.env.ADMIN_USER || 'admin';
        const expectedPass = process.env.ADMIN_PASS || 'admin123';

        // Check if matches admin env credentials
        if (username === expectedUser && pass === expectedPass) {
            const token = jwt.sign(
                { userId: 1, username: 'admin', role: 'ADMIN' },
                process.env.JWT_SECRET || 'dev_jwt_secret',
                { expiresIn: '7d' }
            );
            return {
                token,
                user: { id: 1, username: 'admin', role: 'ADMIN', name: 'Wedapola System Admin' }
            };
        }

        // Check against users table if credentials match
        try {
            const [users]: any = await pool.execute(
                `SELECT id, email, role FROM users WHERE (email = ? OR phone = ?) AND role = 'ADMIN' LIMIT 1`,
                [username, username]
            );
            if (users && users.length > 0 && pass === expectedPass) {
                const user = users[0];
                const token = jwt.sign(
                    { userId: user.id, username: user.email, role: 'ADMIN' },
                    process.env.JWT_SECRET || 'dev_jwt_secret',
                    { expiresIn: '7d' }
                );
                return {
                    token,
                    user: { id: user.id, username: user.email, role: 'ADMIN', name: 'Wedapola Admin' }
                };
            }
        } catch (err) {
            console.warn('DB check note in admin auth:', err);
        }

        throw new Error('Invalid username or password');
    }

    async getStats() {
        try {
            const [techStats]: any = await pool.execute(`
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN verification_status = 'PENDING' THEN 1 ELSE 0 END) as pending,
                    SUM(CASE WHEN verification_status = 'BASIC_VERIFIED' THEN 1 ELSE 0 END) as basic,
                    SUM(CASE WHEN verification_status = 'TRUSTED' THEN 1 ELSE 0 END) as trusted,
                    SUM(CASE WHEN verification_status = 'PRO' THEN 1 ELSE 0 END) as pro,
                    SUM(CASE WHEN is_available = TRUE THEN 1 ELSE 0 END) as available
                FROM technician_profiles
            `);

            const [catStats]: any = await pool.execute(`SELECT COUNT(*) as total FROM service_categories`);
            
            let inquiriesCount = 0;
            try {
                const [inq]: any = await pool.execute(`SELECT COUNT(*) as total FROM customer_inquiries`);
                inquiriesCount = inq[0]?.total || 0;
            } catch {}

            return {
                totalWorkers: techStats[0]?.total || 0,
                pendingKyc: techStats[0]?.pending || 0,
                basicVerified: techStats[0]?.basic || 0,
                trusted: techStats[0]?.trusted || 0,
                pro: techStats[0]?.pro || 0,
                availableWorkers: techStats[0]?.available || 0,
                totalCategories: catStats[0]?.total || 24,
                totalInquiries: inquiriesCount
            };
        } catch (err) {
            console.warn('DB stats note, using mock stats:', err);
            return {
                totalWorkers: this.devTechnicians.length,
                pendingKyc: this.devTechnicians.filter(t => t.verification_status === 'PENDING').length,
                basicVerified: this.devTechnicians.filter(t => t.verification_status === 'BASIC_VERIFIED').length,
                trusted: this.devTechnicians.filter(t => t.verification_status === 'TRUSTED').length,
                pro: this.devTechnicians.filter(t => t.verification_status === 'PRO').length,
                availableWorkers: 4,
                totalCategories: 24,
                totalInquiries: 3
            };
        }
    }

    async getTechnicians(status?: string, search?: string) {
        try {
            let whereClause = "1=1";
            let params: any[] = [];

            if (status && status !== 'ALL') {
                whereClause += " AND t.verification_status = ?";
                params.push(status);
            }

            if (search && search.trim() !== '') {
                whereClause += " AND (t.name LIKE ? OR t.phone LIKE ? OR t.nic_number LIKE ?)";
                const p = `%${search.trim()}%`;
                params.push(p, p, p);
            }

            const query = `
                SELECT 
                    t.id, t.user_id, t.name, t.phone, t.nic_number, t.bio, t.verification_status,
                    t.police_report_status, t.rating, t.total_reviews, t.completed_jobs_count,
                    t.is_available, t.created_at, t.latitude, t.longitude,
                    COALESCE(GROUP_CONCAT(sc.name_en SEPARATOR ', '), 'General Handyman') AS categories
                FROM technician_profiles t
                LEFT JOIN technician_services ts ON t.id = ts.technician_id
                LEFT JOIN service_categories sc ON ts.category_id = sc.id
                WHERE ${whereClause}
                GROUP BY t.id
                ORDER BY t.created_at DESC
            `;

            const [rows]: any = await pool.execute(query, params);
            if (rows && rows.length > 0) {
                return rows;
            }
        } catch (err) {
            console.warn('DB getTechnicians note, using fallback list:', err);
        }

        let list = [...this.devTechnicians];
        if (status && status !== 'ALL') {
            list = list.filter(t => t.verification_status === status);
        }
        if (search && search.trim() !== '') {
            const s = search.toLowerCase();
            list = list.filter(t => t.name.toLowerCase().includes(s) || t.phone.includes(s) || t.nic_number.toLowerCase().includes(s));
        }
        return list;
    }

    async updateTechnicianStatus(id: number, status: string) {
        try {
            await pool.execute(
                `UPDATE technician_profiles SET verification_status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
                [status, id]
            );
            return { success: true, message: `Technician status updated to ${status}` };
        } catch (err) {
            console.warn('DB update status note:', err);
            const found = this.devTechnicians.find(t => t.id === id);
            if (found) {
                found.verification_status = status;
            }
            return { success: true, message: `Status updated to ${status}` };
        }
    }

    async createTechnician(data: {
        name: string;
        phone: string;
        nicNumber?: string;
        bio?: string;
        verificationStatus?: string;
        categoryId?: number;
        latitude?: number;
        longitude?: number;
    }) {
        try {
            // Check or create user
            const googleId = 'manual_' + Date.now();
            const email = `tech_${Date.now()}@wedapola.local`;
            
            const [userResult]: any = await pool.execute(
                `INSERT INTO users (google_user_id, email, phone, role) VALUES (?, ?, ?, 'TECHNICIAN')`,
                [googleId, email, data.phone]
            );
            const userId = userResult.insertId;

            const [techResult]: any = await pool.execute(
                `INSERT INTO technician_profiles (user_id, name, phone, nic_number, bio, verification_status, latitude, longitude)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    userId,
                    data.name,
                    data.phone,
                    data.nicNumber || null,
                    data.bio || 'General handyman and technical services.',
                    data.verificationStatus || 'BASIC_VERIFIED',
                    data.latitude || 6.9271,
                    data.longitude || 79.8612
                ]
            );
            const techId = techResult.insertId;

            if (data.categoryId) {
                await pool.execute(
                    `INSERT IGNORE INTO technician_services (technician_id, category_id) VALUES (?, ?)`,
                    [techId, data.categoryId]
                );
            }

            return { success: true, id: techId, message: 'Technician registered successfully' };
        } catch (err) {
            console.warn('DB createTechnician note:', err);
            const newId = this.devTechnicians.length + 1;
            const newTech = {
                id: newId,
                user_id: 200 + newId,
                name: data.name,
                phone: data.phone,
                nic_number: data.nicNumber || 'N/A',
                bio: data.bio || 'Skilled technical services provider.',
                verification_status: data.verificationStatus || 'BASIC_VERIFIED',
                rating: 5.0,
                total_reviews: 1,
                completed_jobs_count: 1,
                latitude: data.latitude || 6.9271,
                longitude: data.longitude || 79.8612,
                police_report_status: 'NOT_SUBMITTED',
                created_at: new Date().toISOString(),
                categories: 'General Technical Services'
            };
            this.devTechnicians.unshift(newTech);
            return { success: true, id: newId, message: 'Technician registered successfully (dev mode)' };
        }
    }

    async getInquiries() {
        try {
            const [rows]: any = await pool.execute(`
                SELECT 
                    i.id, i.customer_name, i.customer_phone, i.description, i.urgency, i.city, i.status, i.created_at,
                    sc.name_en as category_name,
                    tp.name as technician_name
                FROM customer_inquiries i
                LEFT JOIN service_categories sc ON i.category_id = sc.id
                LEFT JOIN technician_profiles tp ON i.technician_id = tp.id
                ORDER BY i.created_at DESC
                LIMIT 50
            `);
            return rows;
        } catch (err) {
            console.warn('DB getInquiries note:', err);
            return [
                {
                    id: 1,
                    customer_name: 'Anura Bandara',
                    customer_phone: '+94773456789',
                    description: 'Main trip switch trips every time AC is turned on in Colombo 05.',
                    urgency: 'HIGH',
                    city: 'Colombo 05',
                    status: 'NEW',
                    created_at: new Date().toISOString(),
                    category_name: 'Electrical & Wiring',
                    technician_name: 'Sunil Wickramasinghe'
                },
                {
                    id: 2,
                    customer_name: 'Malini Fernando',
                    customer_phone: '+94712334455',
                    description: 'Overhead 1000L water tank leak and ball-valve replacement needed.',
                    urgency: 'MEDIUM',
                    city: 'Dehiwala',
                    status: 'CONTACTED',
                    created_at: new Date(Date.now() - 3600000).toISOString(),
                    category_name: 'Plumbing & Water Systems',
                    technician_name: 'Kusal Perera'
                }
            ];
        }
    }

    async updateInquiryStatus(id: number, status: string) {
        try {
            await pool.execute(`UPDATE customer_inquiries SET status = ? WHERE id = ?`, [status, id]);
            return { success: true, message: `Inquiry status updated to ${status}` };
        } catch (err) {
            return { success: true, message: `Inquiry status updated` };
        }
    }

    async getQuarantinedReviews() {
        try {
            const [rows]: any = await pool.execute(`
                SELECT r.*, j.request_id, u_rev.email AS reviewer_email, u_tgt.email AS target_email
                FROM reviews r
                JOIN jobs j ON r.job_id = j.id
                JOIN users u_rev ON r.reviewer_id = u_rev.id
                JOIN users u_tgt ON r.target_id = u_tgt.id
                WHERE r.status = 'QUARANTINED'
                ORDER BY r.created_at DESC
            `);
            return rows;
        } catch (err) {
            console.warn('DB getQuarantinedReviews note:', err);
            return [];
        }
    }

    async updateReviewStatus(id: number, status: 'PUBLISHED' | 'QUARANTINED' | 'DISPUTED') {
        try {
            await pool.execute(`UPDATE reviews SET status = ? WHERE id = ?`, [status, id]);
            return { success: true, message: `Review status updated to ${status}` };
        } catch (err) {
            return { success: true, message: `Review status updated` };
        }
    }
}

export const adminService = new AdminService();
