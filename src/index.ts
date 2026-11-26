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

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(helmet({ 
    crossOriginResourcePolicy: false,
    contentSecurityPolicy: false // Allow CDN scripts & fonts for UI
}));
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', jobRoutes);

// Storage route
const storagePath = process.env.LOCAL_STORAGE_PATH || path.join(process.cwd(), 'storage');
app.use('/storage', express.static(storagePath));

// Static Frontend Portal & Admin Panel
const publicPath = path.join(process.cwd(), 'public');
app.use(express.static(publicPath));

// Friendly route fallbacks
app.get('/admin', (req: Request, res: Response) => {
    res.sendFile(path.join(publicPath, 'admin', 'index.html'));
});

app.get('/admin/login', (req: Request, res: Response) => {
    res.sendFile(path.join(publicPath, 'admin', 'login.html'));
});

app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({ status: 'ok', message: 'Wedapola API is running' });
});

// Root fallback to customer portal
app.get('*', (req: Request, res: Response) => {
    // If request has not matched API routes, serve the customer job portal
    if (!req.path.startsWith('/api')) {
        res.sendFile(path.join(publicPath, 'index.html'));
    } else {
        res.status(404).json({ error: 'Endpoint not found' });
    }
});

app.listen(port, () => {
    console.log(`Wedapola Server is running on port ${port}`);
});
