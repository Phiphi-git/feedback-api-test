# Script d'entraînement du modèle ML
# Simple et sans caractères spéciaux

Write-Host "[*] Entraînement du modele de sentiment..." -ForegroundColor Cyan
Write-Host ""

# Verifier que Python est installe
$pythonCheck = python --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Python n'est pas installe!" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Python detecte: $pythonCheck" -ForegroundColor Green
Write-Host ""

# Installer les dependances
Write-Host "[*] Installation des dependances Python..." -ForegroundColor Cyan
pip install -q -r requirements_ml.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de l'installation des dependances" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Dependances installes" -ForegroundColor Green
Write-Host ""

# Lancer l'entrainement
Write-Host "[*] Entrainement du modele en cours..." -ForegroundColor Cyan
python sentiment_analyzer.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Erreur lors de l'entrainement du modele" -ForegroundColor Red
    exit 1
}

# Verifier que le modele a ete cree
if (Test-Path "sentiment_model.pkl") {
    Write-Host "[+] Modele cree avec succes: sentiment_model.pkl" -ForegroundColor Green
    Write-Host "[+] Modele pret pour le deploiement!" -ForegroundColor Green
} else {
    Write-Host "[!] Le fichier sentiment_model.pkl n'a pas ete cree" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[+] Entrainement termine avec succes!" -ForegroundColor Green
Write-Host ""
