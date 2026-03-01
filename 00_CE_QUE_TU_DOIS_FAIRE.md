# 📋 GUIDE COMPLET - Ce que TU dois faire

Salut! J'ai automatisé presque tout. Voici exactement ce que **tu dois faire toi-même** (c'est rapide, promis!).

---

## ⚡ RÉSUMÉ DE CE QUI EST FAIT

✅ **Déjà fait par moi:**

- Ajout des endpoints ML au Node.js API (`index.js`)
- Création du script `train-ml-model.ps1` (entraîne le modèle)
- Création du script `deploy-to-cloud.ps1` (déploie tout)
- Création du script `test-local.ps1` (teste localement)
- Tous les fichiers ML (sentiment_analyzer.py, sentiment_api.py, etc.)
- Docker et docker-compose configurés

❌ **Ce que TU dois faire (3 étapes faciles):**

1. Entraîner le modèle ML
2. Tester localement (optionnel mais recommandé)
3. Déployer sur Google Cloud

---

## 🎯 ÉTAPE 1: Entraîner le modèle ML

**Pourquoi:** Le modèle doit être entraîné sur tes feedbacks avant de pouvoir les analyser.

**Commande:**

```powershell
.\train-ml-model.ps1
```

**Résultat attendu:**

```
✅ Python détecté: Python 3.x.x
✅ Dépendances installées
⚙️  Entraînement du modèle en cours...
✅ Modèle créé avec succès: sentiment_model.pkl
✨ Entraînement terminé avec succès!
```

**Temps:** ~2 minutes

**Fichier créé:** `sentiment_model.pkl` (à ne pas supprimer!)

---

## 🧪 ÉTAPE 2: Tester localement (RECOMMANDÉ)

**Pourquoi:** Vérifier que tout fonctionne avant de déployer sur le cloud.

**Prérequis:**

- Docker Desktop doit être ouvert/actif

**Commande:**

```powershell
.\test-local.ps1
```

**Résultat attendu:**

```
✅ Docker détecté
✅ Modèle ML trouvé
📦 Construction des images Docker...
⚙️  Démarrage des services...

🧪 TESTS LOCAL

1️⃣  Test API Health Check...
   ✅ API actif (Feedbacks: 100)

2️⃣  Test ML Service Health Check...
   ✅ Service ML actif
      - Status: ready
      - Version: 1.0

3️⃣  Test analyse de sentiment...
   ✅ Analyse réussie
      - Sentiment: positif
      - Confiance: 95.42%

✨ SERVICES LOCAUX EN COURS D'EXÉCUTION
📍 Adresses:
  API Node.js:  http://localhost:3000
  ML Python:    http://localhost:8080
```

**Temps:** ~3-5 minutes (la première fois) ou 30 secondes (les fois suivantes)

**Pour arrêter:**

```powershell
docker-compose down
```

---

## 🚀 ÉTAPE 3: Déployer sur Google Cloud

### 3.1: Obtenir ton Project ID Google Cloud

