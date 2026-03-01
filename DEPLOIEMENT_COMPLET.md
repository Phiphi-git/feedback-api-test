# 🎯 Déploiement Complet: API + ML sur Google Cloud

Ce guide vous explique comment déployer **COMPLÈTEMENT** votre projet sur Google Cloud en **3 étapes simples**.

---

## 📊 Architecture finale

```
┌──────────────────────────────────────────────────┐
│         GOOGLE CLOUD RUN                         │
├──────────────────────────────────────────────────┤
│                                                  │
│  📱 API Node.js (feedback-api)                  │
│  ├─ Port: 3000                                 │
│  ├─ Endpoints: /api/feedbacks, /api/stats, etc │
│  └─ Appelle le service ML pour l'analyse       │
│                                                  │
│  🤖 Service ML Python (sentiment-ml)           │
│  ├─ Port: 8080                                 │
│  ├─ Endpoints: /analyze, /health               │
│  └─ Analyse les sentiments avec scikit-learn   │
│                                                  │
└──────────────────────────────────────────────────┘
         ↓                          ↓
┌──────────────────────────────────────────────────┐
│         GOOGLE CLOUD SQL                         │
├──────────────────────────────────────────────────┤
│                                                  │
│  🗄️  Base de données MySQL                     │
│  └─ Database: test                             │
│     Table: raw_feedback (données des clients)  │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Étape 1: Préparer le modèle ML

**Avant tout, entraînez le modèle localement:**

```bash
# Windows
python sentiment_analyzer.py

# Linux/Mac
python3 sentiment_analyzer.py
```

**Vérifiez que le fichier `sentiment_model.pkl` a été créé:**

```bash
ls -la sentiment_model.pkl
# ou sur Windows: dir sentiment_model.pkl
```

---

## 🚀 Étape 2: Déployer le service ML

Le service ML doit être déployé en PREMIER, car l'API Node.js aura besoin de son URL.

### Option A: Avec PowerShell (Windows)

```powershell
.\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID -Region europe-west1
```

**Remplacez `YOUR_PROJECT_ID` par votre ID Google Cloud.**

### Option B: Avec Bash (Linux/Mac)

```bash
bash deploy-ml-cloud.sh -p YOUR_PROJECT_ID -r europe-west1
```

**Le script fait automatiquement:**

1. ✅ Construit l'image Docker du service ML
2. ✅ Pousse l'image vers Google Container Registry
3. ✅ Déploie le service sur Cloud Run
4. ✅ Récupère et affiche l'URL du service

**À la fin, vous verrez:**

```
Service ML déployé sur:
https://sentiment-ml-XXXXX.europe-west1.run.app
```

**Notez bien cette URL!** ⭐

---

## 🚀 Étape 3: Déployer l'API Node.js

Maintenant que le ML est en ligne, déployez l'API avec l'URL du ML.

### Créez un fichier `.env` avec

```env
PORT=3000
DB_HOST=34.155.20.62
DB_USER=root
DB_PASSWORD=test
DB_NAME=test
SENTIMENT_API_URL=https://sentiment-ml-XXXXX.europe-west1.run.app
NODE_ENV=production
```

**Remplacez `sentiment-ml-XXXXX.europe-west1.run.app` par l'URL reçue à l'étape 2.**

### Déployez avec gcloud CLI

```bash
gcloud run deploy feedback-api \
    --source . \
    --region europe-west1 \
    --allow-unauthenticated \
    --memory 256Mi \
    --timeout 30s \
    --set-env-vars \
        PORT=3000,\
        DB_HOST=34.155.20.62,\
        DB_USER=root,\
        DB_PASSWORD=test,\
        DB_NAME=test,\
        SENTIMENT_API_URL=https://sentiment-ml-XXXXX.europe-west1.run.app,\
        NODE_ENV=production
```

**À la fin, vous verrez:**

```
Service API déployé sur:
https://feedback-api-XXXXX.europe-west1.run.app
```

---

## ✅ Vérification du déploiement

### Test 1: Health Check de l'API

```bash
curl https://feedback-api-XXXXX.europe-west1.run.app/api/health
```

**Réponse attendue:**

```json
{
  "success": true,
  "message": "API fonctionnelle",
  "databaseConnected": true,
  "recordCount": 100
}
```

### Test 2: Health Check du ML

```bash
curl https://sentiment-ml-XXXXX.europe-west1.run.app/health
```

**Réponse attendue:**

```json
{
  "status": "healthy",
  "service": "sentiment-analysis",
  "model_loaded": true
}
```

### Test 3: Analyser un sentiment via l'API

```bash
curl -X POST https://feedback-api-XXXXX.europe-west1.run.app/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Excellent produit, très satisfait!"}'
```

**Réponse attendue:**

```json
{
  "success": true,
  "text": "Excellent produit, très satisfait!",
  "sentiment": {
    "sentiment": "positive",
    "confidence": 0.92,
    "probabilities": {
      "positive": 0.92,
      "neutral": 0.05,
      "negative": 0.03
    }
  }
}
```

---

## 🎓 Endpoints disponibles

### API Node.js (`feedback-api`)

| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/health` | GET | État de l'API |
| `/api/feedbacks` | GET | Tous les feedbacks (paginé) |
| `/api/feedbacks/:id` | GET | Feedback spécifique |
| `/api/feedbacks-by-user/:username` | GET | Feedbacks d'un utilisateur |
| `/api/feedbacks/:id/sentiment` | GET | Sentiment d'un feedback |
| `/api/stats` | GET | Statistiques globales |
| `/api/analyze` | POST | Analyser du texte |
| `/api/export/json` | GET | Exporter tous les feedbacks |

