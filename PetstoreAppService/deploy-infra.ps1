# =============================================================
# deploy-infra.ps1 — Create Azure Infrastructure (Run Once)
# =============================================================

# Stop immediately on any unhandled error
$ErrorActionPreference = "Stop"

# --- Configuration ---
$resourceGroup  = "petstore-rg"
$location       = "centralindia"
$appServicePlan = "petstore-plan"
$webAppName     = "petstore-api-app"
$runtime        = "DOTNETCORE:9.0"

function Write-Step($message) {
    Write-Host "`n>>> $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "    $message" -ForegroundColor Green
}

function Write-Fail($message) {
    Write-Host "    ERROR: $message" -ForegroundColor Red
}

# --- Step 1: Login to Azure ---
try {
    Write-Step "Step 1: Logging in to Azure..."
    az login
    if ($LASTEXITCODE -ne 0) { throw "Azure login failed." }
    Write-Success "Login successful."
}
catch {
    Write-Fail $_.Exception.Message
    Write-Host "Stopping script. Please login and retry." -ForegroundColor Yellow
    exit 1
}

# --- Step 2: Create Resource Group ---
try {
    Write-Step "Step 2: Creating resource group '$resourceGroup' in '$location'..."
    az group create --name $resourceGroup --location $location
    if ($LASTEXITCODE -ne 0) { throw "Failed to create resource group '$resourceGroup'." }
    Write-Success "Resource group created."
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}

# --- Step 3: Create App Service Plan ---
try {
    Write-Step "Step 3: Creating App Service Plan '$appServicePlan'..."
    az appservice plan create --name $appServicePlan --resource-group $resourceGroup --sku F1 --is-linux
    if ($LASTEXITCODE -ne 0) { throw "Failed to create App Service Plan '$appServicePlan'." }
    Write-Success "App Service Plan created."
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}

# --- Step 4: Create Web App ---
try {
    Write-Step "Step 4: Creating Web App '$webAppName'..."
    az webapp create `
      --name $webAppName `
      --resource-group $resourceGroup `
      --plan $appServicePlan `
      --runtime $runtime
    if ($LASTEXITCODE -ne 0) { throw "Failed to create Web App '$webAppName'." }
    Write-Success "Web App created."
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}

Write-Host ""
Write-Host "Infrastructure created successfully!" -ForegroundColor Green
Write-Host "Now run .\deploy-code.ps1 to deploy your application." -ForegroundColor Yellow