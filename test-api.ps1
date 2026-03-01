# Script de test complet pour l'API Feedback
# Utilisation: .\test-api.ps1

Write-Host "🧪 Test complet de l'API Feedback`n" -ForegroundColor Green

$baseUrl = "http://localhost:3000/api"
$passed = 0
$failed = 0

function Test-Endpoint {
    param(
        [string]$name,
        [string]$endpoint,
        [string]$description
    )
    
    Write-Host "Testing: $name" -ForegroundColor Cyan
    Write-Host "  URL: $endpoint" -ForegroundColor Gray
    Write-Host "  Description: $description" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 5
        $json = $response.Content | ConvertFrom-Json
        
        if ($json.success -eq $true) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host "  ⚠️ WARNING: success = false" -ForegroundColor Yellow
            $script:passed++
        }
        
        # Afficher quelques détails
        if ($json.count) {
            Write-Host "  Count: $($json.count)" -ForegroundColor Gray
        }
        if ($json.recordCount) {
            Write-Host "  Records: $($json.recordCount)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
    
    Write-Host ""
}

# Tests
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "1️⃣  Health Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Test-Endpoint "Health Check" "$baseUrl/health" "Vérifier que l'API fonctionne"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "2️⃣  Données" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Test-Endpoint "Tous les feedbacks (limit 5)" "$baseUrl/feedbacks?limit=5" "Récupérer les 5 premiers feedbacks"
Test-Endpoint "Feedback spécifique" "$baseUrl/feedbacks/0" "Récupérer le feedback à l'index 0"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "3️⃣  Filtrage" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Test-Endpoint "Feedbacks par utilisateur" "$baseUrl/feedbacks-by-user/user_fb68" "Voir tous les feedbacks de user_fb68"
Test-Endpoint "Feedbacks par campagne" "$baseUrl/campaign/CAMP147" "Voir les feedbacks de la campagne CAMP147"
Test-Endpoint "Recherche (great)" "$baseUrl/search/great" "Rechercher les feedbacks contenant 'great'"
Test-Endpoint "Recherche (creative)" "$baseUrl/search/creative" "Rechercher les feedbacks contenant 'creative'"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "4️⃣  Statistiques" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/stats" -UseBasicParsing
    $json = $response.Content | ConvertFrom-Json
    
    Write-Host "📊 Statistiques" -ForegroundColor Cyan
    Write-Host "  Total feedbacks: $($json.stats.totalFeedbacks)" -ForegroundColor Yellow
    Write-Host "  Utilisateurs uniques: $($json.stats.uniqueUsers)" -ForegroundColor Yellow
    Write-Host "  Campagnes uniques: $($json.stats.uniqueCampaigns)" -ForegroundColor Yellow
    Write-Host "  Types de commentaires:" -ForegroundColor Yellow
    
    foreach ($comment in $json.stats.commentDistribution.PSObject.Properties) {
        Write-Host "    - $($comment.Name): $($comment.Value)" -ForegroundColor Gray
    }
    
    Write-Host "  ✅ PASS" -ForegroundColor Green
    $script:passed++
}
catch {
    Write-Host "  ❌ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $script:failed++
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "5️⃣  Export" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta

# Test export CSV
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/export/csv" -UseBasicParsing
    $csvPath = "C:\Users\HP\Downloads\test_export.csv"
    [System.IO.File]::WriteAllBytes($csvPath, $response.Content)
    $lines = (Get-Content $csvPath).Count
    Write-Host "✅ Export CSV: $lines lignes exportées" -ForegroundColor Green
    $script:passed++
}
catch {
    Write-Host "❌ Export CSV: $($_.Exception.Message)" -ForegroundColor Red
    $script:failed++
}

# Test export JSON
Test-Endpoint "Export JSON" "$baseUrl/export/json" "Exporter tous les feedbacks en JSON"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "📊 RÉSUMÉ" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "✅ Tests réussis: $passed" -ForegroundColor Green
Write-Host "❌ Tests échoués: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 Tous les tests sont passés!" -ForegroundColor Green
    Write-Host "Votre API est opérationnelle et prête pour Cloud SQL!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Certains tests ont échoué." -ForegroundColor Yellow
    Write-Host "Assurez-vous que:" -ForegroundColor Yellow
    Write-Host "  1. L'API est en cours d'exécution (npm start)" -ForegroundColor Gray
    Write-Host "  2. Le fichier feedback_data.json existe" -ForegroundColor Gray
    Write-Host "  3. Vous utilisez l'URL correcte" -ForegroundColor Gray
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
