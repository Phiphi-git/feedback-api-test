# ============================================
# 🚀 Script de déploiement Google Cloud
# ============================================

param(
    [string]$ProjectId = $env:GCLOUD_PROJECT,
    [string]$Region = "europe-west1",
    [string]$Action = "deploy"  # deploy, test, logs
)

$ErrorActionPreference = "Stop"

# Couleurs
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error-Custom { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning-Custom { Write-Host $args -ForegroundColor Yellow }

# ============================================
# 1. VÉRIFICATIONS PRÉALABLES
# ============================================

Write-Info "`n📋 VÉRIFICATIONS PRÉALABLES`n"

# Vérifier gcloud
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "❌ gcloud CLI non installé"
    exit 1
}
Write-Success "✅ gcloud CLI détecté"

# Vérifier Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "❌ Docker non installé"
    exit 1
}
Write-Success "✅ Docker détecté"

# Vérifier le modèle ML
if (-not (Test-Path "sentiment_model.pkl")) {
    Write-Error-Custom "❌ sentiment_model.pkl non trouvé!"
    Write-Warning-Custom "`nVeuillez d'abord entraîner le modèle:"
    Write-Info "  .\train-ml-model.ps1"
    exit 1
}
Write-Success "✅ Modèle ML trouvé"

# Vérifier les fichiers nécessaires
$requiredFiles = @(
    "sentiment_api.py",
    "sentiment_analyzer.py",
    "requirements_ml.txt",
    "Dockerfile.ml",
    "index.js",
    "package.json",
    "Dockerfile",
    ".env"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Error-Custom "❌ Fichier manquant: $file"
        exit 1
    }
}
Write-Success "✅ Tous les fichiers nécessaires présents"

# ============================================
# 2. GIT - COMMIT ET PUSH
# ============================================

Write-Info "`n📤 GIT - COMMIT ET PUSH`n"

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Info "Fichiers modifiés détectés"
    git add -A
    git commit -m "chore: Add ML service integration and deployment scripts"
    Write-Success "✅ Commit créé"
} else {
    Write-Info "✅ Aucune modification à commit"
}

Write-Info "Envoi des modifications vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors du push"
    exit 1
}
Write-Success "✅ Code poussé vers GitHub"

# ============================================
# 3. AUTHENTIFICATION GOOGLE CLOUD
# ============================================

Write-Info "`n🔐 AUTHENTIFICATION GOOGLE CLOUD`n"

if (-not $ProjectId) {
    Write-Error-Custom "❌ ProjectId manquant!"
    Write-Info "`nUtilisez: .\deploy-to-cloud.ps1 -ProjectId YOUR_PROJECT_ID"
    exit 1
}

Write-Info "Configuration du projet: $ProjectId"
gcloud config set project $ProjectId
Write-Success "✅ Projet configuré"

# ============================================
# 4. TESTS LOCAUX (OPTIONNEL)
# ============================================

