# Script pour préparer les fichiers à envoyer à votre ami pour Cloud SQL
# Usage: .\prepare-for-cloudsql.ps1

Write-Host "📦 Préparation des fichiers pour Cloud SQL`n" -ForegroundColor Green

$projectDir = "C:\Users\HP\Downloads\feedback-api-test"
$releaseDir = "C:\Users\HP\Downloads\feedback-api-cloudsql"

Write-Host "📁 Création du dossier de release..." -ForegroundColor Cyan

# Créer le dossier
if (Test-Path $releaseDir) {
    Write-Host "  ⚠️ Le dossier existe déjà, suppression..." -ForegroundColor Yellow
    Remove-Item $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir | Out-Null
Write-Host "  ✅ Dossier créé: $releaseDir`n" -ForegroundColor Green

# Fichiers à copier
$filesToCopy = @(
    "package.json",
    "package-lock.json",
    "index-cloud-sql-template.js",
    "README_CLOUD_SQL.md",
    "feedback_data.csv"
)

Write-Host "📋 Copie des fichiers essentiels...`n" -ForegroundColor Cyan

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $projectDir $file
    $destPath = Join-Path $releaseDir $file
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath
        $fileSize = (Get-Item $destPath).Length
        Write-Host "  ✅ $file ($([Math]::Round($fileSize/1024, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $file - non trouvé" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📄 Création d'un fichier SETUP.md pour votre ami...`n" -ForegroundColor Cyan

$setupContent = @"
# 🚀 Mise en place rapide - Cloud SQL

Bonjour! Voici comment mettre en place cette API avec Cloud SQL.

## 📥 Installation locale (Test)

\`\`\`bash
npm install
node index-cloud-sql-template.js
\`\`\`

Tester: http://localhost:3000/api/health

## ☁️ Cloud SQL (Production)

### 1. Créer une instance Cloud SQL
- Google Cloud Console → SQL
- Créer une instance MySQL 8.0
- Region: europe-west1

### 2. Créer la table

\`\`\`sql
CREATE DATABASE feedback_db;
USE feedback_db;

CREATE TABLE feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255),
    feedback_date DATE,
    campaign_id VARCHAR(50),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_campaign (campaign_id)
);
\`\`\`

### 3. Importer le CSV

Via Cloud Console:
1. Allez à Import
2. Sélectionnez feedback_data.csv
3. Cliquez sur Importer

### 4. Configurer l'API

Créer un fichier \`.env\`:
\`\`\`
DB_HOST=votre_ip_cloud_sql
DB_USER=root
DB_PASSWORD=votre_password
DB_NAME=feedback_db
PORT=3000
\`\`\`

### 5. Lancer

\`\`\`bash
npm install mysql2
node index-cloud-sql-template.js
\`\`\`

### 6. Déployer sur Cloud Run

\`\`\`bash
gcloud run deploy feedback-api \\
  --source . \\
  --region europe-west1 \\
  --allow-unauthenticated \\
  --set-env-vars DB_HOST=IP,DB_USER=root,DB_PASSWORD=PASS,DB_NAME=feedback_db
\`\`\`

## 🔗 Endpoints

GET /api/health
GET /api/feedbacks
GET /api/stats
GET /api/search/{keyword}
GET /api/export/json

Voir README_CLOUD_SQL.md pour plus de détails.

Bonne chance! 🎉
"@

$setupPath = Join-Path $releaseDir "SETUP.md"
$setupContent | Out-File $setupPath -Encoding UTF8
Write-Host "  ✅ SETUP.md créé`n" -ForegroundColor Green

# Créer un .env.example
$envExample = @"
# Configuration Cloud SQL
DB_HOST=34.123.45.67
DB_USER=root
DB_PASSWORD=votre_mot_de_passe_ici
DB_NAME=feedback_db
PORT=3000
NODE_ENV=production
"@

$envPath = Join-Path $releaseDir ".env.example"
$envExample | Out-File $envPath -Encoding UTF8
Write-Host "  ✅ .env.example créé`n" -ForegroundColor Green

# Vérifier les données CSV
Write-Host "📊 Vérification du fichier CSV...`n" -ForegroundColor Cyan

$csvPath = Join-Path $releaseDir "feedback_data.csv"
if (Test-Path $csvPath) {
    $csvLines = (Get-Content $csvPath).Count
    $csvSize = (Get-Item $csvPath).Length
    Write-Host "  ✅ feedback_data.csv: $csvLines lignes, $([Math]::Round($csvSize/1024, 2)) KB`n" -ForegroundColor Green
}

# Créer un checklist
$checklistPath = Join-Path $releaseDir "CHECKLIST.txt"
@"
📋 CHECKLIST POUR VOTRE AMI

Avant de commencer:
  □ Google Cloud Project créé
  □ gcloud CLI installé et configuré
  □ Permissions pour créer Cloud SQL et Cloud Run

Installation:
  □ npm install
  □ Créer instance Cloud SQL
  □ Créer table feedbacks (voir SETUP.md)
  □ Importer feedback_data.csv

Configuration:
  □ Créer fichier .env (voir .env.example)
  □ Ajouter les credentials Cloud SQL
  □ npm install mysql2

Test:
  □ node index-cloud-sql-template.js
  □ Tester http://localhost:3000/api/health
  □ Vérifier /api/stats

Déploiement (optionnel):
  □ gcloud run deploy...
  □ Configurer les variables d'environnement
  □ Tester l'API en production

Support:
  - Voir README_CLOUD_SQL.md pour détails
  - Voir SETUP.md pour étapes rapides
  - Documentation Cloud SQL: https://cloud.google.com/sql/docs
"@ | Out-File $checklistPath -Encoding UTF8

Write-Host "  ✅ CHECKLIST.txt créé`n" -ForegroundColor Green

# Résumé final
Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "✅ PRÉPARATION TERMINÉE!" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Magenta

Write-Host "`n📂 Fichiers prêts dans:" -ForegroundColor Cyan
Write-Host "   $releaseDir`n" -ForegroundColor Yellow

Write-Host "📦 Fichiers inclus:" -ForegroundColor Cyan
Get-ChildItem $releaseDir -File | ForEach-Object {
    $size = [Math]::Round($_.Length/1024, 2)
    Write-Host "   ✅ $($_.Name) ($size KB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "🚀 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "   1. Compresser le dossier: Compress-Archive -Path $releaseDir -DestinationPath api.zip" -ForegroundColor Gray
Write-Host "   2. Envoyer api.zip à votre ami" -ForegroundColor Gray
Write-Host "   3. Votre ami suit les étapes de SETUP.md" -ForegroundColor Gray
Write-Host "   4. L'API fonctionne sur Cloud SQL! 🎉" -ForegroundColor Gray

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Magenta