### Service ML (`sentiment-ml`)

| Route | Méthode | Description |
|-------|---------|-------------|
| `/health` | GET | État du service |
| `/analyze` | POST | Analyser un sentiment |
| `/analyze-batch` | POST | Analyser plusieurs textes |
| `/stats` | GET | Statistiques du modèle |

---

## 📝 Exemples d'utilisation

### Exemple 1: Analyser un sentiment

```bash
curl -X POST https://feedback-api.run.app/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "J'\''adore ce produit!"}'
```

### Exemple 2: Récupérer les sentiments d'un utilisateur

```bash
curl "https://feedback-api.run.app/api/feedbacks-by-user/john_doe/sentiments"
```

### Exemple 3: Analyser un feedback spécifique

```bash
curl "https://feedback-api.run.app/api/feedbacks/1/sentiment"
```

### Exemple 4: Exporter tous les feedbacks

```bash
curl "https://feedback-api.run.app/api/export/json" > feedbacks.json
```

---

## 🐛 Dépannage

### Problème: "Service ML unavailable"

**Cause:** L'URL du service ML est incorrecte ou le service n'est pas encore actif

**Solution:**

1. Vérifiez l'URL du service ML
2. Attendez 1-2 minutes après le déploiement
3. Testez `/health` du service ML directement
4. Mettez à jour `SENTIMENT_API_URL` dans l'API

### Problème: "Database connection failed"

**Cause:** L'IP de Cloud SQL ou les credentials sont incorrects

**Solution:**

1. Vérifiez `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
2. Assurez-vous que Cloud SQL est en cours d'exécution
3. Vérifiez le firewall de Cloud SQL

### Problème: "Model not found"

**Cause:** `sentiment_model.pkl` n'existe pas

**Solution:** Entraînez le modèle localement avant le déploiement:

```bash
python sentiment_analyzer.py
```

---

## 💡 Tips pour la production

### 1. Augmentez la mémoire du ML

Pour gérer plus de requêtes:

```bash
gcloud run deploy sentiment-ml \
    --memory 1Gi \
    --max-instances 20
```

### 2. Configurez les alertes

```bash
# Via Google Cloud Console
Cloud Monitoring → Create Alert Policy
```

### 3. Activez les logs

```bash
# Voir les logs du service ML
gcloud run logs read sentiment-ml --limit 50

# Voir les logs de l'API
gcloud run logs read feedback-api --limit 50
```

### 4. Optimisez les coûts

- Utilisez `--min-instances 0` pour que les services se mettent en veille
- Limitez le `--memory` au strict nécessaire
- Utilisez des instances `--cpu 1` pour réduire les coûts

---

## 📚 Architecture multi-régions (avancé)

Si vous voulez déployer dans plusieurs régions:

```bash
# Europe
.\deploy-ml-cloud.ps1 -ProjectId PROJECT -Region europe-west1

# États-Unis
.\deploy-ml-cloud.ps1 -ProjectId PROJECT -Region us-central1

# Asie
.\deploy-ml-cloud.ps1 -ProjectId PROJECT -Region asia-northeast1
```

---

## ✅ Checklist finale

- [ ] Modèle ML entraîné (`sentiment_model.pkl` existe)
- [ ] Service ML déployé et accessible
- [ ] URL du service ML notée
- [ ] Variables d'environnement configurées dans `.env`
- [ ] API déployée sur Cloud Run
- [ ] Test `/api/health` réussi
- [ ] Test `/api/analyze` réussi avec le ML
- [ ] Feedbacks chargés en base de données
- [ ] Logs vérifiés sans erreur

---

## 🎉 Résumé

Vous avez maintenant une **architecture complète et professionnelle** sur Google Cloud:

✅ **API REST** sur Cloud Run (Node.js)
✅ **Service ML** sur Cloud Run (Python)
✅ **Base de données** sur Cloud SQL (MySQL)

Tout est déployé, connecté et prêt pour la **présentation au professeur!** 🎓

---

**Questions? Consultez:**

- `ML_GOOGLE_CLOUD_GUIDE.md` - Guide détaillé du ML
- `GUIDE_PROFESSEUR.md` - Guide d'intégration des données
- Logs: `gcloud run logs read feedback-api`
