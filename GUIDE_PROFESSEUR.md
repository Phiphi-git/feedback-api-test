# 📚 Guide pour le Professeur - Feedback API

Bienvenue! Ce document vous explique comment **remplacer les données de feedback** ou **intégrer votre propre API** dans ce projet.

---

## 📋 Structure du Projet

```
feedback-api-test/
├── index.js                    # API Node.js principale
├── package.json                # Dépendances du projet
├── sentiment_api.py            # Service d'analyse ML (optionnel)
├── sentiment_analyzer.py       # Modèle d'analyse (optionnel)
├── feedback_data.csv           # ✏️ Données à remplacer
├── sentiment_model.pkl         # Modèle ML (optionnel)
├── docker-compose.yml          # Configuration Docker
├── Dockerfile                  # Pour Node.js
└── Dockerfile.ml               # Pour le service ML (optionnel)
```

---

## 🔄 Scénario 1: Remplacer les Données de Feedback

### Étape 1: Préparer vos données CSV

Votre fichier CSV doit avoir cette structure exacte:

```csv
feedback_id,timestamp,customer_name,email,product,rating,comment,sentiment_manual
1,2024-01-15 10:30:00,John Doe,john@example.com,Product A,5,Excellent produit!,positive
2,2024-01-15 11:00:00,Jane Smith,jane@example.com,Product B,3,Pas mal mais amélioration possible,neutral
3,2024-01-15 12:00:00,Bob Wilson,bob@example.com,Product C,1,Très décevant,negative
```

**Colonnes requises:**

- `feedback_id`: Identifiant unique
- `timestamp`: Date/heure du feedback
- `customer_name`: Nom du client
- `email`: Email du client
- `product`: Nom du produit
- `rating`: Note (1-5)
- `comment`: Texte du feedback
- `sentiment_manual`: Sentiment estimé (positive/neutral/negative)

### Étape 2: Remplacer le fichier

1. **Supprimer** l'ancien `feedback_data.csv`
2. **Ajouter** votre `feedback_data.csv` à la racine du projet
3. **Aucune autre modification** n'est nécessaire!

### Étape 3: Tester

```bash
# Installer les dépendances
npm install

# Démarrer l'API
node index.js

# Tester les endpoints
# Dans un navigateur ou avec curl:
# - http://localhost:3000/api/health
# - http://localhost:3000/api/stats
# - http://localhost:3000/api/feedback?limit=10
```

---

## 🔌 Scénario 2: Remplacer par Votre Propre API

### Cas 2A: Votre API renvoie des données JSON

Si votre API retourne un JSON avec une structure similaire:

```json
{
  "feedback": [
    {
      "feedback_id": 1,
      "timestamp": "2024-01-15T10:30:00Z",
      "customer_name": "John Doe",
      "email": "john@example.com",
      "product": "Product A",
      "rating": 5,
      "comment": "Excellent produit!",
      "sentiment_manual": "positive"
    }
  ]
}
```

**Modification dans `index.js` (lignes 110-130):**

```javascript
// ❌ AVANT:
async function getFeedbackData() {
    try {
        const data = fs.readFileSync('feedback_data.csv', 'utf-8');
        const rows = data.split('\n');
        const headers = rows[0].split(',');
        // ... traitement CSV ...
    } catch (error) {
        console.error('Error reading feedback:', error);
    }
}

// ✅ APRÈS: Appeler votre API
async function getFeedbackData() {
    try {
        const API_URL = process.env.FEEDBACK_API_URL || 'http://your-api.com/api';
        const response = await fetch(`${API_URL}/feedback`);
        const data = await response.json();
        return data.feedback; // Adapter selon votre structure
    } catch (error) {
        console.error('Error fetching feedback:', error);
        return [];
    }
}
```

**Ajouter dans `.env` (créer le fichier si absent):**

```env
FEEDBACK_API_URL=https://votre-api.com/api
```

### Cas 2B: Votre API retourne une structure différente

**Exemple:** Votre API retourne `{ "data": [ { "id": ..., "text": ... } ] }`

**Adapter le mapping dans `index.js`:**

