# Configuration rapide du projet pour le professeur (Windows)

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "🚀 Feedback API - Configuration" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Étape 1: Installer les dépendances
Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dépendances installées" -ForegroundColor Green
Write-Host ""

# Étape 2: Vérifier la structure
Write-Host "📋 Vérification des fichiers..." -ForegroundColor Yellow

if (-not (Test-Path "feedback_data.csv")) {
    Write-Host "⚠️  feedback_data.csv manquant" -ForegroundColor Yellow
    Write-Host "   Les données doivent être fournies (CSV ou API)" -ForegroundColor Gray
}

if (-not (Test-Path ".env")) {
    Write-Host "📝 Création du fichier .env..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✅ .env créé (modifiez-le selon vos besoins)" -ForegroundColor Green
}
Write-Host ""

# Étape 3: Information de démarrage
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "✨ Configuration terminée!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📖 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Lire GUIDE_PROFESSEUR.md" -ForegroundColor White
Write-Host "2. Adapter feedback_data.csv ou configurer FEEDBACK_API_URL" -ForegroundColor White
Write-Host "3. Lancer: node index.js" -ForegroundColor White
Write-Host "4. Accéder à: http://localhost:3000/api/health" -ForegroundColor White
Write-Host ""
