import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import path from 'path';
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import categoryRoutes from './routes/categories';
import technicianRoutes from './routes/technicians';
import jobRoutes from './routes/jobs';
import adminRoutes from './routes/admin';
import kycRoutes from './routes/kyc';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(helmet({
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false // Allow CDN scripts & fonts for portal/admin UI
}));
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/kyc', kycRoutes);
app.use('/api', jobRoutes);

// Storage route
const storagePath = process.env.LOCAL_STORAGE_PATH || path.join(process.cwd(), 'storage');
app.use('/storage', express.static(storagePath));

// === Static Frontends ===
const publicPath = path.join(process.cwd(), 'public');

// Admin Panel at /admin/
app.use('/admin', express.static(path.join(publicPath, 'admin')));
app.get('/admin', (_req: Request, res: Response) => {
    res.sendFile(path.join(publicPath, 'admin', 'index.html'));
});

// Customer Job Portal at /portal/
app.use('/portal', express.static(path.join(publicPath, 'portal')));
app.get('/portal', (_req: Request, res: Response) => {
    res.sendFile(path.join(publicPath, 'portal', 'index.html'));
});

// Root → redirect to customer portal
app.get('/', (_req: Request, res: Response) => {
    res.redirect('/portal/');
});

// Health check
app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({ status: 'ok', message: 'Wedapola API is running' });
});

// 404 for any other API routes
app.use('/api', (_req: Request, res: Response) => {
    res.status(404).json({ error: 'API endpoint not found' });
});

app.listen(port, () => {
    console.log(`Wedapola Server is running on port ${port}`);
});
