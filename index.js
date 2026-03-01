const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Charger les données JSON
const feedbackPath = path.join(path.dirname(__dirname), 'feedback_data.json');
let feedbackData = [];

try {
    const data = fs.readFileSync(feedbackPath, 'utf8');
    feedbackData = JSON.parse(data);
    console.log(`\n✓ ${feedbackData.length} feedbacks chargés`);
} catch (error) {
    console.error('Erreur lors du chargement du JSON:', error.message);
    console.log(`📝 Chemin attendu: ${feedbackPath}`);
}

// ========== ROUTES ==========

// 1. Récupérer tous les feedbacks
app.get('/api/feedbacks', (req, res) => {
    // Support pagination
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;

    const paginatedData = feedbackData.slice(startIndex, endIndex);

    res.json({
        success: true,
        pagination: {
            total: feedbackData.length,
            page: page,
            limit: limit,
            pages: Math.ceil(feedbackData.length / limit)
        },
        count: paginatedData.length,
        data: paginatedData
    });
});

// 2. Récupérer un feedback par ID (index)
app.get('/api/feedbacks/:id', (req, res) => {
    const id = parseInt(req.params.id);
    if (id >= 0 && id < feedbackData.length) {
        res.json({
            success: true,
            data: feedbackData[id]
        });
    } else {
        res.status(404).json({
            success: false,
            message: 'Feedback non trouvé'
        });
    }
});

// 3. Filtrer par username
app.get('/api/feedbacks-by-user/:username', (req, res) => {
    const username = req.params.username;
    const filtered = feedbackData.filter(f => f.username === username);
    res.json({
        success: true,
        count: filtered.length,
        data: filtered
    });
});

// 4. Filtrer par campaign_id
app.get('/api/campaign/:campaignId', (req, res) => {
    const campaignId = req.params.campaignId;
    const filtered = feedbackData.filter(f => f.campaign_id === campaignId);
    res.json({
        success: true,
        count: filtered.length,
        data: filtered
    });
});

// 5. Rechercher par mot-clé dans les commentaires
app.get('/api/search/:keyword', (req, res) => {
    const keyword = req.params.keyword.toLowerCase();
    const filtered = feedbackData.filter(f =>
        f.comment.toLowerCase().includes(keyword)
    );
    res.json({
        success: true,
        count: filtered.length,
        data: filtered
    });
});

// 6. Statistiques sur les feedbacks
app.get('/api/stats', (req, res) => {
    const commentCounts = {};
    feedbackData.forEach(f => {
        commentCounts[f.comment] = (commentCounts[f.comment] || 0) + 1;
    });

    const userCount = new Set(feedbackData.map(f => f.username)).size;
    const campaignCount = new Set(feedbackData.map(f => f.campaign_id)).size;

    res.json({
        success: true,
        stats: {
            totalFeedbacks: feedbackData.length,
            uniqueUsers: userCount,
            uniqueCampaigns: campaignCount,
            commentDistribution: commentCounts
        }
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