```javascript
async function getFeedbackData() {
    try {
        const response = await fetch(process.env.FEEDBACK_API_URL + '/feedback');
        const result = await response.json();
        
        // Mapper votre structure à la structure attendue
        return result.data.map(item => ({
            feedback_id: item.id,
            timestamp: item.created_at,
            customer_name: item.user_name,
            email: item.user_email,
            product: item.category,
            rating: item.score,
            comment: item.text,
            sentiment_manual: item.sentiment || 'unknown'
        }));
    } catch (error) {
        console.error('Error fetching feedback:', error);
        return [];
    }
}
```

### Cas 2C: Votre API a une authentification

**Ajouter des variables d'environnement:**

```env
FEEDBACK_API_URL=https://votre-api.com/api
FEEDBACK_API_KEY=votre_clé_api_secrète
FEEDBACK_API_TOKEN=token_bearer_si_applicable
```

**Adapter la requête dans `index.js`:**

```javascript
async function getFeedbackData() {
    try {
        const headers = {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.FEEDBACK_API_TOKEN}`
        };
        
        const response = await fetch(
            `${process.env.FEEDBACK_API_URL}/feedback`,
            { headers }
        );
        
        if (!response.ok) throw new Error(`API returned ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error('Error fetching feedback:', error);
        return [];
    }
}
```

---

## 🐳 Lancer avec Docker

Si vous préférez utiliser Docker:

```bash
# Construire l'image
docker build -t feedback-api .

# Lancer le conteneur
docker run -p 3000:3000 -e DB_HOST=localhost feedback-api

# Ou avec Docker Compose
docker-compose up
```

**Pour utiliser une BD personnalisée, modifier `docker-compose.yml`:**

```yaml
services:
  api:
    build: .
    environment:
      - DB_HOST=votre-host
      - DB_USER=votre-user
      - DB_PASSWORD=votre-motdepasse
      - DB_NAME=votre-db
      - FEEDBACK_API_URL=https://votre-api.com
```

---

## 📊 Endpoints Disponibles

### 1. Health Check

```
GET /api/health
```

Retourne: État de la connexion et nombre de feedbacks

### 2. Statistiques

```
GET /api/stats
```

Retourne: Moyenne des notes, distribution sentiments, etc.

### 3. Liste des Feedbacks

```
GET /api/feedback?limit=10&offset=0
```

Retourne: Liste paginée des feedbacks

### 4. Analyser un Sentiment

```
POST /api/analyze
Body: { "text": "Votre texte ici" }
```

Retourne: Sentiment estimé (nécessite le service ML)

---

## ⚙️ Variables d'Environnement

Créez un fichier `.env` à la racine:

```env
# Port
PORT=3000

# Base de données (optionnel si utilisant CSV)
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=feedback_db

# Votre API personnalisée
FEEDBACK_API_URL=https://votre-api.com/api

# Service ML
SENTIMENT_API_URL=http://localhost:8080
ML_MODEL_PATH=./sentiment_model.pkl
```

---

## 🐛 Dépannage

### Problème: "feedback_data.csv not found"

**Solution:** Vérifiez que le fichier CSV est à la racine du projet

### Problème: "Cannot read property of undefined"

**Solution:** Vérifiez que votre CSV ou API retourne la bonne structure

### Problème: "Cannot connect to ML service"

**Solution:** Le service ML est optionnel, l'API continue sans lui

### Problème: CORS Error

**Solution:** CORS est déjà activé dans `index.js`, vérifiez vos domaines autorisés

---

## 📝 Checklist de Vérification

- [ ] Fichier CSV ou API configuré
- [ ] Variables d'environnement définies
- [ ] `npm install` exécuté
- [ ] `node index.js` démarre sans erreur
- [ ] `/api/health` retourne `{"success": true}`
- [ ] `/api/feedback` retourne vos données
- [ ] `/api/stats` affiche les statistiques

---

## 📞 Support

Si vous avez des questions sur l'intégration de vos données:

1. Vérifiez que votre structure correspond aux exemples
2. Testez avec `curl` ou Postman
3. Regardez les logs dans la console

**Bon courage! 🎓**
