# 🤖 Guide ML - Intégration Google Cloud Run

Ce guide explique comment déployer le service ML sur **Google Cloud Run** et le connecter à votre API Node.js.

---

## 📋 Vue d'ensemble

Vous avez maintenant 2 services à déployer sur Google Cloud:

```
┌─────────────────────────────────────────┐
│      Google Cloud Platform              │
├─────────────────────────────────────────┤
│                                         │
│  Cloud Run Service #1: API Node.js      │
│  └─ Feedback API (port 3000)           │
│     └─ Route /api/analyze appelle ML   │
│                                         │
│  Cloud Run Service #2: ML Python        │
│  └─ Sentiment Analysis (port 8080)     │
│     └─ Route /analyze pour ML          │
│                                         │
│  Cloud SQL: Database                    │
│  └─ Stocke les feedbacks               │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🚀 Déploiement en 4 étapes

### Étape 1: Entraîner le modèle localement

**Avant le déploiement, le modèle doit exister:**

```bash
# Windows
python sentiment_analyzer.py

# Linux/Mac
python3 sentiment_analyzer.py
```

**Vérifiez que `sentiment_model.pkl` existe:**

```bash
ls -la sentiment_model.pkl
```

### Étape 2: Déployer le service ML

#### Windows (PowerShell)

```powershell
.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID -Region europe-west1
```

#### Linux/Mac

```bash
bash deploy-ml-cloud.sh -p YOUR_PROJECT_ID -r europe-west1
```

**Le script va:**

1. ✅ Activer les APIs Google Cloud requises
2. ✅ Construire l'image Docker du ML
3. ✅ Pousser l'image vers Google Container Registry
4. ✅ Déployer sur Cloud Run
5. ✅ Récupérer l'URL du service

**Résultat:** Vous recevrez une URL comme:

```
https://sentiment-ml-XXXXX.europe-west1.run.app
```

### Étape 3: Récupérer l'URL du service ML

Le script affiche l'URL à la fin. Ou récupérez-la manuellement:

```bash
gcloud run services describe sentiment-ml --region europe-west1 --format 'value(status.url)'
```

### Étape 4: Configurer l'API Node.js

#### Option A: Via variable d'environnement

Créez `.env`:

```env
SENTIMENT_API_URL=https://sentiment-ml-XXXXX.europe-west1.run.app
```

#### Option B: Via Cloud Run

Lors du déploiement de l'API, ajoutez:

```bash
gcloud run deploy feedback-api \
    --set-env-vars SENTIMENT_API_URL=https://sentiment-ml-XXXXX.europe-west1.run.app \
    ...autres paramètres...
```

---

## 📝 Configuration Automatique

J'ai inclus deux scripts automatisés qui font tout:

### Script 1: `deploy-ml-cloud.ps1` (Windows)

```powershell
.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID
```

**Options:**

- `-ProjectId` (obligatoire) - Votre ID Google Cloud
- `-Region` (optionnel) - Région (défaut: europe-west1)

### Script 2: `deploy-ml-cloud.sh` (Linux/Mac)

```bash
bash deploy-ml-cloud.sh -p YOUR_PROJECT_ID -r europe-west1
```

**Options:**

- `-p, --project` (obligatoire) - Votre ID Google Cloud
- `-r, --region` (optionnel) - Région (défaut: europe-west1)

---

## 🧪 Tests du service ML

### Health Check (tester que le service fonctionne)

```bash
curl https://sentiment-ml-XXXXX.europe-west1.run.app/health
```

**Réponse attendue:**

```json
{
  "status": "healthy",
  "service": "sentiment-analysis",
  "model_loaded": true,
  "version": "1.0.0"
}
```

### Analyser un sentiment

```bash
curl -X POST https://sentiment-ml-XXXXX.europe-west1.run.app/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Excellent produit, très satisfait!"}'
```

**Réponse attendue:**

```json
{
  "sentiment": "positive",
  "confidence": 0.92,
  "probabilities": {
    "positive": 0.92,
    "neutral": 0.05,
    "negative": 0.03
  }
}
```

### Analyser plusieurs textes (batch)

```bash
curl -X POST https://sentiment-ml-XXXXX.europe-west1.run.app/analyze-batch \
  -H "Content-Type: application/json" \
  -d '{
    "texts": [
      "Excellent produit!",
      "Déçu par la qualité",
      "C'\''est correct"
    ]
  }'
```

---

## 🔌 Intégration avec l'API Node.js

### Utilisation dans `index.js`

```javascript
// Configuration
const SENTIMENT_API_URL = process.env.SENTIMENT_API_URL || 
    'https://sentiment-ml-XXXXX.europe-west1.run.app';

