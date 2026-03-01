const mysql = require('mysql2/promise');
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

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
        pool = mysql.createPool({
            host: process.env.DB_HOST || 'localhost',
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD || '',
            database: process.env.DB_NAME || 'test',
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0,
            enableKeepAlive: true,
            keepAliveInitialDelayMs: 0
        });

        console.log('✓ Connecté à Cloud SQL');
        return true;
    } catch (error) {
        console.error('Erreur de connexion à la base de données:', error.message);
        return false;
    }
}

// ========== ROUTES ==========

// 1. Récupérer tous les feedbacks
app.get('/api/feedbacks', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 2. Récupérer un feedback par ID
app.get('/api/feedbacks/:id', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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

// 3. Filtrer par username
app.get('/api/feedbacks-by-user/:username', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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

// 4. Filtrer par campaign_id
app.get('/api/campaign/:campaignId', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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

// 5. Rechercher dans les commentaires
app.get('/api/search/:keyword', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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

// 6. Statistiques
app.get('/api/stats', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
        }

        const connection = await pool.getConnection();

        const [totalResult] = await connection.query('SELECT COUNT(*) as total FROM raw_feedback');
        const [userResult] = await connection.query('SELECT COUNT(DISTINCT username) as count FROM raw_feedback');
        const [campaignResult] = await connection.query('SELECT COUNT(DISTINCT campaign_id) as count FROM raw_feedback');
        const [commentResult] = await connection.query('SELECT comment, COUNT(*) as count FROM raw_feedback GROUP BY comment');

        connection.release();

        const commentDistribution = {};
        commentResult.forEach(row => {
            commentDistribution[row.comment] = row.count;
        });

        res.json({
            success: true,
            stats: {
                totalFeedbacks: totalResult[0].total,
                uniqueUsers: userResult[0].count,
                uniqueCampaigns: campaignResult[0].count,
                commentDistribution: commentDistribution
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 7. Exporter en JSON
app.get('/api/export/json', async (req, res) => {
    try {
        if (!pool) {
            return res.status(500).json({ success: false, message: 'Base de données non initialisée' });
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

// 8. Health check
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
            connected = false;
        }
    }

    res.json({
        success: connected,
        message: connected ? 'API fonctionnelle' : 'Base de données non disponible',
        databaseConnected: connected,
        recordCount: recordCount,
        timestamp: new Date().toISOString()
    });
});

// Error handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée'
    });
});

// Démarrer le serveur
async function start() {
    try {
        const dbInitialized = await initDatabase();

        if (!dbInitialized) {
            console.warn('⚠️ Attention: Impossible de se connecter à la base de données');
            console.log('Assurez-vous que les variables d\'environnement sont correctes:');
            console.log(`  DB_HOST: ${process.env.DB_HOST}`);
            console.log(`  DB_USER: ${process.env.DB_USER}`);
            console.log(`  DB_NAME: ${process.env.DB_NAME}`);
        }

        app.listen(PORT, () => {
            console.log(`\n🚀 API démarrée sur http://localhost:${PORT}`);
            console.log('\n📚 Endpoints disponibles:');
            console.log(`  GET  /api/health - Vérifier l'API`);
            console.log(`  GET  /api/feedbacks - Tous les feedbacks (avec pagination)`);
            console.log(`  GET  /api/feedbacks/:id - Un feedback par ID`);
            console.log(`  GET  /api/feedbacks-by-user/:username - Feedbacks d'un utilisateur`);
            console.log(`  GET  /api/campaign/:campaignId - Feedbacks d'une campagne`);
            console.log(`  GET  /api/search/:keyword - Rechercher dans les commentaires`);
            console.log(`  GET  /api/stats - Statistiques générales`);
            console.log(`  GET  /api/export/json - Exporter en JSON\n`);

            if (dbInitialized) {
                console.log('✅ Base de données initialisée avec succès\n');
            }
        });
    } catch (error) {
        console.error('Erreur au démarrage:', error);
        process.exit(1);
    }
}

start();

module.exports = app;
