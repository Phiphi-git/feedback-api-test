# Script de test local - Docker Compose
# Version simple sans caracteres speciaux

Write-Host "[*] Demarrage des services locaux..." -ForegroundColor Cyan
Write-Host ""

# Verifier que Docker est installe
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Docker n'est pas installe" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Docker detecte" -ForegroundColor Green

# Verifier que le modele ML existe
if (-not (Test-Path "sentiment_model.pkl")) {
    Write-Host "[!] sentiment_model.pkl non trouve!" -ForegroundColor Red
    Write-Host "[*] Veuillez d'abord entrainer le modele:" -ForegroundColor Yellow
    Write-Host "    .\train-ml-model-simple.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host "[+] Modele ML trouve" -ForegroundColor Green
Write-Host ""

# Construire les images
Write-Host "[*] Construction des images Docker..." -ForegroundColor Cyan
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de la construction" -ForegroundColor Red
    exit 1
}

# Demarrer les services
Write-Host ""
Write-Host "[*] Demarrage des services..." -ForegroundColor Cyan
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors du demarrage" -ForegroundColor Red
    exit 1
}

# Attendre que les services demarrent
Write-Host "[*] Attente de demarrage des services..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "[*] TESTS LOCAL" -ForegroundColor Cyan
Write-Host ""

# Test 1: API Health
Write-Host "[1] Test API Health Check..." -ForegroundColor Yellow
try {
    $response = curl -s http://localhost:3000/api/health | ConvertFrom-Json
    if ($response.success) {
        Write-Host "    [+] API actif (Feedbacks: $($response.recordCount))" -ForegroundColor Green
    } else {
        Write-Host "    [!] API non connectee a la BD" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [!] Impossible de joindre l'API" -ForegroundColor Red
}

# Test 2: ML Health
Write-Host ""
Write-Host "[2] Test ML Service Health Check..." -ForegroundColor Yellow
try {
    $response = curl -s http://localhost:8080/health | ConvertFrom-Json
    Write-Host "    [+] Service ML actif" -ForegroundColor Green
    Write-Host "        Status: $($response.status)" -ForegroundColor Cyan
    Write-Host "        Version: $($response.version)" -ForegroundColor Cyan
} catch {
    Write-Host "    [!] Impossible de joindre le service ML" -ForegroundColor Red
}

# Test 3: Analyser un sentiment
Write-Host ""
Write-Host "[3] Test analyse de sentiment..." -ForegroundColor Yellow
try {
    $testText = "Excellent produit, tres satisfait!"
    $response = curl -X POST http://localhost:8080/analyze `
        -H "Content-Type: application/json" `
        -d "{""text"": ""$testText""}" -s | ConvertFrom-Json
    
    Write-Host "    [+] Analyse reussie" -ForegroundColor Green
    Write-Host "        Sentiment: $($response.sentiment)" -ForegroundColor Cyan
    Write-Host "        Confiance: $([math]::Round($response.confidence * 100, 2))%" -ForegroundColor Cyan
} catch {
    Write-Host "    [!] Erreur lors de l'analyse" -ForegroundColor Red
}

# Test 4: Recuperer des feedbacks
Write-Host ""
Write-Host "[4] Test recuperation de feedbacks..." -ForegroundColor Yellow
try {
    $response = curl -s "http://localhost:3000/api/feedbacks?limit=1" | ConvertFrom-Json
    if ($response.success -and $response.data.length -gt 0) {
        $feedback = $response.data[0]
        Write-Host "    [+] Feedback recupere" -ForegroundColor Green
        Write-Host "        ID: $($feedback.id)" -ForegroundColor Cyan
        Write-Host "        Utilisateur: $($feedback.username)" -ForegroundColor Cyan
    } else {
        Write-Host "    [!] Aucun feedback trouve" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [!] Erreur lors de la recuperation" -ForegroundColor Red
}

# Test 5: Analyse de sentiment avec ID de feedback
Write-Host ""
Write-Host "[5] Test analyse de sentiment pour feedback specifique..." -ForegroundColor Yellow
try {
    $response = curl -s "http://localhost:3000/api/feedbacks/1/sentiment" | ConvertFrom-Json
    if ($response.success) {
        Write-Host "    [+] Analyse reussie" -ForegroundColor Green
        Write-Host "        Sentiment: $($response.sentiment.sentiment)" -ForegroundColor Cyan
        Write-Host "        Confiance: $([math]::Round($response.sentiment.confidence * 100, 2))%" -ForegroundColor Cyan
    } else {
        Write-Host "    [!] $($response.error)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [!] Erreur lors de l'analyse" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "[+] SERVICES LOCAUX EN COURS D'EXECUTION" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Adresses:" -ForegroundColor Green
Write-Host "    API Node.js:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "    ML Python:    http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Pour arreter les services:" -ForegroundColor Yellow
Write-Host "    docker-compose down" -ForegroundColor Cyan
Write-Host ""
