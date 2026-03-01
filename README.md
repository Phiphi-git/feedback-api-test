# 📊 DJP COMPANY

Une API Node.js pour collecter, analyser et afficher les retours clients avec support du Machine Learning optionnel.

## 🚀 Démarrage Rapide

### Installation

```bash
npm install
```

### Lancement Local

```bash
node index.js
```

L'API sera disponible sur `http://localhost:3000`

### Test des Endpoints

```bash
# Health Check
curl http://localhost:3000/api/health

# Récupérer les feedbacks
curl http://localhost:3000/api/feedback

# Statistiques
curl http://localhost:3000/api/stats
```

---

## 📝 Configuration

### Variables d'Environnement

Créez un fichier `.env` (voir `.env.example` pour les valeurs par défaut):

```env
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=feedback_db
FEEDBACK_API_URL=http://votre-api.com/api
SENTIMENT_API_URL=http://localhost:8080
```

---

## 🔄 Intégration de Vos Données

### Option 1: Fichier CSV

Placez un fichier `feedback_data.csv` à la racine avec cette structure:

```csv
feedback_id,timestamp,customer_name,email,product,rating,comment,sentiment_manual
1,2024-01-15 10:30:00,John Doe,john@example.com,Product A,5,Excellent!,positive
```

### Option 2: Votre API

Définissez `FEEDBACK_API_URL` dans `.env` et l'API s'intégrera automatiquement.

**Pour plus de détails:** Voir `GUIDE_PROFESSEUR.md`

---

## 🐳 Avec Docker

```bash
# Construire
docker build -t feedback-api .

# Lancer
docker run -p 3000:3000 -e PORT=3000 feedback-api
```

---

## 📚 Documentation

- **`GUIDE_PROFESSEUR.md`** - Guide complet pour intégrer vos données ou API
- **`package.json`** - Dépendances du projet
- **`.env.example`** - Variables d'environnement

---

## 🔌 API Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| GET | `/api/health` | Vérifier l'état de l'API |
| GET | `/api/stats` | Obtenir les statistiques |
| GET | `/api/feedback` | Liste paginée des feedbacks |
| POST | `/api/analyze` | Analyser le sentiment d'un texte |

---

## 📦 Structure Minimale

```
feedback-api-test/
├── index.js                 # API principale
├── package.json             # Dépendances
├── feedback_data.csv        # Vos données (à adapter)
├── sentiment_api.py         # Service ML (optionnel)
├── sentiment_analyzer.py    # Modèle ML (optionnel)
├── docker-compose.yml       # Configuration Docker
├── Dockerfile               # Image Docker
├── .env.example             # Exemple de configuration
├── GUIDE_PROFESSEUR.md      # ⭐ Documentation complète
└── README.md                # Ce fichier
```

---

## 🛠️ Technologies

- **Node.js** - Runtime JavaScript
- **Express.js** - Framework API
- **CORS** - Support Cross-Origin
- **MySQL** - Base de données (optionnel)
- **Python/Flask** - Service ML (optionnel)

---

## 📄 Licence

ISC

---

**Pour intégrer vos propres données ou API, consultez `GUIDE_PROFESSEUR.md`** 📚
