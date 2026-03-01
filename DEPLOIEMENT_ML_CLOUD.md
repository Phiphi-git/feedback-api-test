# 🚀 Déploiement ML sur Google Cloud

## Architecture

```
┌─────────────────────────────────────────────────────┐
│         Google Cloud Platform                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────┐      ┌──────────────────┐    │
│  │  Cloud Run       │      │   Cloud Run      │    │
│  │  (Node.js API)   │◄────►│  (Python ML)     │    │
│  │  Port 3000       │      │  Port 8080       │    │
│  └──────────────────┘      └──────────────────┘    │
│           ▲                        ▲                │
│           │                        │                │
│           └────────┬───────────────┘                │
│                    │ HTTPS                          │
│           ┌────────▼──────────┐                    │
│           │   Cloud SQL       │                    │
│           │   (MySQL)         │                    │
│           └───────────────────┘                    │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 📋 Prérequis

- ✅ Compte Google Cloud
- ✅ `gcloud` CLI installé
- ✅ Docker installé (pour tester localement)
- ✅ Fichier `sentiment_model.pkl` entraîné

---

## 🎯 Étapes de déploiement

### Étape 1: Préparer le modèle ML

Avant de déployer, créer le modèle entraîné:

```bash
# Sur votre ordinateur
python sentiment_analyzer.py

# Cela crée: sentiment_model.pkl
```

**Vérifier que le fichier existe:**

```bash
ls -la sentiment_model.pkl
```

---

### Étape 2: Tester localement avec Docker

```bash
# Construire et lancer les deux services
docker-compose up --build

# Vérifier que tout fonctionne
curl http://localhost:3000/api/health
curl http://localhost:8080/health
```

**Tester l'analyse de sentiment:**

```bash
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Excellent produit!"}'
```

---

### Étape 3: Déployer sur Google Cloud Run

#### **3.1: Configurer gcloud**

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

#### **3.2: Créer un registre (Container Registry)**

```bash
# Activer l'API
gcloud services enable containerregistry.googleapis.com

# Configurer Docker pour authentification
gcloud auth configure-docker
```

#### **3.3: Construire et pousser l'image Docker ML**

```bash
# Construire l'image
docker build -f Dockerfile.ml -t gcr.io/YOUR_PROJECT_ID/sentiment-ml:latest .

# Pousser dans Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/sentiment-ml:latest
```

#### **3.4: Déployer sur Cloud Run**

```bash
gcloud run deploy sentiment-ml \
  --image gcr.io/YOUR_PROJECT_ID/sentiment-ml:latest \
  --region europe-west1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --timeout 60s \
  --max-instances 10
```

**Résultat:**

```
Service URL: https://sentiment-ml-abc123.run.app
```

---

### Étape 4: Mettre à jour l'API Node.js

Modifiez votre `index.js` pour appeler le service ML:

```javascript
// Ajouter cette fonction
async function analyzeSentiment(feedbackText) {
    try {
        const mlServiceUrl = process.env.SENTIMENT_API_URL || 
                            'https://sentiment-ml-abc123.run.app';
        
        const response = await fetch(`${mlServiceUrl}/analyze`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ text: feedbackText })
        });
        
        return await response.json();
    } catch (error) {
        console.error('ML Service error:', error);
        return { sentiment: 'unknown', confidence: 0 };
    }
}

// Utiliser dans un nouvel endpoint
app.get('/api/feedbacks/:id/sentiment', async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const connection = await pool.getConnection();
        const [rows] = await connection.query(
            'SELECT comment FROM raw_feedback WHERE id = ?', 
            [id]
        );
        connection.release();
        
        if (rows.length === 0) {
            return res.status(404).json({ success: false });
        }
        
        const sentiment = await analyzeSentiment(rows[0].comment);
        res.json({ success: true, sentiment });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
```

#### **Configurer la variable d'environnement:**

```bash
gcloud run deploy feedback-api \
  --update-env-vars SENTIMENT_API_URL=https://sentiment-ml-abc123.run.app
```

---

## 📊 Option 2: Vertex AI (ML avancé)

Si vous voulez utiliser des modèles pré-entraînés Google:

```bash
# Déployer sur Vertex AI
gcloud ai-platform models create sentiment-model \
  --region=europe-west1

# C'est plus cher mais plus puissant
```

---

## 💾 Option 3: Cloud Storage + Cloud Functions

Stocker le modèle dans Cloud Storage:

```bash
# Créer un bucket
gsutil mb gs://your-project-ml-models

# Uploader le modèle
gsutil cp sentiment_model.pkl gs://your-project-ml-models/

# Créer une Cloud Function pour les prédictions
gcloud functions deploy sentiment-analyzer \
  --runtime python39 \
  --trigger-http
```

---

## 🔧 Configuration complète pour production

Créer un fichier `cloudbuild.yaml`:

```yaml
steps:
  # Build ML service
  - name: 'gcr.io/cloud-builders/docker'
    args: [
      'build',
      '-f', 'Dockerfile.ml',
      '-t', 'gcr.io/$PROJECT_ID/sentiment-ml:$SHORT_SHA',
      '.'
    ]
  
  # Push ML service
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/sentiment-ml:$SHORT_SHA']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gke-deploy'
    args:
      - run
      - --filename=.
      - --image=gcr.io/$PROJECT_ID/sentiment-ml:$SHORT_SHA
      - --region=europe-west1

images:
  - 'gcr.io/$PROJECT_ID/sentiment-ml:$SHORT_SHA'
```

---

## 🧪 Tests en production

```bash
# Tester le service ML
curl https://sentiment-ml-abc123.run.app/health

# Analyser un texte
curl -X POST https://sentiment-ml-abc123.run.app/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Excellent service!"}'

# Tester via l'API Node.js
curl https://feedback-api-294468132567.europe-west1.run.app/api/feedbacks/1/sentiment
```

---

## 💰 Coûts estimés

| Service | Gratuit | Coût |
|---------|---------|------|
| Cloud Run | 2M requêtes/mois | $0.40 / 1M req |
| Cloud Storage | 5 GB | $0.020 / GB |
| Vertex AI | 500 prédictions | $0.08 / 1K |

**Estimation:** ~$5-10/mois pour une petite utilisation

---

## 🚨 Monitoring

Configurer les logs et alertes:

```bash
# Voir les logs
gcloud run logs read sentiment-ml --limit 50

# Configurer les alertes
gcloud monitoring policies create \
  --display-name="ML Service High Error Rate" \
  --condition-threshold-value=0.05
```

---

## ✅ Checklist déploiement

- [ ] Modèle ML entraîné (`sentiment_model.pkl`)
- [ ] Dockerfile.ml créé et testé
- [ ] docker-compose.yml validé localement
- [ ] `gcloud` CLI configuré
- [ ] Images poussées dans Container Registry
- [ ] Services déployés sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Tests réussis en production
- [ ] Monitoring et logs activés
- [ ] Documentation mise à jour

---

## 🎯 Prochaines étapes

1. **Entraîner le modèle** (si pas déjà fait)
2. **Tester localement** avec docker-compose
3. **Déployer ML service** sur Cloud Run
4. **Mettre à jour API Node.js** pour l'utiliser
5. **Monitorer** en production

---

**Besoin d'aide pour une étape?** 🚀
