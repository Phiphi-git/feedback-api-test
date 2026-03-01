# Script de déploiement ML sur Google Cloud Run (Windows)
# Usage: .\deploy-ml-cloud.ps1 -ProjectId YOUR_PROJECT_ID -Region europe-west1

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "europe-west1"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🚀 DÉPLOIEMENT ML SUR GOOGLE CLOUD RUN" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifications préalables
Write-Host "1️⃣  VÉRIFICATIONS PRÉALABLES" -ForegroundColor Blue
Write-Host ""

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "❌ gcloud CLI non installé" -ForegroundColor Red
    exit 1
}
Write-Host "✅ gcloud CLI détecté" -ForegroundColor Green

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker non installé" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Docker détecté" -ForegroundColor Green

if (-not (Test-Path "sentiment_model.pkl")) {
    Write-Host "⚠️  sentiment_model.pkl manquant" -ForegroundColor Yellow
    Write-Host "Le modèle sera entraîné lors du déploiement" -ForegroundColor Gray
}

Write-Host ""

# 2. Configuration Google Cloud
Write-Host "2️⃣  CONFIGURATION GOOGLE CLOUD" -ForegroundColor Blue
Write-Host ""

Write-Host "Configuration du projet: $ProjectId" -ForegroundColor Cyan
gcloud config set project $ProjectId
Write-Host "✅ Projet configuré" -ForegroundColor Green

Write-Host "Activation des APIs Google Cloud..." -ForegroundColor Cyan
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com --quiet
Write-Host "✅ APIs activées" -ForegroundColor Green

Write-Host ""

# 3. Configuration Docker pour GCR
Write-Host "3️⃣  CONFIGURATION DOCKER" -ForegroundColor Blue
Write-Host ""

gcloud auth configure-docker --quiet
Write-Host "✅ Docker configuré pour GCR" -ForegroundColor Green

Write-Host ""

# 4. Construire et pousser l'image ML
Write-Host "4️⃣  BUILD ET PUSH IMAGE ML" -ForegroundColor Blue
Write-Host ""

$ML_IMAGE_NAME = "gcr.io/$ProjectId/sentiment-ml:latest"

Write-Host "Construction de l'image ML..." -ForegroundColor Cyan
docker build -f Dockerfile.ml -t $ML_IMAGE_NAME .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la construction" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image construite" -ForegroundColor Green

Write-Host ""
Write-Host "Push de l'image vers GCR..." -ForegroundColor Cyan
docker push $ML_IMAGE_NAME

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du push" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Image pushée vers GCR" -ForegroundColor Green

Write-Host ""

# 5. Déployer sur Cloud Run
Write-Host "5️⃣  DÉPLOIEMENT SUR CLOUD RUN" -ForegroundColor Blue
Write-Host ""

Write-Host "Déploiement du service ML..." -ForegroundColor Cyan
gcloud run deploy sentiment-ml `
    --image $ML_IMAGE_NAME `
    --region $Region `
    --allow-unauthenticated `
    --memory 512Mi `
    --timeout 60s `
    --max-instances 10 `
    --platform managed `
    --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du déploiement" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Service ML déployé sur Cloud Run" -ForegroundColor Green

Write-Host ""

# 6. Récupérer l'URL du service
Write-Host "6️⃣  RÉCUPÉRATION DES INFORMATIONS" -ForegroundColor Blue
Write-Host ""

$ML_SERVICE_URL = gcloud run services describe sentiment-ml `
    --region $Region `
    --format 'value(status.url)'

Write-Host "✅ URL du service ML:" -ForegroundColor Green
Write-Host "$ML_SERVICE_URL" -ForegroundColor Cyan

Write-Host ""

# 7. Tests en production
Write-Host "7️⃣  TESTS EN PRODUCTION" -ForegroundColor Blue
Write-Host ""

Write-Host "Test du health check..." -ForegroundColor Cyan
try {
    $HEALTH_RESPONSE = curl -s "$ML_SERVICE_URL/health"
    Write-Host "Réponse: $HEALTH_RESPONSE" -ForegroundColor Gray
    
    if ($HEALTH_RESPONSE -match "healthy") {
        Write-Host "✅ Service ML actif et fonctionnel" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Service en cours de démarrage, réessayez dans 30 secondes" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Impossible de tester maintenant, le service démarre" -ForegroundColor Yellow
}

Write-Host ""

# 8. Résumé
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✨ DÉPLOIEMENT ML RÉUSSI!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Service ML déployé sur:" -ForegroundColor Green
Write-Host "$ML_SERVICE_URL" -ForegroundColor Yellow
Write-Host ""

Write-Host "Endpoints disponibles:" -ForegroundColor Green
Write-Host "  POST   $ML_SERVICE_URL/analyze" -ForegroundColor Gray
Write-Host "  GET    $ML_SERVICE_URL/health" -ForegroundColor Gray
Write-Host "  GET    $ML_SERVICE_URL/stats" -ForegroundColor Gray
Write-Host ""

Write-Host "À utiliser dans index.js:" -ForegroundColor Green
Write-Host "  SENTIMENT_API_URL=$ML_SERVICE_URL" -ForegroundColor Yellow
Write-Host ""

Write-Host "Commandes utiles:" -ForegroundColor Green
Write-Host "  Voir les logs:      gcloud run logs read sentiment-ml --region $Region" -ForegroundColor Gray
Write-Host "  Redéployer:         gcloud run deploy sentiment-ml --image $ML_IMAGE_NAME --region $Region" -ForegroundColor Gray
Write-Host "  Supprimer:          gcloud run services delete sentiment-ml --region $Region" -ForegroundColor Gray
Write-Host ""
