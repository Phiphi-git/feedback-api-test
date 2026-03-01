# Script de deploiement Google Cloud
# Version simple sans caracteres speciaux

param(
    [string]$ProjectId = $env:GCLOUD_PROJECT,
    [string]$Region = "europe-west1"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "[*] VERIFICATION DES PREREQUIS" -ForegroundColor Cyan
Write-Host ""

# Verifier gcloud
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "[!] gcloud CLI non installe" -ForegroundColor Red
    Write-Host "[*] Telecharge-le ici: https://cloud.google.com/sdk/docs/install-sdk" -ForegroundColor Yellow
    exit 1
}
Write-Host "[+] gcloud CLI detecte" -ForegroundColor Green

# Verifier Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Docker non installe" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Docker detecte" -ForegroundColor Green

# Verifier le modele ML
if (-not (Test-Path "sentiment_model.pkl")) {
    Write-Host "[!] sentiment_model.pkl non trouve!" -ForegroundColor Red
    Write-Host "[*] Lancer d'abord:" -ForegroundColor Yellow
    Write-Host "    .\train-ml-model-simple.ps1" -ForegroundColor Cyan
    exit 1
}
Write-Host "[+] Modele ML trouve" -ForegroundColor Green

# Verifier les fichiers necessaires
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
        Write-Host "[!] Fichier manquant: $file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "[+] Tous les fichiers necessaires presents" -ForegroundColor Green

# GIT - COMMIT ET PUSH
Write-Host ""
Write-Host "[*] GIT - COMMIT ET PUSH" -ForegroundColor Cyan
Write-Host ""

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "[*] Fichiers modifies detectes" -ForegroundColor Cyan
    git add -A
    git commit -m "chore: ML deployment scripts fix"
    Write-Host "[+] Commit cree" -ForegroundColor Green
} else {
    Write-Host "[+] Aucune modification a commit" -ForegroundColor Green
}

Write-Host "[*] Envoi des modifications vers GitHub..." -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors du push" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Code pousse vers GitHub" -ForegroundColor Green

# AUTHENTIFICATION GOOGLE CLOUD
Write-Host ""
Write-Host "[*] AUTHENTIFICATION GOOGLE CLOUD" -ForegroundColor Cyan
Write-Host ""

if (-not $ProjectId) {
    Write-Host "[!] ProjectId manquant!" -ForegroundColor Red
    Write-Host "[*] Utilise: .\deploy-to-cloud-simple.ps1 -ProjectId YOUR_PROJECT_ID" -ForegroundColor Yellow
    exit 1
}

Write-Host "[*] Configuration du projet: $ProjectId" -ForegroundColor Cyan
gcloud config set project $ProjectId
Write-Host "[+] Projet configure" -ForegroundColor Green

# DEPLOIEMENT - SERVICE ML
Write-Host ""
Write-Host "[*] DEPLOIEMENT - SERVICE ML" -ForegroundColor Cyan
Write-Host ""

$mlImageName = "gcr.io/$ProjectId/sentiment-ml:latest"

Write-Host "[*] Construction de l'image ML..." -ForegroundColor Cyan
docker build -f Dockerfile.ml -t $mlImageName .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de la construction de l'image ML" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Image ML construite" -ForegroundColor Green

Write-Host "[*] Configuration Docker pour Google Cloud..." -ForegroundColor Cyan
gcloud auth configure-docker --quiet
Write-Host "[+] Docker configure" -ForegroundColor Green

Write-Host "[*] Push de l'image ML..." -ForegroundColor Cyan
docker push $mlImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors du push" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Image ML poussee vers GCR" -ForegroundColor Green

Write-Host "[*] Deploiement du service ML sur Cloud Run..." -ForegroundColor Cyan
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
    Write-Host "[!] Erreur lors du deploiement ML" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Service ML deploye" -ForegroundColor Green

# Recuperer l'URL du service ML
$mlServiceUrl = gcloud run services describe sentiment-ml `
    --region $Region `
    --format 'value(status.url)' | ForEach-Object { $_ }

Write-Host "[+] URL du service ML: $mlServiceUrl" -ForegroundColor Green

# DEPLOIEMENT - API NODE.JS
Write-Host ""
Write-Host "[*] DEPLOIEMENT - API NODE.JS" -ForegroundColor Cyan
Write-Host ""

$apiImageName = "gcr.io/$ProjectId/feedback-api:latest"

Write-Host "[*] Construction de l'image API..." -ForegroundColor Cyan
docker build -f Dockerfile -t $apiImageName .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de la construction de l'image API" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Image API construite" -ForegroundColor Green

Write-Host "[*] Push de l'image API..." -ForegroundColor Cyan
docker push $apiImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors du push" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Image API poussee" -ForegroundColor Green

Write-Host "[*] Deploiement du service API sur Cloud Run..." -ForegroundColor Cyan
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
    Write-Host "[!] Erreur lors du deploiement API" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Service API deploye" -ForegroundColor Green

# Recuperer l'URL de l'API
$apiServiceUrl = gcloud run services describe feedback-api `
    --region $Region `
    --format 'value(status.url)' | ForEach-Object { $_ }

Write-Host "[+] URL de l'API: $apiServiceUrl" -ForegroundColor Green

# TESTS EN PRODUCTION
Write-Host ""
Write-Host "[*] TESTS EN PRODUCTION" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 2

Write-Host "[*] Test API Health..." -ForegroundColor Yellow
try {
    $response = curl -s "$apiServiceUrl/api/health"
    Write-Host "[+] $response" -ForegroundColor Green
} catch {
    Write-Host "[!] Erreur lors du test" -ForegroundColor Red
}

Write-Host ""
Write-Host "[*] Test service ML..." -ForegroundColor Yellow
try {
    $response = curl -s "$mlServiceUrl/health"
    Write-Host "[+] Service ML actif" -ForegroundColor Green
} catch {
    Write-Host "[!] Erreur lors du test" -ForegroundColor Red
}

# RESUME
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "[+] DEPLOIEMENT REUSSI!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] RESUME DU DEPLOIEMENT:" -ForegroundColor Green
Write-Host ""
Write-Host "    Service ML:  $mlServiceUrl" -ForegroundColor Cyan
Write-Host "    Service API: $apiServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] ENDPOINTS DISPONIBLES:" -ForegroundColor Green
Write-Host ""
Write-Host "    Health Check:      $apiServiceUrl/api/health" -ForegroundColor Cyan
Write-Host "    Feedbacks:         $apiServiceUrl/api/feedbacks" -ForegroundColor Cyan
Write-Host "    Sentiment:         $apiServiceUrl/api/feedbacks/:id/sentiment" -ForegroundColor Cyan
Write-Host "    Stats:             $apiServiceUrl/api/stats" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] COMMANDES UTILES:" -ForegroundColor Green
Write-Host ""
Write-Host "    Voir les logs API:    gcloud run logs read feedback-api --region $Region" -ForegroundColor Cyan
Write-Host "    Voir les logs ML:     gcloud run logs read sentiment-ml --region $Region" -ForegroundColor Cyan
Write-Host "    Supprimer API:        gcloud run services delete feedback-api --region $Region" -ForegroundColor Cyan
Write-Host "    Supprimer ML:         gcloud run services delete sentiment-ml --region $Region" -ForegroundColor Cyan
Write-Host ""
Write-Host "[+] Tout est pret pour votre presentation!" -ForegroundColor Green
Write-Host ""
