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

// 7. Statistiques
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

// 8. Exporter en JSON
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

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée',
        availableEndpoints: [
            'GET /api/health',
            'GET /api/feedbacks?page=1&limit=50',
            'GET /api/feedbacks/:id',
            'GET /api/feedbacks-by-user/:username',
            'GET /api/campaign/:campaignId',
            'GET /api/search/:keyword',
            'GET /api/stats',
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
    });
});

// 7. Exporter les données au format CSV (pour Cloud SQL)
app.get('/api/export/csv', (req, res) => {
    if (feedbackData.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Aucune donnée à exporter'
        });
    }

    // Créer les en-têtes CSV
    const headers = Object.keys(feedbackData[0]);
    const csvContent = [
        headers.join(','),
        ...feedbackData.map(row =>
            headers.map(header => {
                const value = row[header];
                // Échapper les guillemets et entourer les valeurs avec des guillemets
                return `"${String(value).replace(/"/g, '""')}"`;
            }).join(',')
        )
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="feedback_data.csv"');
    res.send(csvContent);
});

// 8. Exporter les données au format JSON
app.get('/api/export/json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', 'attachment; filename="feedback_data.json"');
    res.json(feedbackData);
});

// 9. Health check
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'API fonctionnelle',
        dataLoaded: feedbackData.length > 0,
        recordCount: feedbackData.length,
        timestamp: new Date().toISOString()
    });
});

// Erreur 404
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route non trouvée'
    });
});

// Démarrer le serveur
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
    console.log(`  GET  /api/export/csv - Exporter en CSV`);
    console.log(`  GET  /api/export/json - Exporter en JSON\n`);
});

module.exports = app;
