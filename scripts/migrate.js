require('dotenv').config();

const { readFile } = require('node:fs/promises');
const path = require('node:path');
const mysql = require('mysql2/promise');

async function migrate() {
  const database = process.env.DB_NAME;
  if (!database) {
    throw new Error('DB_NAME must be set before running migrations.');
  }

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'ekafy-mariadb',
    port: Number.parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'ekafy_admin',
    password: process.env.DB_PASSWORD || '',
    database,
    multipleStatements: true,
    charset: 'utf8mb4',
  });

  try {
    const schemaPath = path.resolve(process.cwd(), 'database/init/01_schema.sql');
    const schema = await readFile(schemaPath, 'utf8');
    await connection.query(schema);
    console.log(`Database schema and seed data applied to "${database}".`);
  } finally {
    await connection.end();
  }
}

migrate().catch((error) => {
  console.error('Database migration failed:', error);
  process.exitCode = 1;
});
