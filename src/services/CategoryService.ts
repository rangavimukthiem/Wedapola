import pool from '../config/db';

export class CategoryService {
    async getCategories() {
        const [rows]: any = await pool.execute('SELECT * FROM service_categories ORDER BY name ASC');
        return rows;
    }
}

export const categoryService = new CategoryService();
