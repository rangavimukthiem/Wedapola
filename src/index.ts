import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import categoryRoutes from './routes/categories';
import technicianRoutes from './routes/technicians';
import jobRoutes from './routes/jobs';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(helmet({ crossOriginResourcePolicy: false })); // allow static images to be served across origins
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/technicians', technicianRoutes);
app.use('/api', jobRoutes);

// Static storage route
// In production, you might want a middleware to check visibility before serving
import path from 'path';
const storagePath = process.env.LOCAL_STORAGE_PATH || path.join(process.cwd(), 'storage');
app.use('/storage', express.static(storagePath));

app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', message: 'Wedapola API is running' });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
