const path = require("path");
const { Pool } = require("pg");

require("dotenv").config({
    path: path.join(__dirname, ".env"),
});

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    throw new Error(
        "DATABASE_URL is not set. Add your Neon PostgreSQL connection string to backend/.env."
    );
}

const pool = new Pool({
    connectionString,
    ssl: {
        rejectUnauthorized: false,
    },
});

module.exports = pool;