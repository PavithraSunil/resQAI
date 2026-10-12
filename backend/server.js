<<<<<<< HEAD
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
=======

require("dotenv").config();

const express = require("express");
const cors = require("cors");
const authRouter = require("./routes/auth");
const landslideRouter = require("./routes/landslide");
const pool = require("./db");

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Existing authentication routes
app.use(authRouter);
app.use(landslideRouter);

// Health check
app.get("/", (req, res) => {
  res.status(200).send("ResQAI Backend is running!");
});

// Initialize database before accepting requests
async function initializeDatabase() {
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
    ADD COLUMN IF NOT EXISTS phone TEXT
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
}

async function startServer() {
  try {
    await initializeDatabase();

    const PORT = process.env.PORT || 5000;

    app.listen(PORT, "0.0.0.0", () => {
      console.log(`ResQAI backend running on port ${PORT}`);
    });
  } catch (error) {
    console.error("Backend startup failed:", error.message);
    process.exit(1);
  }
}

startServer();
>>>>>>> b166b4d084212c29548822a68eddf63402d147b0
