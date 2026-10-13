
const express = require("express");
const axios = require("axios");

const router = express.Router();

router.post("/api/landslide/predict", async (req, res) => {
    try {
        const landslideApiUrl = process.env.LANDSLIDE_API_URL;

        if (!landslideApiUrl) {
            return res.status(503).json({
                error: "Landslide prediction service is not configured yet."
            });
        }

        const response = await axios.post(
            `${landslideApiUrl.replace(/\/+$/, "")}/predict`,
            req.body,
            { timeout: 15000 }
        );

        return res.status(200).json(response.data);
    } catch (error) {
        if (error.response) {
            return res
                .status(error.response.status)
                .json(error.response.data);
        }

        console.error(
            "Landslide prediction connection failed:",
            error.message
        );

        return res.status(503).json({
            error: "Landslide prediction service is unavailable."
        });
    }
});

module.exports = router;
