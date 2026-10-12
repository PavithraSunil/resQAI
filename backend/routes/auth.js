const express = require("express");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const pool = require("../db");

const router = express.Router();


// =========================================================
// DATABASE TABLES
// =========================================================

async function initializeAuthSchema() {
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

        await pool.query(`
            CREATE TABLE IF NOT EXISTS password_reset_tokens (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL
                    REFERENCES users(id)
                    ON DELETE CASCADE,
                token_hash TEXT NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT NOW()
            )
        `);

        console.log("Auth schema ready");

    } catch (error) {

        console.error(
            "Auth schema initialization failed:",
            error.stack || error
        );

    }
}

initializeAuthSchema();


// =========================================================
// GMAIL CONFIGURATION
// =========================================================

const transporter = nodemailer.createTransport({
    service: "gmail",

    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});


// =========================================================
// REGISTER
// =========================================================

router.post("/register", async (req, res) => {

    const {
        fullname,
        email,
        password,
        phone
    } = req.body || {};

    console.log("Register payload:", req.body);

    if (!fullname || !email || !password) {

        return res.status(400).json({
            success: false,
            message:
                "Full name, email, and password are required.",
        });

    }

    try {

        const cleanEmail =
            email.trim().toLowerCase();

        console.log(
            "Register -> checking existing email",
            cleanEmail
        );

        const existingUser = await pool.query(
            `
            SELECT id
            FROM users
            WHERE email = $1
            `,
            [cleanEmail]
        );

        if (existingUser.rows.length > 0) {

            return res.status(409).json({
                success: false,
                message: "Email already registered.",
            });

        }

        const hashedPassword =
            await bcrypt.hash(password, 10);

        await pool.query(
            `
            INSERT INTO users
            (
                fullname,
                email,
                phone,
                password
            )
            VALUES ($1, $2, $3, $4)
            `,
            [
                fullname.trim(),
                cleanEmail,
                phone || null,
                hashedPassword,
            ]
        );

        return res.status(201).json({
            success: true,
            message: "Registration successful.",
        });

    } catch (error) {

        console.error(
            "Register error:",
            error.stack || error
        );

        return res.status(500).json({
            success: false,
            message: "Failed to register user.",
        });

    }
});


// =========================================================
// LOGIN
// =========================================================

