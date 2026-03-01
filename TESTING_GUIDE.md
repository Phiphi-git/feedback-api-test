# 📊 RÉSUMÉ - Comment tester et utiliser votre API

## ✅ Statut: L'API est OPÉRATIONNELLE

L'API fonctionne sur: **<http://localhost:3000>**

---

## 🧪 Tests rapides à faire

### Test 1: Vérifier que l'API répond

```powershell
Invoke-WebRequest -Uri "http://localhost:3000/api/health" -UseBasicParsing
```

**Résultat attendu:**

```json
{
  "success": true,
  "message": "API fonctionnelle",
  "timestamp": "2026-02-28T22:24:55.542Z"
}
```

### Test 2: Voir les statistiques

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:3000/api/stats" -UseBasicParsing
$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

**Résultat actuel:**

- 📊 Total: 100 feedbacks
- 👥 Utilisateurs uniques: 66
- 🎯 Campagnes uniques: 91
- 💬 Types de commentaires: 8 différents

### Test 3: Voir les feedbacks (5 premiers)

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:3000/api/feedbacks?page=1&limit=5" -UseBasicParsing
$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

### Test 4: Rechercher par mot-clé

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:3000/api/search/great" -UseBasicParsing
$response.Content | ConvertFrom-Json | Select-Object -ExpandProperty count
```

### Test 5: Exporter en CSV

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:3000/api/export/csv" -UseBasicParsing
$response.Content | Out-File -FilePath "C:\Users\HP\Downloads\feedback_export.csv" -Encoding UTF8
Write-Host "✅ CSV exporté!"
```

---

## 🌐 Tous les Endpoints

### 1. Health Check

```
GET /api/health
```

Vérifie que l'API fonctionne.

### 2. Tous les feedbacks (avec pagination)

```
GET /api/feedbacks?page=1&limit=10
```

Paramètres optionnels:

- `page` - Numéro de page (défaut: 1)
- `limit` - Résultats par page (défaut: 50)

### 3. Un feedback spécifique

```
GET /api/feedbacks/0
GET /api/feedbacks/5
```

Retourne le feedback à l'index donné.

### 4. Feedbacks d'un utilisateur

```
GET /api/feedbacks-by-user/user_fb68
GET /api/feedbacks-by-user/user_fb46
```

### 5. Feedbacks d'une campagne

```
GET /api/campaign/CAMP147
GET /api/campaign/CAMP892
```

### 6. Rechercher dans les commentaires

```
GET /api/search/great
GET /api/search/creative
GET /api/search/organized
```

### 7. Statistiques

```
GET /api/stats
```

Retourne les statistiques globales.

### 8. Exporter en CSV

```
GET /api/export/csv
```

Télécharge tous les feedbacks en CSV.

### 9. Exporter en JSON

```
GET /api/export/json
```

Télécharge tous les feedbacks en JSON.

---

## 📦 Envoyer à votre ami pour Cloud SQL

### Étape 1: Exporter les données en CSV

```powershell
$response = Invoke-WebRequest -Uri "http://localhost:3000/api/export/csv" -UseBasicParsing
$response.Content | Out-File -FilePath "feedback_data.csv" -Encoding UTF8
```

### Étape 2: Préparer le dossier à envoyer

Créer un dossier avec ces fichiers:

```
feedback-api-for-cloudsql/
├── index-cloud-sql.js           ← Code adapté pour Cloud SQL
├── package.json                 ← Dépendances
├── feedback_data.csv            ← Les données
├── CLOUD_SQL_INSTRUCTIONS.md    ← Instructions pour votre ami
└── README.md                    ← Documentation générale
```

### Étape 3: Envoyer à votre ami via email/Drive

Votre ami devra:

1. **Créer une base de données Cloud SQL**
   - Via Google Cloud Console
   - Choisir MySQL ou PostgreSQL

2. **Créer la table**

```sql
CREATE TABLE feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255),
    feedback_date DATE,
    campaign_id VARCHAR(50),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

1. **Importer le CSV**
   - Utiliser Cloud Console ou la commande `gcloud`

2. **Lancer l'API**

```bash
npm install
npm install mysql2
node index-cloud-sql.js
```

---

## 🔗 Ouvrir l'API dans le navigateur

Vous pouvez simplement ouvrir ces URLs dans votre navigateur:

- Health: <http://localhost:3000/api/health>
- Stats: <http://localhost:3000/api/stats>
- Feedbacks: <http://localhost:3000/api/feedbacks>
- Export CSV: <http://localhost:3000/api/export/csv>

---

## 📋 Checklist

✅ L'API démarre sans erreurs
✅ `/api/health` fonctionne
✅ Les données se chargent (100 feedbacks)
✅ `/api/stats` retourne les statistiques
✅ `/api/feedbacks` liste les données
✅ `/api/export/csv` permet d'exporter
✅ Prêt à partager avec votre ami!

---

## 🚀 Prochaines étapes

1. **Testez tous les endpoints** à l'aide des commandes ci-dessus
2. **Exportez les données** en CSV
3. **Envoyez les fichiers** à votre ami
4. **Votre ami les ingère** dans Cloud SQL
5. **Profitez de votre API!** 🎉

---

## 📞 Questions?

Le fichier `CLOUD_SQL_INSTRUCTIONS.md` contient un guide complet pour votre ami.

Enjoy! 🚀
