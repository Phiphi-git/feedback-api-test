# 🚀 GUIDE COMPLET - Déployer sur Google Cloud

## ÉTAPE 1: Configurer le fichier `.env` (FAIT ✅)

Le fichier `.env` est créé. Vous devez juste remplir les valeurs:

```env
DB_HOST=34.155.20.62
DB_USER=root
DB_PASSWORD=test
DB_NAME=test
TABLE_NAME=raw_feedback
PORT=3000
NODE_ENV=production
```

**Comment trouver l'IP Cloud SQL?**

1. Google Cloud Console
2. SQL
3. Cliquez sur votre instance
4. Cherchez "Public IP address"

---

## ÉTAPE 2: Créer la base de données (À FAIRE)

### Via Google Cloud Console

1. Ouvrez Google Cloud Console
2. Allez à **SQL**
3. Cliquez sur votre instance
4. Onglet **Query editor**
5. Copier-collez le contenu du fichier `CREATE_DATABASE.sql`
6. Cliquez sur **Execute**

### Ou via gcloud CLI

```bash
-- Utiliser la base de données test (déjà existante)
USE test;

-- Créer la table raw_feedback si elle n'existe pas
CREATE TABLE IF NOT EXISTS raw_feedback (
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

---

## ÉTAPE 3: Importer le CSV (À FAIRE)

### Via Google Cloud Console

1. SQL → Votre instance
2. Onglet **Import**
3. Cliquez sur **Create Import**
4. Sélectionnez `feedback_data.csv` depuis votre ordinateur
5. Database: `test`
6. Table: `raw_feedback`
7. Cliquez sur **Importer**

### Ou via gcloud CLI

```bash
# Créer un bucket Cloud Storage
gsutil mb gs://mon-bucket-feedback

# Uploader le CSV
gsutil cp feedback_data.csv gs://mon-bucket-feedback/

# Importer dans Cloud SQL
gcloud sql import csv feedback-db \
  gs://mon-bucket-feedback/feedback_data.csv \
  --database=test \
  --table=raw_feedback
```

---

## ÉTAPE 4: Tester localement (PRÊT ✅)

```bash
# Dans votre terminal PowerShell

# 1. Aller au dossier du projet
cd c:\Users\HP\Downloads\feedback-api-test

# 2. Installer les dépendances
npm install

# 3. Lancer l'API
node index.js

# 4. Ouvrir dans le navigateur
# http://localhost:3000/api/health
# http://localhost:3000/api/stats
```

---

## ÉTAPE 5: Déployer sur Cloud Run (OPTIONNEL)

### Via gcloud CLI

```bash
# 1. D'abord, configurez gcloud
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 2. Allez au dossier du projet
cd c:\Users\HP\Downloads\feedback-api-test

# 3. Déployez avec les variables d'environnement
gcloud run deploy feedback-api \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=YOUR_IP,DB_USER=root,DB_PASSWORD=YOUR_PASS,DB_NAME=feedback_db

# 4. Google Cloud vous donnera une URL comme:
# https://feedback-api-xyz.run.app

# 5. Testez:
# curl https://feedback-api-xyz.run.app/api/health
```

---

## 📋 FICHIERS CRÉÉS POUR VOUS

✅ `.env` - Configuration locale (remplissez les valeurs)
✅ `CREATE_DATABASE.sql` - Script pour créer la table
✅ `Dockerfile` - Pour déployer sur Cloud Run
✅ `.gitignore` - Pour éviter de push les secrets

---

## 🎯 PROCHAINES ÉTAPES

1. **Ouvrez `.env`** et remplissez les valeurs réelles
2. **Exécutez `CREATE_DATABASE.sql`** dans Cloud Console
3. **Importez `feedback_data.csv`** dans Cloud SQL
4. **Testez localement** avec `node index.js`
5. **Déployez** sur Cloud Run quand c'est prêt

---

## 🆘 EN CAS DE PROBLÈME

**"Connection refused"**
→ Vérifiez que Cloud SQL instance est "running"

**"Access denied"**
→ Vérifiez le mot de passe dans `.env`

**"Table doesn't exist"**
→ Vérifiez que `CREATE_DATABASE.sql` a été exécuté et que le CSV a été importé

**"Cannot connect to database"**
→ Vérifiez que `DB_HOST` est la bonne IP

---

## 📞 BESOIN D'AIDE?

Dites-moi quelle étape pose problème et je vous aiderai! 💪