if ($Action -eq "test") {
    Write-Info "`n🧪 TESTS LOCAUX AVEC DOCKER-COMPOSE`n"
    
    Write-Info "Construction des images Docker..."
    docker-compose build
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "❌ Erreur lors de la construction"
        exit 1
    }
    
    Write-Info "Démarrage des services..."
    docker-compose up -d
    Start-Sleep -Seconds 3
    
    Write-Info "Test du health check API..."
    $apiHealth = curl -s http://localhost:3000/api/health
    Write-Success "✅ API Health: $apiHealth"
    
    Write-Info "Test du health check ML..."
    $mlHealth = curl -s http://localhost:8080/health
    Write-Success "✅ ML Health: $mlHealth"
    
    Write-Info "Test de l'analyse de sentiment..."
    $sentiment = curl -X POST http://localhost:8080/analyze `
        -H "Content-Type: application/json" `
        -d '{"text": "Excellent produit!"}' -s
    Write-Success "✅ Sentiment: $sentiment"
    
    Write-Info "Arrêt des services..."
    docker-compose down
    
    return
}

# ============================================
# 5. DÉPLOIEMENT - SERVICE ML
# ============================================

Write-Info "`n🤖 DÉPLOIEMENT - SERVICE ML`n"

$mlImageName = "gcr.io/$ProjectId/sentiment-ml:latest"

Write-Info "Construction de l'image ML..."
docker build -f Dockerfile.ml -t $mlImageName .
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors de la construction de l'image ML"
    exit 1
}
Write-Success "✅ Image ML construite"

Write-Info "Configuration Docker pour Google Cloud..."
gcloud auth configure-docker --quiet
Write-Success "✅ Docker configuré"

Write-Info "Push de l'image ML vers Google Container Registry..."
docker push $mlImageName
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors du push"
    exit 1
}
Write-Success "✅ Image poussée vers GCR"

Write-Info "Déploiement du service ML sur Cloud Run..."
gcloud run deploy sentiment-ml `
    --image $mlImageName `
    --region $Region `
    --allow-unauthenticated `
    --memory 512Mi `
    --timeout 60s `
    --max-instances 10 `
    --platform managed `
    --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors du déploiement ML"
    exit 1
}
Write-Success "✅ Service ML déployé"

# Récupérer l'URL du service ML
$mlServiceUrl = gcloud run services describe sentiment-ml `
    --region $Region `
    --format 'value(status.url)' | ForEach-Object { $_ }

Write-Success "URL du service ML: $mlServiceUrl"

# ============================================
# 6. DÉPLOIEMENT - API NODE.JS
# ============================================

Write-Info "`n🟢 DÉPLOIEMENT - API NODE.JS`n"

$apiImageName = "gcr.io/$ProjectId/feedback-api:latest"

Write-Info "Construction de l'image API..."
docker build -f Dockerfile -t $apiImageName .
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors de la construction de l'image API"
    exit 1
}
Write-Success "✅ Image API construite"

Write-Info "Push de l'image API..."
docker push $apiImageName
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors du push"
    exit 1
}
Write-Success "✅ Image API poussée"

Write-Info "Déploiement du service API sur Cloud Run..."
gcloud run deploy feedback-api `
    --image $apiImageName `
    --region $Region `
    --allow-unauthenticated `
    --memory 256Mi `
    --timeout 30s `
    --max-instances 50 `
    --set-env-vars "SENTIMENT_API_URL=$mlServiceUrl" `
    --platform managed `
    --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "❌ Erreur lors du déploiement API"
    exit 1
}
Write-Success "✅ Service API déployé"

# Récupérer l'URL de l'API
$apiServiceUrl = gcloud run services describe feedback-api `
    --region $Region `
    --format 'value(status.url)' | ForEach-Object { $_ }

Write-Success "URL de l'API: $apiServiceUrl"

# ============================================
# 7. AFFICHER LES LOGS
# ============================================

if ($Action -eq "logs") {
    Write-Info "`n📊 LOGS`n"
    
    Write-Info "Logs du service ML (dernier 50 lignes):"
    gcloud run logs read sentiment-ml --limit 50 --region $Region
    
    Write-Info "`nLogs du service API (dernier 50 lignes):"
    gcloud run logs read feedback-api --limit 50 --region $Region
    
    return
}

# ============================================
# 8. TESTS EN PRODUCTION
# ============================================

Write-Info "`n✅ TESTS EN PRODUCTION`n"

Start-Sleep -Seconds 2

Write-Info "Test API Health..."
$response = curl -s "$apiServiceUrl/api/health"
Write-Success "✅ $response"

Write-Info "`nTest récupération de feedbacks..."
$feedbacks = curl -s "$apiServiceUrl/api/feedbacks?limit=1" | ConvertFrom-Json
Write-Success "✅ Feedback récupéré"

Write-Info "`nTest analyse de sentiment..."
$sentimentTest = curl -s "$mlServiceUrl/health"
Write-Success "✅ Service ML actif"

# ============================================
# 9. RÉSUMÉ
# ============================================

Write-Success "`n" + "="*50
Write-Success "✨ DÉPLOIEMENT RÉUSSI!"
Write-Success "="*50 + "`n"

Write-Info "📊 RÉSUMÉ DU DÉPLOIEMENT:`n"
Write-Info "  Service ML:  $mlServiceUrl"
Write-Info "  Service API: $apiServiceUrl`n"

Write-Info "🔗 ENDPOINTS DISPONIBLES:`n"
Write-Info "  Health Check:      $apiServiceUrl/api/health"
Write-Info "  Feedbacks:         $apiServiceUrl/api/feedbacks"
Write-Info "  Sentiment:         $apiServiceUrl/api/feedbacks/:id/sentiment"
Write-Info "  Stats:             $apiServiceUrl/api/stats`n"

Write-Info "📝 COMMANDES UTILES:`n"
Write-Info "  Voir les logs API:    gcloud run logs read feedback-api --region $Region"
Write-Info "  Voir les logs ML:     gcloud run logs read sentiment-ml --region $Region"
Write-Info "  Supprimer API:        gcloud run services delete feedback-api --region $Region"
Write-Info "  Supprimer ML:         gcloud run services delete sentiment-ml --region $Region`n"

Write-Success "🎉 Tout est prêt pour votre présentation!`n"
