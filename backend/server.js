const express = require("express");
const cors = require("cors");
const authRouter = require("./routes/auth");
const pool = require("./db");

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

        console.log("Database table 'users' is ready");

    } catch (error) {

        console.error(
            "Failed to initialize the database:",
            error
        );

    }

    console.log("Server running on port 5000");
});