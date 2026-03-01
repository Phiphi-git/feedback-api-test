# ============================================
# Script d'entraînement du modèle ML
# ============================================

Write-Host "[*] Entraînement du modèle de sentiment..." -ForegroundColor Cyan

# Vérifier que Python est installé
$pythonCheck = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Python n'est pas installé!" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Python détecté: $pythonCheck" -ForegroundColor Green

# Installer les dépendances si nécessaire
Write-Host "[*] Installation des dépendances Python..." -ForegroundColor Cyan
pip install -q -r requirements_ml.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de l'installation des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Dépendances installées" -ForegroundColor Green

# Lancer l'entraînement
Write-Host "[*] Entraînement du modèle en cours..." -ForegroundColor Cyan
python sentiment_analyzer.py


if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de l'entraînement du modèle" -ForegroundColor Red
    exit 1
}

# Vérifier que le modèle a été créé
if (Test-Path "sentiment_model.pkl") {
    Write-Host "[+] Modèle créé avec succès: sentiment_model.pkl" -ForegroundColor Green
    Write-Host "[+] Modèle prêt pour le déploiement!" -ForegroundColor Green
} else {
    Write-Host "[!] Le fichier sentiment_model.pkl n'a pas été créé" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Entraînement terminé avec succès!" -ForegroundColor Green