1. Va sur [Google Cloud Console](https://console.cloud.google.com)
2. En haut à gauche, tu vois "Sélecteur de projet" avec un ID comme: `feedback-api-294468132567`
3. **Copie cet ID**

### 3.2: Lancer le déploiement

**Commande:**

```powershell
.\deploy-to-cloud.ps1 -ProjectId YOUR_PROJECT_ID -Region europe-west1
```

**Remplace `YOUR_PROJECT_ID` par ton ID réel**, par exemple:

```powershell
.\deploy-to-cloud.ps1 -ProjectId feedback-api-294468132567 -Region europe-west1
```

### 3.3: Le script va faire automatiquement

1. ✅ Vérifier que tout est en place
2. ✅ Commit et push vers GitHub
3. ✅ Configurer les droits d'accès Google Cloud
4. ✅ Construire les images Docker
5. ✅ Les envoyer dans Google Container Registry
6. ✅ Déployer le service ML sur Cloud Run
7. ✅ Déployer l'API Node.js sur Cloud Run
8. ✅ Configurer les variables d'environnement
9. ✅ Tester en production
10. ✅ Afficher les URLs finales

**Résultat attendu:**

```
📋 VÉRIFICATIONS PRÉALABLES
✅ gcloud CLI détecté
✅ Docker détecté
✅ Modèle ML trouvé
✅ Tous les fichiers nécessaires présents

📤 GIT - COMMIT ET PUSH
Fichiers modifiés détectés
✅ Commit créé
✅ Code poussé vers GitHub

🔐 AUTHENTIFICATION GOOGLE CLOUD
Configuration du projet: feedback-api-294468132567
✅ Projet configuré

🤖 DÉPLOIEMENT - SERVICE ML
✅ Image ML construite
✅ Docker configuré
✅ Image poussée vers GCR
✅ Service ML déployé
URL du service ML: https://sentiment-ml-abc123.run.app

🟢 DÉPLOIEMENT - API NODE.JS
✅ Image API construite
✅ Image API poussée
✅ Service API déployé
URL de l'API: https://feedback-api-xyz789.run.app

✅ TESTS EN PRODUCTION
✅ https://feedback-api-xyz789.run.app/api/health

✨ DÉPLOIEMENT RÉUSSI!
==================================================
📊 RÉSUMÉ DU DÉPLOIEMENT:

  Service ML:  https://sentiment-ml-abc123.run.app
  Service API: https://feedback-api-xyz789.run.app

🔗 ENDPOINTS DISPONIBLES:

  Health Check:      https://feedback-api-xyz789.run.app/api/health
  Feedbacks:         https://feedback-api-xyz789.run.app/api/feedbacks
  Sentiment:         https://feedback-api-xyz789.run.app/api/feedbacks/:id/sentiment
  Stats:             https://feedback-api-xyz789.run.app/api/stats
```

**Temps:** ~10-15 minutes (surtout pour la construction des images)

---

## 📊 NOUVEAUX ENDPOINTS DISPONIBLES APRÈS DÉPLOIEMENT

Après le déploiement, tu as **3 nouveaux endpoints** pour l'analyse de sentiment:

### 1️⃣ Analyser un feedback spécifique

```bash
GET https://feedback-api-xyz789.run.app/api/feedbacks/1/sentiment
```

**Réponse:**

```json
{
  "success": true,
  "feedback": {
    "id": 1,
    "username": "user@example.com",
    "text": "Excellent produit..."
  },
  "sentiment": {
    "sentiment": "positif",
    "confidence": 0.95,
    "probabilities": {
      "positif": 0.95,
      "neutre": 0.04,
      "négatif": 0.01
    }
  }
}
```

### 2️⃣ Analyser tous les feedbacks d'un utilisateur

```bash
GET https://feedback-api-xyz789.run.app/api/feedbacks-by-user/username/sentiments
```

**Réponse:**

```json
{
  "success": true,
  "username": "user@example.com",
  "feedbackCount": 3,
  "sentiments": [
    {
      "id": 1,
      "text": "...",
      "sentiment": { "sentiment": "positif", "confidence": 0.95 }
    }
  ]
}
```

### 3️⃣ Analyser TOUS les feedbacks (avec limite)

```bash
GET https://feedback-api-xyz789.run.app/api/feedbacks/analysis/all-sentiments?limit=100
```

**Réponse:**

```json
{
  "success": true,
  "stats": {
    "total": 100,
    "positif": 55,
    "neutre": 30,
    "négatif": 15
  },
  "feedbacks": [...]
}
```

---

## 🎓 POUR TA PRÉSENTATION

Tu peux montrer:

1. **Architecture:**
   - Diagram dans `DEPLOIEMENT_ML_CLOUD.md`

2. **Résultats live:**
   - URL de l'API en production
   - Appels aux endpoints ML
   - Statistiques de sentiments

3. **Code:**
   - Les 3 nouveaux endpoints dans `index.js`
   - Le modèle ML dans `sentiment_analyzer.py`
   - L'API Flask dans `sentiment_api.py`

4. **Infrastructure:**
   - Services Google Cloud Run
   - Cloud SQL database
   - Container Registry

---

## 🚨 TROUBLESHOOTING

### "gcloud CLI non installé"

Télécharge et installe: <https://cloud.google.com/sdk/docs/install-sdk>

### "Docker n'est pas installé"

Télécharge Docker Desktop: <https://www.docker.com/products/docker-desktop>

### "sentiment_model.pkl non trouvé"

Lance d'abord:

```powershell
.\train-ml-model.ps1
```

### "Erreur lors du push vers GitHub"

Vérifie que tu es loggé:

```powershell
git config user.name "Ton Nom"
git config user.email "ton.email@example.com"
```

### "ProjectId manquant"

Utilise l'ID exact de ta console Google Cloud:

```powershell
.\deploy-to-cloud.ps1 -ProjectId feedback-api-294468132567
```

---

## ✅ CHECKLIST FINALE

Avant ta présentation, vérifie:

- [ ] Étape 1 complétée: `.\train-ml-model.ps1` ✅
- [ ] Étape 2 complétée: `.\test-local.ps1` ✅
- [ ] Étape 3 complétée: `.\deploy-to-cloud.ps1` ✅
- [ ] Les 2 services sont actifs sur Google Cloud
- [ ] Tu as les URLs finales
- [ ] Tu as testé les endpoints ML
- [ ] La documentation est à jour

---

## 🎉 C'EST TOUT

Une fois que tu as exécuté les 3 scripts PowerShell, **tout est prêt pour ta présentation**!

Les scripts gèrent:

- L'entraînement du modèle
- Les tests locaux
- Le déploiement complet sur Google Cloud
- Les configurations d'environnement
- Les variables de connexion

Tu n'as que 3 commandes à lancer. Le reste se fait automatiquement! 🚀
