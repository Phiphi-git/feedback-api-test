# Script de test complet pour l'API Feedback
# À exécuter après: node index.js

Write-Host "🧪 TEST DE L'API FEEDBACK" -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:3000"

# Fonction pour faire une requête et afficher le résultat
function Test-Endpoint {
    param(
        [string]$name,
        [string]$url
    )
    
    Write-Host "Test: $name" -ForegroundColor Yellow
    Write-Host "URL: $url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -ErrorAction Stop
        $data = $response.Content | ConvertFrom-Json
        
        Write-Host "✅ Succès (Code: $($response.StatusCode))" -ForegroundColor Green
        Write-Host "Réponse: $($data | ConvertTo-Json -Depth 2 | Select-Object -First 20)"
        Write-Host ""
        
        return $true
    } catch {
        Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Tests
Write-Host "1️⃣  Health Check" -ForegroundColor Blue
Test-Endpoint "Health" "$baseUrl/api/health"

Write-Host "2️⃣  Statistics" -ForegroundColor Blue
Test-Endpoint "Stats" "$baseUrl/api/stats"

Write-Host "3️⃣  Tous les feedbacks (page 1)" -ForegroundColor Blue
Test-Endpoint "Feedbacks Page 1" "$baseUrl/api/feedbacks?page=1&limit=10"

Write-Host "4️⃣  Feedback spécifique (ID 0)" -ForegroundColor Blue
Test-Endpoint "Feedback 0" "$baseUrl/api/feedbacks/0"

Write-Host "5️⃣  Recherche par mot-clé" -ForegroundColor Blue
Test-Endpoint "Recherche 'creative'" "$baseUrl/api/search/creative"

Write-Host "Résumé:" -ForegroundColor Cyan
Write-Host "Si tous les tests sont ✅, l'API fonctionne correctement!" -ForegroundColor Green
