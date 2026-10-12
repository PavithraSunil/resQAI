<<<<<<< HEAD
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
=======

const { Pool } = require("pg");
require("dotenv").config();

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is missing from backend/.env");
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
  max: 10,
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
});

pool.on("connect", () => {
  console.log("Connected to Neon PostgreSQL");
});

pool.on("error", (err) => {
  console.error("PostgreSQL pool error:", err.message);
});

module.exports = pool;
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
