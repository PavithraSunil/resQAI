const express = require("express");
const bcrypt = require("bcrypt");
const pool = require("../db");

pool.query(`
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        fullname TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
    )
`).then(() => pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;`))
  .then(() => console.log("Auth schema ready"))
  .catch((error) => console.error("Auth schema initialization failed:", error));

const router = express.Router();

router.post("/register", async (req, res) => {
    const { fullname, email, password, phone } = req.body;
    console.log("Register payload:", req.body);

    if (!fullname || !email || !password) {
        return res.status(400).json({
            success: false,
            message: "Full name, email, and password are required.",
        });
    }

    try {
        console.log("Register -> checking existing email", email);
        const existingUser = await pool.query(
            "SELECT id FROM users WHERE email = $1",
            [email]
        );
        console.log("Register -> existing rows", existingUser.rows.length);

        if (existingUser.rows.length > 0) {
            return res.status(409).json({
                success: false,
                message: "Email already registered.",
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await pool.query(
            "INSERT INTO users (fullname, email, phone, password) VALUES ($1, $2, $3, $4)",
            [fullname, email, phone || null, hashedPassword]
        );

        return res.status(201).json({
            success: true,
            message: "Registration successful.",
        });
    } catch (error) {
        console.error("Register error:", error.stack || error);
        return res.status(500).json({
            success: false,
            message: "Failed to register user.",
        });
    }
});

router.post("/login", async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({
            success: false,
            message: "Email and password are required.",
        });
    }

    try {
        const result = await pool.query(
            "SELECT id, fullname, email, password FROM users WHERE email = $1",
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password.",
            });
        }

        const user = result.rows[0];
        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid email or password.",
            });
        }

        return res.status(200).json({
            success: true,
            message: "Login successful.",
            data: {
                id: user.id,
                fullname: user.fullname,
                email: user.email,
            },
        });
    } catch (error) {
        console.error("Login error:", error.stack || error);
        return res.status(500).json({
            success: false,
            message: "Failed to login.",
        });
    }
});

module.exports = router;