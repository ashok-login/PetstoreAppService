# =============================================================
# deploy-code.ps1 — Deploy Application Code Only
# Run this script from the root of your PetstoreAppService folder
# Usage: .\deploy-code.ps1
# Prerequisite: deploy-infra.ps1 must have been run at least once
# =============================================================

# Stop immediately on any unhandled error
$ErrorActionPreference = "Stop"

# --- Configuration ---
$resourceGroup = "petstore-rg"
$webAppName    = "petstore-api-app"
$publishFolder = "./publish"
$zipFile       = "./app.zip"

function Write-Step($message) {
    Write-Host "`n>>> $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "    $message" -ForegroundColor Green
}

function Write-Fail($message) {
    Write-Host "    ERROR: $message" -ForegroundColor Red
}

# --- Step 1: Build and Publish ---
try {
    Write-Step "Step 1: Building and publishing the project..."
    dotnet publish --configuration Release --output $publishFolder
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed. Check build errors above." }
    Write-Success "Build and publish successful."
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}

# --- Step 2: Zip the published output ---
try {
    Write-Step "Step 2: Zipping published output..."

    if (-not (Test-Path $publishFolder)) {
        throw "Publish folder '$publishFolder' not found. Ensure Step 1 completed successfully."
    }

    if (Test-Path $zipFile) {
        Remove-Item $zipFile
        Write-Success "Old zip file removed."
    }

    Compress-Archive -Path "$publishFolder/*" -DestinationPath $zipFile -Force
    Write-Success "Zip created at '$zipFile'."
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}

# --- Step 3: Deploy to Azure ---
try {
    Write-Step "Step 3: Deploying to Azure App Service..."
    az webapp deploy `
      --name $webAppName `
      --resource-group $resourceGroup `
      --src-path $zipFile `
      --type zip
    if ($LASTEXITCODE -ne 0) { throw "Deployment to Azure App Service '$webAppName' failed." }
    Write-Success "Deployment successful."
}
catch {
    Write-Fail $_.Exception.Message
    Write-Host "    Tip: Ensure deploy-infra.ps1 was run at least once and the Web App exists." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "App URL     : https://$webAppName.azurewebsites.net/api/v3/pets" -ForegroundColor Green
Write-Host "Scalar UI   : https://$webAppName.azurewebsites.net/scalar/v1" -ForegroundColor Green
Write-Host "OpenAPI JSON: https://$webAppName.azurewebsites.net/openapi/v1.json" -ForegroundColor Green