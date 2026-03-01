# 📚 RÉSUMÉ POUR LE PROFESSEUR

Bienvenue dans le projet **DJP COMPANY**!

Ce document résume ce que vous devez savoir pour utiliser, tester et adapter ce projet.

---

## 🎯 Qu'est-ce que c'est?

Une **API Node.js** qui:

- ✅ Collecte des retours clients (feedbacks)
- ✅ Affiche des statistiques (moyenne note, sentiments, etc.)
- ✅ Intègre le Machine Learning pour analyser les sentiments (optionnel)
- ✅ Support de CSV ou votre propre API

---

## 📖 Commencer en 3 Étapes

### 1️⃣ Installation

```bash
npm install
```

### 2️⃣ Adapter les Données

Choisissez une option:

**Option A: Fichier CSV**

- Remplacez `feedback_data.csv` par vos données
- Voir le format exact dans `GUIDE_PROFESSEUR.md`

**Option B: Votre API**

- Définissez `FEEDBACK_API_URL=https://votre-api.com/api` dans `.env`
- L'intégration se fera automatiquement

### 3️⃣ Lancer l'API

```bash
node index.js
```

Accédez à: `http://localhost:3000/api/health`

---

## 📚 Fichiers Importants

| Fichier | Description |
| --- | --- |
| **GUIDE_PROFESSEUR.md** | 🌟 Documentation COMPLÈTE pour intégrer vos données |
| **index.js** | Code principal de l'API |
| **package.json** | Dépendances du projet |
| **.env.example** | Template de configuration |
| **feedback_data.csv** | Données d'exemple (à remplacer) |
| **docker-compose.yml** | Pour lancer avec Docker |

---

## 🔌 Endpoints Disponibles

```bash
# Vérifier que l'API fonctionne
GET /api/health

# Récupérer les statistiques
GET /api/stats

# Lister les feedbacks
GET /api/feedback?limit=10&offset=0

# Analyser un sentiment
POST /api/analyze
Body: { "text": "Votre texte ici" }
```

---

## 🚀 Démarrage Rapide

### Windows (PowerShell)

```powershell
# Configuration automatique
.\setup.ps1

# Puis lancer
node index.js
```

### Linux/Mac

```bash
# Configuration automatique
bash setup.sh

# Puis lancer
node index.js
```

---

## 🐳 Avec Docker

```bash
# Construire l'image
docker build -t feedback-api .

# Lancer le conteneur
docker run -p 3000:3000 feedback-api

# Ou avec Docker Compose
docker-compose up
```

---

## ⚙️ Configuration Avancée

Créez un fichier `.env` (basé sur `.env.example`):

```env
# Port
PORT=3000

# Votre API de données
FEEDBACK_API_URL=https://votre-api.com/api
FEEDBACK_API_KEY=votre_clé_secrète

# Base de données (optionnel)
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=feedback_db

# Service ML (optionnel)
SENTIMENT_API_URL=http://localhost:8080
```

---

## ❓ Questions Fréquentes

### Q: Comment intégrer mon propre CSV?

**R:** Voir `GUIDE_PROFESSEUR.md` - Scénario 1

### Q: Comment intégrer mon API?

**R:** Voir `GUIDE_PROFESSEUR.md` - Scénario 2

### Q: Quel format de données?

**R:** Voir le fichier `GUIDE_PROFESSEUR.md` pour les structures exactes

### Q: Le ML est obligatoire?

**R:** Non! C'est optionnel. L'API fonctionne sans.

### Q: Comment connecter à une vraie BD?

**R:** Modifiez les variables `DB_*` dans `.env`

---

## 🧪 Tests

```bash
# Vérifier que ça fonctionne
curl http://localhost:3000/api/health

# Récupérer les statistiques
curl http://localhost:3000/api/stats

# Lister les feedbacks
curl http://localhost:3000/api/feedback
```

---

## 📦 Ce qui est Inclus

- ✅ **API Node.js** fonctionnelle
- ✅ **Support CSV** pour les données
- ✅ **Support API personnalisée**
- ✅ **Docker** pour le déploiement
- ✅ **ML optionnel** pour l'analyse de sentiments
- ✅ **Documentation complète**

---

## 🎓 Pour Plus de Détails

**Consultez `GUIDE_PROFESSEUR.md`** pour:

- Remplacer les données
- Intégrer votre API
- Adapter les structures
- Gérer l'authentification
- Dépanner les problèmes

---

## ✨ Le Projet est Prêt à l'Emploi

Il n'y a **aucun fichier inutile**. Tout ce qui est dans ce dossier est nécessaire.

👉 **Commencez par lire `GUIDE_PROFESSEUR.md`** pour adapter selon vos besoins!

---

**Bonne utilisation! 🚀**
