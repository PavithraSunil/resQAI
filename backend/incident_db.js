const path = require("path");
const { Pool } = require("pg");

require("dotenv").config({
    path: path.join(__dirname, ".env"),
});

const connectionString = process.env.INCIDENT_DATABASE_URL;

if (!connectionString) {
    throw new Error(
        "INCIDENT_DATABASE_URL is not set. Add the incident Neon connection string to backend/.env."
    );
}

const incidentPool = new Pool({
    connectionString,
    ssl: {
        rejectUnauthorized: false,
    },
});

module.exports = incidentPool;