router.post("/login", async (req, res) => {

    const {
        email,
        password
    } = req.body || {};

    if (!email || !password) {

        return res.status(400).json({
            success: false,
            message:
                "Email and password are required.",
        });

    }

    try {

        const cleanEmail =
            email.trim().toLowerCase();

        const result = await pool.query(
            `
            SELECT
                id,
                fullname,
                email,
                password
            FROM users
            WHERE email = $1
            `,
            [cleanEmail]
        );

        if (result.rows.length === 0) {

            return res.status(401).json({
                success: false,
                message:
                    "Invalid email or password.",
            });

        }

        const user = result.rows[0];

        const passwordMatch =
            await bcrypt.compare(
                password,
                user.password
            );

        if (!passwordMatch) {

            return res.status(401).json({
                success: false,
                message:
                    "Invalid email or password.",
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

        console.error(
            "Login error:",
            error.stack || error
        );

        return res.status(500).json({
            success: false,
            message: "Failed to login.",
        });

    }
});


// =========================================================
// FORGOT PASSWORD
// USER ENTERS EMAIL
// =========================================================

router.post(
    "/forgot-password",
    async (req, res) => {

        const {
            email
        } = req.body || {};

        if (!email) {

            return res.status(400).json({
                success: false,
                message:
                    "Email address is required.",
            });

        }

        try {

            const cleanEmail =
                email.trim().toLowerCase();

            console.log(
                "Forgot password request:",
                cleanEmail
            );

            const result = await pool.query(
                `
                SELECT
                    id,
                    fullname,
                    email
                FROM users
                WHERE email = $1
                `,
                [cleanEmail]
            );

            /*
             Do not reveal whether an email
             exists in the database.
            */

            if (result.rows.length === 0) {

                return res.status(200).json({
                    success: true,
                    message:
                        "If an account exists with this email, a password reset link has been sent.",
                });

            }

            const user = result.rows[0];


            // -------------------------------------------------
            // DELETE OLD TOKENS
            // -------------------------------------------------

            await pool.query(
                `
                DELETE FROM password_reset_tokens
                WHERE user_id = $1
                `,
                [user.id]
            );


            // -------------------------------------------------
            // CREATE RANDOM TOKEN
            // -------------------------------------------------

            const resetToken =
                crypto
                    .randomBytes(32)
                    .toString("hex");


            // -------------------------------------------------
            // HASH TOKEN FOR DATABASE
            // -------------------------------------------------

            const tokenHash =
                crypto
                    .createHash("sha256")
                    .update(resetToken)
                    .digest("hex");


            // -------------------------------------------------
            // TOKEN EXPIRATION
            // 15 MINUTES
            // -------------------------------------------------

            const expiresAt =
                new Date(
                    Date.now() +
                    15 * 60 * 1000
                );


            // -------------------------------------------------
            // SAVE TOKEN
            // -------------------------------------------------

            await pool.query(
                `
                INSERT INTO password_reset_tokens
                (
                    user_id,
                    token_hash,
                    expires_at
                )
                VALUES ($1, $2, $3)
                `,
                [
                    user.id,
                    tokenHash,
                    expiresAt,
                ]
            );


            // -------------------------------------------------
            // RESET LINK
            // -------------------------------------------------

            const resetLink =
                `http://localhost:5000/reset-password?token=${resetToken}`;


            // -------------------------------------------------
            // SEND EMAIL
            // -------------------------------------------------

            await transporter.sendMail({

                from:
                    `"ResQAI" <${process.env.EMAIL_USER}>`,

                to:
                    user.email,

                subject:
                    "ResQAI - Reset Your Password",

                html: `
                    <div style="
                        font-family: Arial, sans-serif;
                        max-width: 600px;
                        margin: auto;
                        padding: 30px;
                        border: 1px solid #ddd;
                        border-radius: 10px;
                    ">

                        <h2 style="
                            color: #f44336;
                        ">
                            ResQAI Password Reset
                        </h2>

                        <p>
                            Hello ${user.fullname},
                        </p>

                        <p>
                            We received a request to reset
                            your ResQAI account password.
                        </p>

                        <p>
                            Click the button below to create
                            a new password.
                        </p>

                        <div style="
                            text-align: center;
                            margin: 30px 0;
                        ">

                            <a
                                href="${resetLink}"
                                style="
                                    background-color: #f44336;
                                    color: white;
                                    padding: 14px 25px;
                                    text-decoration: none;
                                    border-radius: 8px;
                                    display: inline-block;
                                    font-weight: bold;
                                "
                            >
                                Reset Password
                            </a>

                        </div>

                        <p>
                            This link will expire in
                            <strong>
                                15 minutes
                            </strong>.
                        </p>

                        <p>
                            If you did not request a password
                            reset, you can safely ignore this
                            email.
                        </p>

                        <p>
                            Regards,<br>
                            <strong>
                                ResQAI Team
                            </strong>
                        </p>

                    </div>
                `,
            });


            console.log(
                "Password reset email sent to:",
                user.email
            );


            return res.status(200).json({
                success: true,
                message:
                    "Password reset link has been sent to your email.",
            });

        } catch (error) {

            console.error(
                "Forgot password error:",
                error.stack || error
            );

            return res.status(500).json({
                success: false,
                message:
                    "Unable to send password reset email.",
            });

        }
    }
);


// =========================================================
// RESET PASSWORD PAGE
// USER OPENS LINK FROM EMAIL
// =========================================================

router.get(
    "/reset-password",
    async (req, res) => {

        const {
            token
        } = req.query || {};

        if (!token) {

            return res.status(400).send(`
                <h2>
                    Invalid password reset link.
                </h2>
            `);

        }

        try {

            const tokenHash =
                crypto
                    .createHash("sha256")
                    .update(token)
                    .digest("hex");


            const result = await pool.query(
                `
                SELECT id
                FROM password_reset_tokens
                WHERE token_hash = $1
                AND expires_at > NOW()
                `,
                [tokenHash]
            );


            if (result.rows.length === 0) {

                return res.status(400).send(`
                    <div style="
                        font-family: Arial;
                        text-align: center;
                        margin-top: 100px;
                    ">

                        <h2>
                            Reset Link Expired
                        </h2>

                        <p>
                            This password reset link is
                            invalid or has expired.
                        </p>

                    </div>
                `);

            }


            return res.send(`
                <!DOCTYPE html>

                <html>

                <head>

                    <title>
                        ResQAI - Reset Password
                    </title>

                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1"
                    >

                </head>


                <body style="
                    font-family: Arial, sans-serif;
                    background: #f5f5f5;
                    padding: 40px 20px;
                ">

                    <div style="
                        max-width: 450px;
                        margin: auto;
                        background: white;
                        padding: 30px;
                        border-radius: 12px;
                        box-shadow:
                            0 2px 10px
                            rgba(0,0,0,0.1);
                    ">

                        <h2 style="
                            color: #f44336;
                            text-align: center;
                        ">
                            ResQAI
                        </h2>

                        <h3 style="
                            text-align: center;
                        ">
                            Reset Password
                        </h3>


                        <form
                            method="POST"
                            action="/reset-password"
                        >

                            <input
                                type="hidden"
                                name="token"
                                value="${token}"
                            >


                            <label>
                                New Password
                            </label>

                            <input
                                type="password"
                                name="password"
                                required
                                minlength="6"
                                style="
                                    width: 100%;
                                    padding: 12px;
                                    margin-top: 8px;
                                    margin-bottom: 20px;
                                    box-sizing: border-box;
                                    border: 1px solid #ccc;
                                    border-radius: 8px;
                                "
                            >


                            <label>
                                Confirm New Password
                            </label>

                            <input
                                type="password"
                                name="confirmPassword"
                                required
                                minlength="6"
                                style="
                                    width: 100%;
                                    padding: 12px;
                                    margin-top: 8px;
                                    margin-bottom: 25px;
                                    box-sizing: border-box;
                                    border: 1px solid #ccc;
                                    border-radius: 8px;
                                "
                            >


                            <button
                                type="submit"
                                style="
                                    width: 100%;
                                    padding: 14px;
                                    background: #f44336;
                                    color: white;
                                    border: none;
                                    border-radius: 8px;
                                    font-size: 16px;
                                    font-weight: bold;
                                    cursor: pointer;
                                "
                            >
                                Change Password
                            </button>

                        </form>

                    </div>

                </body>

                </html>
            `);

        } catch (error) {

            console.error(
                "Reset page error:",
                error.stack || error
            );

            return res.status(500).send(
                "Unable to process password reset."
            );

        }
    }
);


// =========================================================
// RESET PASSWORD
// FORM SUBMISSION
// =========================================================

router.post(
    "/reset-password",
    async (req, res) => {

        /*
         IMPORTANT FIX:
         req.body may be undefined.
         Therefore we use || {}.
        */

        const {
            token,
            password,
            confirmPassword
        } = req.body || {};


        console.log(
            "Reset password request received."
        );


        // -------------------------------------------------
        // CHECK TOKEN
        // -------------------------------------------------

        if (!token) {

            return res.status(400).send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2>
                        Invalid reset token.
                    </h2>

                    <p>
                        Please request a new password
                        reset link.
                    </p>

                </div>
            `);

        }


        // -------------------------------------------------
        // CHECK PASSWORD
        // -------------------------------------------------

        if (!password || !confirmPassword) {

            return res.status(400).send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2>
                        Please enter both password fields.
                    </h2>

                </div>
            `);

        }


        // -------------------------------------------------
        // PASSWORD LENGTH
        // -------------------------------------------------

        if (password.length < 6) {

            return res.status(400).send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2>
                        Password must contain at least
                        6 characters.
                    </h2>

                </div>
            `);

        }


        // -------------------------------------------------
        // PASSWORD MATCH
        // -------------------------------------------------

        if (password !== confirmPassword) {

            return res.status(400).send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2>
                        Passwords do not match.
                    </h2>

                </div>
            `);

        }


        try {

            // -------------------------------------------------
            // HASH TOKEN
            // -------------------------------------------------

            const tokenHash =
                crypto
                    .createHash("sha256")
                    .update(token)
                    .digest("hex");


            // -------------------------------------------------
            // FIND VALID TOKEN
            // -------------------------------------------------

            const tokenResult =
                await pool.query(
                    `
                    SELECT
                        id,
                        user_id
                    FROM password_reset_tokens
                    WHERE token_hash = $1
                    AND expires_at > NOW()
                    `,
                    [tokenHash]
                );


            if (tokenResult.rows.length === 0) {

                return res.status(400).send(`
                    <div style="
                        font-family: Arial;
                        text-align: center;
                        margin-top: 100px;
                    ">

                        <h2>
                            Reset Link Expired
                        </h2>

                        <p>
                            This password reset link is
                            invalid or has expired.
                        </p>

                    </div>
                `);

            }


            const resetRecord =
                tokenResult.rows[0];


            // -------------------------------------------------
            // HASH NEW PASSWORD
            // -------------------------------------------------

            const hashedPassword =
                await bcrypt.hash(
                    password,
                    10
                );


            // -------------------------------------------------
            // UPDATE PASSWORD
            // -------------------------------------------------

            const updateResult =
                await pool.query(
                    `
                    UPDATE users
                    SET password = $1
                    WHERE id = $2
                    `,
                    [
                        hashedPassword,
                        resetRecord.user_id,
                    ]
                );


            console.log(
                "Password update rows:",
                updateResult.rowCount
            );


            // -------------------------------------------------
            // CHECK UPDATE
            // -------------------------------------------------

            if (updateResult.rowCount === 0) {

                return res.status(404).send(`
                    <h2>
                        User account not found.
                    </h2>
                `);

            }


            // -------------------------------------------------
            // DELETE USED TOKEN
            // -------------------------------------------------

            await pool.query(
                `
                DELETE FROM password_reset_tokens
                WHERE id = $1
                `,
                [resetRecord.id]
            );


            console.log(
                "Password successfully reset for user:",
                resetRecord.user_id
            );


            // -------------------------------------------------
            // SUCCESS PAGE
            // -------------------------------------------------

            return res.send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2 style="
                        color: green;
                    ">
                        Password Changed Successfully!
                    </h2>

                    <p>
                        Your ResQAI password has been updated.
                    </p>

                    <p>
                        You can now close this page and
                        log in using your new password.
                    </p>

                </div>
            `);


        } catch (error) {

            console.error(
                "Reset password error:",
                error.stack || error
            );

            return res.status(500).send(`
                <div style="
                    font-family: Arial;
                    text-align: center;
                    margin-top: 100px;
                ">

                    <h2>
                        Failed to reset password.
                    </h2>

                    <p>
                        Please try again.
                    </p>

                </div>
            `);

        }
    }
);


// =========================================================
// EXPORT
// =========================================================

module.exports = router;