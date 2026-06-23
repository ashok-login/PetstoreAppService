# =============================================================
# deploy.ps1 — Redeploy PetstoreAppService to Azure App Service
# Run this script from the root of your PetstoreAppService folder
# Usage: .\deploy.ps1
# =============================================================

# --- Configuration — change these if needed ---
$resourceGroup = "petstore-rg"
$location      = "centralindia"       # Change to your region with available quota
$appServicePlan = "petstore-plan"
$webAppName    = "petstore-api-app"
$runtime       = "DOTNETCORE:9.0"
$publishFolder = "./publish"
$zipFile       = "./app.zip"

# --- Step 1: Login to Azure ---
Write-Host "Logging in to Azure..." -ForegroundColor Cyan
az login

# --- Step 2: Create Resource Group ---
Write-Host "Creating resource group '$resourceGroup' in '$location'..." -ForegroundColor Cyan
az group create --name $resourceGroup --location $location

# --- Step 3: Create App Service Plan ---
Write-Host "Creating App Service Plan '$appServicePlan'..." -ForegroundColor Cyan
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku F1 --is-linux

# --- Step 4: Create Web App ---
Write-Host "Creating Web App '$webAppName'..." -ForegroundColor Cyan
az webapp create `
  --name $webAppName `
  --resource-group $resourceGroup `
  --plan $appServicePlan `
  --runtime $runtime

# --- Step 5: Build and Publish ---
Write-Host "Building and publishing the project..." -ForegroundColor Cyan
dotnet publish --configuration Release --output $publishFolder

# --- Step 6: Zip the published output ---
Write-Host "Zipping published output..." -ForegroundColor Cyan
if (Test-Path $zipFile) { Remove-Item $zipFile }   # Delete old zip if exists
Compress-Archive -Path "$publishFolder/*" -DestinationPath $zipFile -Force

# --- Step 7: Deploy to Azure ---
Write-Host "Deploying to Azure App Service..." -ForegroundColor Cyan
az webapp deploy `
  --name $webAppName `
  --resource-group $resourceGroup `
  --src-path $zipFile `
  --type zip

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "App URL     : https://$webAppName.azurewebsites.net/api/v3/pets" -ForegroundColor Green
Write-Host "Scalar UI   : https://$webAppName.azurewebsites.net/scalar/v1" -ForegroundColor Green
Write-Host "OpenAPI JSON: https://$webAppName.azurewebsites.net/openapi/v1.json" -ForegroundColor Green