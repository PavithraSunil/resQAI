const express = require("express");
const cors = require("cors");
const authRouter = require("./routes/auth");
const pool = require("./db");

const app = express();

app.use(cors());
app.use(express.json());
app.use(authRouter);

app.get("/", (req, res) => {
    res.send("Backend is running!");
});

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
        console.error("Failed to initialize the database:", error);
    }

    console.log("Server running on port 5000");
});