const express = require("express");
const cors = require("cors");
const authRouter = require("./routes/auth");
const incidentReportsRouter = require("./routes/incident_reports");
const pool = require("./db");
const incidentPool = require("./incident_db");

const app = express();


// =========================================================
// MIDDLEWARE
// =========================================================

app.use(cors());

// For Flutter / JSON requests
app.use(express.json());

// IMPORTANT:
// For the HTML password-reset form sent from Gmail link
app.use(express.urlencoded({ extended: true }));


// =========================================================
// AUTH ROUTES
// =========================================================

app.use(authRouter);
app.use(incidentReportsRouter);


// =========================================================
// TEST ROUTE
// =========================================================

app.get("/", (req, res) => {
    res.send("Backend is running!");
});


// =========================================================
// START SERVER
// =========================================================

app.listen(5000, async () => {

    try {

        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                fullname TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        `);

        await pool.query(`
            ALTER TABLE users
            ADD COLUMN IF NOT EXISTS phone TEXT;
        `);

        await incidentPool.query(`
            CREATE TABLE IF NOT EXISTS incident_reports (
                id BIGSERIAL PRIMARY KEY,
                firebase_uid TEXT NOT NULL,
                user_name TEXT,
                type TEXT NOT NULL,
                severity TEXT NOT NULL,
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                accuracy_m DOUBLE PRECISION NOT NULL,
                location_text TEXT NOT NULL,
                description TEXT NOT NULL,
                photo_urls TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
                status TEXT NOT NULL DEFAULT 'new',
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        `);

        console.log("Database table 'users' is ready");
        console.log("Database table 'incident_reports' is ready");

    } catch (error) {

        console.error(
            "Failed to initialize the database:",
            error
        );

    }

    console.log("Server running on port 5000");
});