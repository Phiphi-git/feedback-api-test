# ============================================
# 🧪 Script de test local - Docker Compose
# ============================================

Write-Host "🚀 Démarrage des services locaux..." -ForegroundColor Cyan

# Vérifier que Docker est installé
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker n'est pas installé" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker détecté" -ForegroundColor Green

# Vérifier que le modèle ML existe
if (-not (Test-Path "sentiment_model.pkl")) {
    Write-Host "❌ sentiment_model.pkl non trouvé!" -ForegroundColor Red
    Write-Host "`nVeuillez d'abord entraîner le modèle:" -ForegroundColor Yellow
    Write-Host "  .\train-ml-model.ps1" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ Modèle ML trouvé" -ForegroundColor Green

# Construire les images
Write-Host "`n📦 Construction des images Docker..." -ForegroundColor Cyan
docker-compose build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la construction" -ForegroundColor Red
    exit 1
}

# Démarrer les services
Write-Host "`n⚙️  Démarrage des services..." -ForegroundColor Cyan
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du démarrage" -ForegroundColor Red
    exit 1
}

# Attendre que les services démarrent
Write-Host "`n⏳ Attente de démarrage des services..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Tests
Write-Host "`n🧪 TESTS LOCAL`n" -ForegroundColor Cyan

# Test 1: API Health
Write-Host "1️⃣  Test API Health Check..." -ForegroundColor Yellow
try {
    $response = curl -s http://localhost:3000/api/health | ConvertFrom-Json
    if ($response.success) {
        Write-Host "   ✅ API actif (Feedbacks: $($response.recordCount))" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  API non connectée à la BD" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Impossible de joindre l'API" -ForegroundColor Red
}

# Test 2: ML Health
Write-Host "`n2️⃣  Test ML Service Health Check..." -ForegroundColor Yellow
try {
    $response = curl -s http://localhost:8080/health | ConvertFrom-Json
    Write-Host "   ✅ Service ML actif" -ForegroundColor Green
    Write-Host "      - Status: $($response.status)" -ForegroundColor Cyan
    Write-Host "      - Version: $($response.version)" -ForegroundColor Cyan
} catch {
    Write-Host "   ❌ Impossible de joindre le service ML" -ForegroundColor Red
}

# Test 3: Analyser un sentiment
Write-Host "`n3️⃣  Test analyse de sentiment..." -ForegroundColor Yellow
try {
    $testText = "Excellent produit, très satisfait!"
    $response = curl -X POST http://localhost:8080/analyze `
        -H "Content-Type: application/json" `
        -d "{""text"": ""$testText""}" -s | ConvertFrom-Json
    
    Write-Host "   ✅ Analyse réussie" -ForegroundColor Green
    Write-Host "      - Sentiment: $($response.sentiment) " -ForegroundColor Cyan
    Write-Host "      - Confiance: $([math]::Round($response.confidence * 100, 2))%" -ForegroundColor Cyan
} catch {
    Write-Host "   ❌ Erreur lors de l'analyse" -ForegroundColor Red
}

# Test 4: Récupérer des feedbacks
Write-Host "`n4️⃣  Test récupération de feedbacks..." -ForegroundColor Yellow
try {
    $response = curl -s "http://localhost:3000/api/feedbacks?limit=1" | ConvertFrom-Json
    if ($response.success -and $response.data.length -gt 0) {
        $feedback = $response.data[0]
        Write-Host "   ✅ Feedback récupéré" -ForegroundColor Green
        Write-Host "      - ID: $($feedback.id)" -ForegroundColor Cyan
        Write-Host "      - Utilisateur: $($feedback.username)" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️  Aucun feedback trouvé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Erreur lors de la récupération" -ForegroundColor Red
}

# Test 5: Analyse de sentiment avec ID de feedback
Write-Host "`n5️⃣  Test analyse de sentiment pour feedback spécifique..." -ForegroundColor Yellow
try {
    $response = curl -s "http://localhost:3000/api/feedbacks/1/sentiment" | ConvertFrom-Json
    if ($response.success) {
        Write-Host "   ✅ Analyse réussie" -ForegroundColor Green
        Write-Host "      - Sentiment: $($response.sentiment.sentiment)" -ForegroundColor Cyan
        Write-Host "      - Confiance: $([math]::Round($response.sentiment.confidence * 100, 2))%" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️  $($response.error)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Erreur lors de l'analyse" -ForegroundColor Red
}

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "✨ SERVICES LOCAUX EN COURS D'EXÉCUTION" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "`n📍 Adresses:" -ForegroundColor Green
Write-Host "  API Node.js:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "  ML Python:    http://localhost:8080" -ForegroundColor Cyan
Write-Host "`n📚 Documentation:" -ForegroundColor Green
Write-Host "  - http://localhost:3000/api/health" -ForegroundColor Cyan
Write-Host "  - http://localhost:8080/health" -ForegroundColor Cyan
Write-Host "`n🛑 Pour arrêter les services:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor Cyan
Write-Host "`n"
