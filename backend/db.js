const { Pool } = require("pg");

const pool = new Pool({
    user: "postgres",
    host: "localhost",
    database: "resqai",
    password: "sniya.123",
    port: 5432,
});

module.exports = pool;