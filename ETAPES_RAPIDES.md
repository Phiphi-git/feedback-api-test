# ⚡ RÉSUMÉ RAPIDE - 5 ÉTAPES

## 📋 Ce qui a été créé pour vous

✅ `.env` - fichier de configuration (REMPLIR LES VALEURS)
✅ `CREATE_DATABASE.sql` - créer la table dans Cloud SQL
✅ `Dockerfile` - pour déployer sur Cloud Run
✅ `.gitignore` - éviter de pousser les secrets
✅ `GUIDE_CLOUD_DEPLOY.md` - guide détaillé
✅ `GCLOUD_COMMANDS.md` - commandes prêtes à copier-coller
✅ `test-api-local.ps1` - script de test PowerShell

---

## 🎯 PLAN D'ACTION

### ÉTAPE 1: Remplir le fichier `.env`

Ouvrez `.env` et remplacez:

```env
DB_HOST=34.155.20.62             ← Votre IP (déjà remplie ✅)
DB_USER=root
DB_PASSWORD=test                 ← Votre mot de passe (déjà rempli ✅)
DB_NAME=test                     ← Votre base de données
TABLE_NAME=raw_feedback          ← Votre table
PORT=3000
NODE_ENV=production
```

**Où trouver l'IP?**

- Google Cloud Console → SQL → Votre instance → "Public IP address"

---

### ÉTAPE 2: Créer la base de données

**Via Google Cloud Console:**

1. Allez à **SQL** → **Query editor**
2. Sélectionnez votre instance
3. Ouvrez le fichier `CREATE_DATABASE.sql` (ici même)
4. Copiez tout le contenu
5. Collez dans Query editor
6. Cliquez **Execute**

⚠️ **IMPORTANT:** Si votre table `raw_feedback` existe déjà, ignorez cette étape.

**Ou via terminal:**

```bash
gcloud sql connect feedback-db --user=root
# Puis copiez-collez le contenu de CREATE_DATABASE.sql
```

---

### ÉTAPE 3: Importer le CSV

**Via Google Cloud Console:**

1. SQL → Votre instance → **Import**
2. **Create Import**
3. Fichier: `feedback_data.csv`
4. Database: `test`           ← Votre base de données
5. Table: `raw_feedback`      ← Votre table
6. **Importer**

**Ou via gcloud:**

```bash
# Uploader
gsutil cp feedback_data.csv gs://mon-bucket/

# Importer
gcloud sql import csv feedback-db gs://mon-bucket/feedback_data.csv \
  --database=test \
  --table=raw_feedback
```

---

### ÉTAPE 4: Tester localement

```powershell
# Terminal PowerShell

cd c:\Users\HP\Downloads\feedback-api-test

# Installer les dépendances
npm install

# Lancer l'API
node index.js

# Dans une AUTRE terminal PowerShell, tester:
.\test-api-local.ps1

# Si tous les tests sont ✅, c'est bon!
```

---

### ÉTAPE 5: Déployer sur Cloud Run

```bash
# Terminal (cmd ou powershell)

cd c:\Users\HP\Downloads\feedback-api-test

# Remplacez les valeurs
gcloud run deploy feedback-api \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=34.155.20.62,DB_USER=root,DB_PASSWORD=test,DB_NAME=test

# Google vous donnera une URL comme:
# https://feedback-api-xyz.run.app

# Testez:
curl https://feedback-api-xyz.run.app/api/health
```

---

## 📝 CHECKLIST

- [ ] `.env` rempli avec les vraies valeurs
- [ ] `CREATE_DATABASE.sql` exécuté dans Cloud SQL
- [ ] CSV importé dans Cloud SQL (100+ lignes)
- [ ] `npm install` réussi
- [ ] `node index.js` démarre sans erreurs
- [ ] Tests PowerShell réussis (5/5 ✅)
- [ ] Déploiement Cloud Run réussi
- [ ] API accessible via l'URL donnée

---

## 💡 FICHIERS CLÉS

```
feedback-api-test/
├── .env                         ← REMPLIR (secrets)
├── index.js                     ← Code de l'API
├── Dockerfile                   ← Pour Cloud Run
├── CREATE_DATABASE.sql          ← Exécuter dans Cloud SQL
├── feedback_data.csv            ← Importer dans Cloud SQL
├── GUIDE_CLOUD_DEPLOY.md        ← Guide détaillé
├── GCLOUD_COMMANDS.md           ← Commandes gcloud
└── test-api-local.ps1           ← Tests PowerShell
```

---

## ❓ J'SUIS BLOQUÉ

**"Connection refused"** → Cloud SQL n'est pas running
**"Access denied"** → Mauvais mot de passe dans `.env`
**"Table doesn't exist"** → CREATE_DATABASE.sql n'a pas été exécuté
**"API ne démarre pas"** → `npm install` n'a pas été fait

**Besoin d'aide? Dis-moi à quelle étape tu bloques!** 💪
