const express = require("express");
const admin = require("firebase-admin");
const incidentPool = require("../incident_db");

const router = express.Router();
const incidentTypes = new Set(["Flood", "Landslide", "Road Block", "Medical"]);
const severityLevels = new Set(["Low", "Moderate", "Critical"]);

async function requireFirebaseUser(req, res, next) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!serviceAccountJson) {
        return res.status(503).json({
            success: false,
            message: "Firebase authentication is not configured on the server.",
        });
    }

    try {
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(
                    JSON.parse(serviceAccountJson)
                ),
            });
        }
    } catch (error) {
        console.error("Firebase Admin configuration failed:", error.message);
        return res.status(503).json({
            success: false,
            message: "Firebase authentication is unavailable.",
        });
    }

    const authorization = req.get("authorization") || "";
    const tokenMatch = authorization.match(/^Bearer\s+(.+)$/i);
    if (!tokenMatch) {
        return res.status(401).json({
            success: false,
            message: "A Firebase ID token is required.",
        });
    }

    try {
        req.firebaseUser = await admin.auth().verifyIdToken(tokenMatch[1]);
        return next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: "The Firebase ID token is invalid or expired.",
        });
    }
}

router.post("/incident-reports", requireFirebaseUser, async (req, res) => {
    const {
        type,
        severity,
        latitude,
        longitude,
        accuracyM,
        locationText,
        description,
        photoUrls = [],
    } = req.body || {};

    if (
        !incidentTypes.has(type) ||
        !severityLevels.has(severity) ||
        !Number.isFinite(latitude) ||
        latitude < -90 ||
        latitude > 90 ||
        !Number.isFinite(longitude) ||
        longitude < -180 ||
        longitude > 180 ||
        !Number.isFinite(accuracyM) ||
        accuracyM < 0 ||
        typeof locationText !== "string" ||
        locationText.trim().length === 0 ||
        typeof description !== "string" ||
        description.trim().length < 5 ||
        !Array.isArray(photoUrls) ||
        photoUrls.length > 4 ||
        !photoUrls.every((url) => typeof url === "string")
    ) {
        return res.status(400).json({
            success: false,
            message: "The incident report contains invalid or missing fields.",
        });
    }

    try {
        const result = await incidentPool.query(
            `
            INSERT INTO incident_reports (
                firebase_uid,
                user_name,
                type,
                severity,
                latitude,
                longitude,
                accuracy_m,
                location_text,
                description,
                photo_urls
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING id, status, created_at
            `,
            [
                req.firebaseUser.uid,
                req.firebaseUser.name || null,
                type,
                severity,
                latitude,
                longitude,
                accuracyM,
                locationText.trim(),
                description.trim(),
                photoUrls,
            ]
        );

        return res.status(201).json({
            success: true,
            message: "Incident report submitted successfully.",
            report: result.rows[0],
        });
    } catch (error) {
        console.error("Incident report insert failed:", error);
        return res.status(500).json({
            success: false,
            message: "Failed to save the incident report.",
        });
    }
});

module.exports = router;
