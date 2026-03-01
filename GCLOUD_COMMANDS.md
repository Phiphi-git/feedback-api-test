# 📜 Commandes gcloud prêtes à exécuter

## 1️⃣ CONFIGURATION INITIALE

### Se connecter à Google Cloud

```bash
gcloud auth login
```

### Définir votre projet

```bash
gcloud config set project YOUR_PROJECT_ID
```

### Vérifier la configuration

```bash
gcloud config list
```

---

## 2️⃣ GÉRER L'INSTANCE CLOUD SQL

### Créer une instance Cloud SQL

```bash
gcloud sql instances create feedback-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=europe-west1 \
  --root-password=your_secure_password
```

### Obtenir l'IP publique

```bash
gcloud sql instances describe feedback-db --format="get(ipAddresses[0].ipAddress)"
```

### Se connecter à la base de données

```bash
gcloud sql connect feedback-db --user=root
```

### Créer un utilisateur (optionnel)

```bash
gcloud sql users create app_user \
  --instance=feedback-db \
  --password=app_password
```

---

## 3️⃣ GÉRER LES DONNÉES

### Uploader le CSV dans Cloud Storage

```bash
# Créer un bucket
gsutil mb gs://feedback-bucket-unique

# Uploader le CSV
gsutil cp feedback_data.csv gs://feedback-bucket-unique/
```

### Importer le CSV dans Cloud SQL

```bash
gcloud sql import csv feedback-db \
  gs://feedback-bucket-unique/feedback_data.csv \
  --database=feedback_db \
  --table=feedbacks
```

### Exporter les données

```bash
gcloud sql export csv feedback-db \
  gs://feedback-bucket-unique/feedback_export.csv \
  --database=feedback_db \
  --table=feedbacks
```

---

## 4️⃣ DÉPLOYER SUR CLOUD RUN

### Déploiement simple

```bash
gcloud run deploy feedback-api \
  --source . \
  --region=europe-west1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=YOUR_IP,DB_USER=root,DB_PASSWORD=YOUR_PASS,DB_NAME=feedback_db
```

### Déploiement avec Secret Manager (plus sécurisé)

```bash
# Créer un secret pour le mot de passe
echo -n "your_password" | gcloud secrets create db-password --data-file=-

# Donner l'accès à Cloud Run
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:YOUR_PROJECT_ID@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor

# Déployer avec le secret
gcloud run deploy feedback-api \
  --source . \
  --region=europe-west1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=YOUR_IP,DB_USER=root,DB_NAME=feedback_db \
  --update-secrets DB_PASSWORD=db-password:latest
```

---

## 5️⃣ MONITORING ET LOGS

### Voir les logs

```bash
gcloud run logs read feedback-api --region=europe-west1 --limit=50
```

### Voir les opérations Cloud SQL

```bash
gcloud sql operations list --instance=feedback-db
```

### Vérifier les métriques

```bash
gcloud monitoring metrics list
```

---

## 6️⃣ NETTOYAGE

### Supprimer l'instance Cloud SQL

```bash
gcloud sql instances delete feedback-db
```

### Supprimer le service Cloud Run

```bash
gcloud run services delete feedback-api --region=europe-west1
```

### Vider le bucket Cloud Storage

```bash
gsutil -m rm -r gs://feedback-bucket-unique
```

---

## 💡 NOTES IMPORTANTES

1. **Remplacez `YOUR_PROJECT_ID`** par votre ID de projet Google Cloud
2. **Remplacez `YOUR_IP`** par l'IP publique de Cloud SQL
3. **Remplacez `your_password`** par un mot de passe sécurisé
4. **`europe-west1`** peut être changé selon votre région préférée
5. **N'oubliez pas** de configurer les firewall rules dans Cloud SQL

---

## 🔐 SÉCURITÉ

Avant la production:

- ✅ Utilisez Secret Manager pour les mots de passe
- ✅ Configurez les firewall rules
- ✅ Activez SSL/TLS pour les connexions
- ✅ Créez des backups réguliers
- ✅ Activez l'authentification API Key

---

## 📞 BESOIN D'AIDE?

```bash
# Voir l'aide pour une commande
gcloud sql --help
gcloud run --help
gcloud secrets --help
```
