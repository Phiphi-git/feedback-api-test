# Script pour preparer les fichiers a envoyer pour Cloud SQL
# Usage: .\prepare-for-cloudsql.ps1

Write-Host "Preparation des fichiers pour Cloud SQL" -ForegroundColor Green

$projectDir = "C:\Users\HP\Downloads\feedback-api-test"
$releaseDir = "C:\Users\HP\Downloads\feedback-api-cloudsql"

Write-Host "Creation du dossier de release..." -ForegroundColor Cyan

if (Test-Path $releaseDir) {
    Write-Host "  Le dossier existe deja, suppression..." -ForegroundColor Yellow
    Remove-Item $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir | Out-Null
Write-Host "  Dossier cree: $releaseDir`n" -ForegroundColor Green

# Fichiers a copier
$filesToCopy = @(
    "package.json",
    "package-lock.json",
    "index-cloud-sql-template.js",
    "README_CLOUD_SQL.md",
    "feedback_data.csv"
)

Write-Host "Copie des fichiers essentiels...`n" -ForegroundColor Cyan

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $projectDir $file
    $destPath = Join-Path $releaseDir $file
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath
        $fileSize = (Get-Item $destPath).Length / 1024
        Write-Host "  OK: $file ($fileSize KB)" -ForegroundColor Green
    } else {
        Write-Host "  MANQUE: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Creation des fichiers de configuration...`n" -ForegroundColor Cyan

# Fichier .env.example
$envPath = Join-Path $releaseDir ".env.example"
$envContent = "DB_HOST=votre_ip_cloud_sql`nDB_USER=root`nDB_PASSWORD=votre_password`nDB_NAME=feedback_db`nPORT=3000"
$envContent | Out-File $envPath -Encoding UTF8 -NoNewline
Write-Host "  OK: .env.example cree" -ForegroundColor Green

# Afficher le resume
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "PREPARATION TERMINEEE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta

Write-Host "`nFichiers prepares dans:" -ForegroundColor Cyan
Write-Host "   $releaseDir`n" -ForegroundColor Yellow

Write-Host "Fichiers inclus:" -ForegroundColor Cyan
Get-ChildItem $releaseDir -File | ForEach-Object {
    Write-Host "   OK: $($_.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Cyan
Write-Host "   1. Compresser: Compress-Archive -Path $releaseDir -DestinationPath api.zip" -ForegroundColor Gray
Write-Host "   2. Envoyer a votre ami" -ForegroundColor Gray
Write-Host "   3. L'ami suit les etapes README_CLOUD_SQL.md" -ForegroundColor Gray

Write-Host ""
