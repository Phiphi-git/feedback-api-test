# 📊 Feedback API - Guide Cloud SQL

Bonjour! Voici comment mettre en place cette API avec Cloud SQL.

## 📦 Fichiers reçus

```
├── index.js                           # API avec données JSON locales
├── index-cloud-sql-template.js        # API adaptée pour Cloud SQL
├── package.json                       # Dépendances
├── feedback_data.csv                  # Données à importer
└── TESTING_GUIDE.md                   # Guide de test
```

---

## 🚀 Démarrage rapide

### Option 1: Tester localement d'abord

**1. Installer les dépendances**

```bash
npm install
```

**2. Démarrer l'API (mode fichier JSON)**

```bash
node index.js
```

**3. Tester dans le navigateur**

```
http://localhost:3000/api/health
http://localhost:3000/api/stats
```

---

### Option 2: Utiliser Cloud SQL (Production)

#### Étape 1: Créer une instance Cloud SQL

Dans Google Cloud Console:

1. Aller à **SQL** → **Créer une instance**
2. Sélectionner **MySQL 8.0**
3. Configuration:
   - ID: `feedback-db`
   - Region: `europe-west1` (ou votre région)
   - Machine: `db-f1-micro` (gratuit)

#### Étape 2: Créer la base de données

```sql
CREATE DATABASE IF NOT EXISTS feedback_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE feedback_db;

CREATE TABLE feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    feedback_date DATE,
    campaign_id VARCHAR(50),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_campaign (campaign_id),
    INDEX idx_date (feedback_date)
);
```

#### Étape 3: Importer les données CSV

**Via Cloud Console:**

1. Cliquez sur l'instance Cloud SQL
2. Allez à **Import**
3. Téléchargez `feedback_data.csv`
4. Sélectionnez `feedback_db.feedbacks`
5. Cliquez sur **Importer**

**Ou via gcloud CLI:**

```bash
# Créer un bucket Cloud Storage
gsutil mb gs://mon-bucket

# Uploader le CSV
gsutil cp feedback_data.csv gs://mon-bucket/

# Importer dans Cloud SQL
gcloud sql import csv feedback-db \
  gs://mon-bucket/feedback_data.csv \
  --database=feedback_db \
  --table=feedbacks
```

#### Étape 4: Configurer l'API

**1. Créer un fichier `.env`**

```env
DB_HOST=34.123.45.67  # L'IP de votre instance Cloud SQL
DB_USER=root
DB_PASSWORD=votre_mot_de_passe
DB_NAME=feedback_db
PORT=3000
NODE_ENV=production
```

**2. Installer les dépendances MySQL**

```bash
npm install mysql2
```

**3. Renommer le fichier Cloud SQL**

```bash
mv index-cloud-sql-template.js index.js
```

**4. Lancer l'API**

```bash
node index.js
```

**5. Tester**

```bash
curl http://localhost:3000/api/health
curl http://localhost:3000/api/stats
```

---

## 🌐 Déployer sur Google Cloud Run

Créez un `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install --production && npm install mysql2

COPY index-cloud-sql-template.js index.js

ENV PORT=3000
EXPOSE 3000

CMD ["node", "index.js"]
```

Déployez:

```bash
# Mettre en place le fichier .env
export DB_HOST=34.123.45.67
export DB_USER=root
export DB_PASSWORD=password
export DB_NAME=feedback_db

# Déployer
gcloud run deploy feedback-api \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=$DB_HOST,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,DB_NAME=$DB_NAME
```

---

## 🔐 Sécurité

**AVANT de mettre en production:**

1. ✅ Ajouter une authentification API Key
2. ✅ Utiliser HTTPS
3. ✅ Ajouter un mot de passe fort à Cloud SQL
4. ✅ Restreindre l'accès aux IPs
5. ✅ Chiffrer les variables sensibles

### Exemple: Ajouter une API Key

```javascript
// Dans index.js
const API_KEY = process.env.API_KEY;

app.use((req, res, next) => {
    const key = req.headers['x-api-key'];
    if (key !== API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
});
```

Puis utilisez:

```bash
curl -H "x-api-key: YOUR_KEY" http://localhost:3000/api/health
```

---

## 📋 Endpoints disponibles

```
GET  /api/health                      # Vérifier la connexion
GET  /api/feedbacks?page=1&limit=50   # Tous les feedbacks (paginé)
GET  /api/feedbacks/:id               # Un feedback spécifique
GET  /api/feedbacks-by-user/:username # Feedbacks d'un utilisateur
GET  /api/campaign/:campaignId        # Feedbacks d'une campagne
GET  /api/search/:keyword             # Rechercher dans les commentaires
GET  /api/stats                       # Statistiques
GET  /api/export/json                 # Exporter en JSON
```

---

## 🆘 Troubleshooting

### "Connection refused"

```
Vérifier que:
1. Cloud SQL instance est running
2. DB_HOST est la bonne IP
3. Firewall autorise votre IP
```

### "Access denied for user 'root'"

```
Vérifier:
1. DB_USER et DB_PASSWORD sont corrects
2. L'utilisateur existe dans Cloud SQL
```

### "Table doesn't exist"

```
Vérifier que le CSV a été importé correctement:
gcloud sql operations list --instance=feedback-db
```

### "Too many connections"

```
Modifier dans index.js:
connectionLimit: 10  // Augmenter si nécessaire
```

---

## 📊 Exemples d'utilisation

**JavaScript/Fetch:**

```javascript
const response = await fetch('http://localhost:3000/api/feedbacks?limit=10');
const data = await response.json();
console.log(data);
```

**Python:**

```python
import requests

response = requests.get('http://localhost:3000/api/feedbacks')
data = response.json()
print(data)
```

**cURL:**

```bash
curl http://localhost:3000/api/stats | jq
```

---

## ✅ Checklist

- [ ] Cloud SQL instance créée
- [ ] Base de données `feedback_db` créée
- [ ] Table `feedbacks` créée
- [ ] CSV importé avec succès
- [ ] `.env` configuré
- [ ] `npm install` exécuté
- [ ] API démarre sans erreurs
- [ ] `/api/health` retourne `success: true`
- [ ] `/api/stats` montre les bonnes statistiques
- [ ] Prêt pour la production!

---

## 💡 Conseils

1. **Backup réguliers**: Configurer des exports automatiques du CSV
2. **Monitoring**: Utiliser Google Cloud Monitoring
3. **Logs**: Consulter les logs avec `gcloud sql operations list`
4. **Scaling**: Utiliser Cloud Run pour l'auto-scaling

---

## 📞 Support

En cas de problème, consultez:

- [Documentation Cloud SQL](https://cloud.google.com/sql/docs)
- [Documentation Cloud Run](https://cloud.google.com/run/docs)
- [Forum Google Cloud](https://stackoverflow.com/questions/tagged/google-cloud-platform)

Bonne chance! 🚀
