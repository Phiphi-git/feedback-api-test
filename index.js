const mysql = require('mysql2/promise');
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configuration de la base de données Cloud SQL
let pool = null;

// Initialiser la pool de connexion
async function initDatabase() {
    try {
        console.log('Tentative de connexion à Cloud SQL...');
        console.log(`Host: ${process.env.DB_HOST}`);
        console.log(`Database: ${process.env.DB_NAME}`);

        pool = mysql.createPool({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            waitForConnections: true,
            connectionLimit: 5,
            queueLimit: 0,
            enableKeepAlive: true,
            keepAliveInitialDelayMs: 0,
            connectionTimeout: 10000
        });

        // Test la connexion
        const connection = await pool.getConnection();
        await connection.query('SELECT 1');
        connection.release();

        console.log('✓ Connecté à Cloud SQL avec succès!');
        return true;
    } catch (error) {
        console.error('❌ Erreur de connexion à Cloud SQL:', error.message);
        console.error('Détails:', error.code);
        return false;
    }
}

// ========== SERVICE ML ==========

// Appeler le service ML pour analyser un sentiment
async function analyzeSentimentWithML(feedbackText) {
    try {
        const mlServiceUrl = process.env.SENTIMENT_API_URL ||
            'http://ml-service:8080';

        const response = await fetch(`${mlServiceUrl}/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: feedbackText }),
            timeout: 10000
        });

        if (!response.ok) {
            throw new Error(`ML Service returned ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        console.warn('⚠️  ML Service unavailable:', error.message);
        return {
            sentiment: 'unknown',
            confidence: 0,
            error: 'ML service not available'
        };
    }
}

// ========== ROUTES ==========

// 1. Health Check - TOUJOURS disponible
app.get('/api/health', async (req, res) => {
    let connected = false;
    let recordCount = 0;

    if (pool) {
        try {
            const connection = await pool.getConnection();
            const [result] = await connection.query('SELECT COUNT(*) as total FROM raw_feedback');
            recordCount = result[0].total;
            connection.release();
            connected = true;
        } catch (error) {
            console.error('Erreur health check:', error.message);
            connected = false;
        }
    }

    res.json({
        success: connected,
        message: connected ? 'API fonctionnelle' : 'Connexion à la base de données perdue',
        databaseConnected: connected,
        recordCount: recordCount,
        timestamp: new Date().toISOString()
    });
});

// 2. Récupérer tous les feedbacks
app.get('/api/feedbacks', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({
                success: false,
                message: 'Base de données non disponible',
                error: 'Database connection not initialized'
            });
        }

        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const offset = (page - 1) * limit;

        const connection = await pool.getConnection();

        // Récupérer le nombre total
        const [countResult] = await connection.query('SELECT COUNT(*) as total FROM raw_feedback');
        const total = countResult[0].total;

        // Récupérer les données paginées
        const [rows] = await connection.query('SELECT * FROM raw_feedback LIMIT ? OFFSET ?', [limit, offset]);

        connection.release();

        res.json({
            success: true,
            pagination: {
                total: total,
                page: page,
                limit: limit,
                pages: Math.ceil(total / limit)
            },
            count: rows.length,
            data: rows
        });
    } catch (error) {
        console.error('Erreur /api/feedbacks:', error.message);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 3. Récupérer un feedback par ID
app.get('/api/feedbacks/:id', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const id = parseInt(req.params.id);
        const connection = await pool.getConnection();
        const [rows] = await connection.query('SELECT * FROM raw_feedback WHERE id = ?', [id]);
        connection.release();

        if (rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Feedback non trouvé'
            });
        }

        res.json({
            success: true,
            data: rows[0]
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 4. Filtrer par username
app.get('/api/feedbacks-by-user/:username', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const username = req.params.username;
        const connection = await pool.getConnection();
        const [rows] = await connection.query('SELECT * FROM raw_feedback WHERE username = ?', [username]);
        connection.release();

        res.json({
            success: true,
            count: rows.length,
            data: rows
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 5. Filtrer par campaign_id
app.get('/api/campaign/:campaignId', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const campaignId = req.params.campaignId;
        const connection = await pool.getConnection();
        const [rows] = await connection.query('SELECT * FROM raw_feedback WHERE campaign_id = ?', [campaignId]);
        connection.release();

        res.json({
            success: true,
            count: rows.length,
            data: rows
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 6. Rechercher dans les commentaires
app.get('/api/search/:keyword', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const keyword = `%${req.params.keyword}%`;
        const connection = await pool.getConnection();
        const [rows] = await connection.query('SELECT * FROM raw_feedback WHERE comment LIKE ?', [keyword]);
        connection.release();

        res.json({
            success: true,
            count: rows.length,
            data: rows
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 7. Analyser le sentiment d'un texte (ML)
app.post('/api/analyze', async (req, res) => {
    try {
        const { text } = req.body;

        if (!text || text.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Texte requis pour l\'analyse'
            });
        }

        const sentiment = await analyzeSentimentWithML(text);

        res.json({
            success: true,
            text: text,
            sentiment: sentiment,
            mlServiceUrl: process.env.SENTIMENT_API_URL || 'http://ml-service:8080'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 8. Statistiques
app.get('/api/stats', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const connection = await pool.getConnection();

        const [totalResult] = await connection.query('SELECT COUNT(*) as total FROM raw_feedback');
        const [userResult] = await connection.query('SELECT COUNT(DISTINCT username) as count FROM raw_feedback');
        const [campaignResult] = await connection.query('SELECT COUNT(DISTINCT campaign_id) as count FROM raw_feedback');

        connection.release();

        res.json({
            success: true,
            stats: {
                totalFeedbacks: totalResult[0].total,
                uniqueUsers: userResult[0].count,
                uniqueCampaigns: campaignResult[0].count
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 9. Exporter en JSON
app.get('/api/export/json', async (req, res) => {
    try {
        if (!pool) {
            return res.status(503).json({ success: false, message: 'Base de données non disponible' });
        }

        const connection = await pool.getConnection();
        const [rows] = await connection.query('SELECT * FROM raw_feedback');
        connection.release();

        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', 'attachment; filename="feedback_data.json"');
        res.json(rows);
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 10. Analyser le sentiment d'un feedback spécifique
app.get('/api/feedbacks/:id/sentiment', async (req, res) => {
    try {
        const id = parseInt(req.params.id);

        if (isNaN(id)) {
            return res.status(400).json({ success: false, error: 'ID invalide' });
        }

        const connection = await pool.getConnection();
        const [rows] = await connection.query(
            'SELECT id, comment, username FROM raw_feedback WHERE id = ?',
            [id]
        );
        connection.release();

        if (rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Feedback non trouvé' });
        }

        const feedback = rows[0];
        const sentiment = await analyzeSentimentWithML(feedback.comment);

        res.json({
            success: true,
            feedback: {
                id: feedback.id,
                username: feedback.username,
                text: feedback.comment
            },
            sentiment: sentiment
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 11. Analyser les sentiments de tous les feedbacks d'un utilisateur
app.get('/api/feedbacks-by-user/:username/sentiments', async (req, res) => {
    try {
        const username = req.params.username;

        const connection = await pool.getConnection();
        const [rows] = await connection.query(
            'SELECT id, comment FROM raw_feedback WHERE username = ? ORDER BY feedback_date DESC',
            [username]
        );
        connection.release();

        if (rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Utilisateur non trouvé' });
        }

        // Analyser tous les feedbacks
        const sentiments = await Promise.all(
            rows.map(async (row) => ({
                id: row.id,
                text: row.comment,
                sentiment: await analyzeSentimentWithML(row.comment)
            }))
        );

        res.json({
            success: true,
            username: username,
            feedbackCount: rows.length,
            sentiments: sentiments
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 12. Analyser les sentiments de tous les feedbacks
app.get('/api/feedbacks/analysis/all-sentiments', async (req, res) => {
    try {
        const connection = await pool.getConnection();
        const [rows] = await connection.query(
            'SELECT id, comment, username FROM raw_feedback LIMIT ?',
            [parseInt(req.query.limit) || 100]
        );
        connection.release();

        // Analyser tous les feedbacks
        const analysis = await Promise.all(
            rows.map(async (row) => ({
                id: row.id,
                username: row.username,
                text: row.comment,
                sentiment: await analyzeSentimentWithML(row.comment)
            }))
        );

        // Statistiques
        const stats = {
            total: analysis.length,
            positif: analysis.filter(a => a.sentiment.sentiment === 'positif').length,
            neutre: analysis.filter(a => a.sentiment.sentiment === 'neutre').length,
            négatif: analysis.filter(a => a.sentiment.sentiment === 'négatif').length,
            unknown: analysis.filter(a => a.sentiment.sentiment === 'unknown').length
        };

        res.json({
            success: true,
            stats: stats,
            feedbacks: analysis
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 404 - Route non trouvée
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée',
        availableEndpoints: [
            'GET /api/health',
            'GET /api/feedbacks?page=1&limit=50',
            'GET /api/feedbacks/:id',
            'GET /api/feedbacks/:id/sentiment',
            'GET /api/feedbacks-by-user/:username',
            'GET /api/feedbacks-by-user/:username/sentiments',
            'GET /api/campaign/:campaignId',
            'GET /api/search/:keyword',
            'GET /api/stats',
            'GET /api/feedbacks/analysis/all-sentiments?limit=100',
            'GET /api/export/json'
        ]
    });
});

// Démarrer le serveur
async function start() {
    console.log('🚀 Démarrage de l\'API Feedback...');
    console.log(`Port: ${PORT}`);
    console.log(`Environnement: ${process.env.NODE_ENV || 'development'}`);

    // Initialiser la base de données (ne bloque pas le démarrage)
    await initDatabase();

    app.listen(PORT, () => {
        console.log(`\n✅ Serveur en écoute sur le port ${PORT}`);
        console.log('\n📚 Endpoints disponibles:');
        console.log(`  GET  /api/health`);
        console.log(`  GET  /api/feedbacks?page=1&limit=50`);
        console.log(`  GET  /api/feedbacks/:id`);
        console.log(`  GET  /api/feedbacks-by-user/:username`);
        console.log(`  GET  /api/campaign/:campaignId`);
        console.log(`  GET  /api/search/:keyword`);
        console.log(`  GET  /api/stats`);
        console.log(`  GET  /api/export/json\n`);
    });
}

start().catch(error => {
    console.error('Erreur au démarrage:', error);
    process.exit(1);
});

module.exports = app;