// Fonction d'analyse
async function analyzeSentimentWithML(feedbackText) {
    try {
        const response = await fetch(`${SENTIMENT_API_URL}/analyze`, {
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

// Endpoint pour analyser un feedback
app.post('/api/analyze', async (req, res) => {
    const { text } = req.body;
    
    if (!text) {
        return res.status(400).json({
            success: false,
            message: 'Texte requis'
        });
    }

    const result = await analyzeSentimentWithML(text);
    
    res.json({
        success: true,
        sentiment: result
    });
});
```

---

## 📊 Endpoints ML disponibles

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Vérifier l'état du service |
| POST | `/analyze` | Analyser un sentiment |
| POST | `/analyze-batch` | Analyser plusieurs textes |
| GET | `/stats` | Statistiques du modèle |

---

## 🐛 Dépannage

### "Service pas accessible"

```bash
# Vérifier le statut du service
gcloud run services describe sentiment-ml --region europe-west1

# Voir les logs
gcloud run logs read sentiment-ml --region europe-west1 --limit 50
```

### "Cannot import module sklearn"

**Cause:** Les dépendances ne sont pas installées

**Solution:** Vérifiez `requirements_ml.txt` et reconstruisez:

```bash
.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID
```

### "Model not found"

**Cause:** `sentiment_model.pkl` n'existe pas

**Solution:** Entraînez le modèle d'abord:

```bash
python sentiment_analyzer.py
```

### "Timeout - service trop lent"

**Cause:** Le service est overchargé

**Solution:** Augmentez les ressources:

```bash
gcloud run deploy sentiment-ml \
    --image gcr.io/YOUR_PROJECT_ID/sentiment-ml:latest \
    --memory 1Gi \
    --max-instances 20 \
    --region europe-west1
```

---

## 💡 Conseils pour la production

### 1. Augmentez la mémoire

Pour mieux gérer les requêtes:

```bash
gcloud run deploy sentiment-ml \
    --memory 1Gi \
    --region europe-west1
```

### 2. Ajustez les instances

```bash
gcloud run deploy sentiment-ml \
    --min-instances 1 \
    --max-instances 50 \
    --region europe-west1
```

### 3. Activer l'authentification

Pour sécuriser le service:

```bash
gcloud run deploy sentiment-ml \
    --no-allow-unauthenticated \
    --region europe-west1
```

Puis gérez l'accès avec IAM.

### 4. Monitoring

Configurez les alertes:

```bash
# Voir les métriques
gcloud monitoring metrics-descriptors list

# Configurer les alertes dans Cloud Console
```

---

## 📝 Architecture complète

```
┌─────────────────────────────────────────────────────────┐
│                  Google Cloud Platform                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Cloud Run: feedback-api (Node.js)                     │
│  ├─ Image: gcr.io/PROJECT/feedback-api:latest         │
│  ├─ Port: 3000                                        │
│  ├─ Memory: 256Mi                                     │
│  └─ Env: SENTIMENT_API_URL=...                       │
│                                                         │
│  Cloud Run: sentiment-ml (Python)                      │
│  ├─ Image: gcr.io/PROJECT/sentiment-ml:latest         │
│  ├─ Port: 8080                                        │
│  ├─ Memory: 512Mi                                     │
│  └─ Model: sentiment_model.pkl                       │
│                                                         │
│  Cloud SQL: MySQL                                     │
│  ├─ Instance: feedback-db                            │
│  ├─ Database: test                                   │
│  ├─ Table: raw_feedback                              │
│  └─ IP: 34.155.20.62                                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist

- [ ] Modèle entraîné (`sentiment_model.pkl` existe)
- [ ] Dockerfile.ml existe et est correct
- [ ] Docker installé et fonctionnel
- [ ] gcloud CLI configuré
- [ ] Google Cloud projet créé
- [ ] Script `deploy-ml-cloud.ps1` ou `.sh` prêt
- [ ] Exécutez le script de déploiement
- [ ] Service ML déployé et accessible
- [ ] URL du service ML notée
- [ ] `.env` mise à jour avec SENTIMENT_API_URL
- [ ] API Node.js déployée et connectée au ML

---

## 🎓 Commandes essentielles

```bash
# Voir les services actifs
gcloud run services list

# Voir les logs du service ML
gcloud run logs read sentiment-ml --limit 50

# Récupérer l'URL
gcloud run services describe sentiment-ml --format 'value(status.url)'

# Redéployer après modification
.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID

# Supprimer le service
gcloud run services delete sentiment-ml --region europe-west1
```

---

## 🚀 Résumé

1. **Entraînez le modèle:** `python sentiment_analyzer.py`
2. **Déployez le ML:** `.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID`
3. **Notez l'URL:** `https://sentiment-ml-XXXXX.europe-west1.run.app`
4. **Mettez à jour .env:** `SENTIMENT_API_URL=<URL>`
5. **Déployez l'API:** Mise à jour avec la nouvelle URL
6. **Testez:** Appelez `/api/analyze` depuis votre API

**C'est tout! Le ML est maintenant sur Google Cloud! 🎉**
