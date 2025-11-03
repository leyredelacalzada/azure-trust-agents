# PowerShell script to retrieve Azure resource keys and create .env file
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup
)

Write-Host "Getting Azure resource information from resource group: $ResourceGroup"

# Check if user is logged in to Azure
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "User not signed in Azure. Please sign in using 'az login' command."
    az login --use-device-code
}

# Initialize .env file
$envFile = "../.env"
if (Test-Path $envFile) {
    Remove-Item $envFile
}

Write-Host "Discovering resources in resource group..."

# Get Storage Account
$storageAccountName = az storage account list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($storageAccountName) {
    Write-Host "Found Storage Account: $storageAccountName"
    $storageAccountKey = az storage account keys list --account-name $storageAccountName --resource-group $ResourceGroup --query "[0].value" -o tsv
    $storageConnectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccountKey;EndpointSuffix=core.windows.net"
    Add-Content $envFile "STORAGE_ACCOUNT_NAME=`"$storageAccountName`""
    Add-Content $envFile "STORAGE_ACCOUNT_KEY=`"$storageAccountKey`""
    Add-Content $envFile "STORAGE_CONNECTION_STRING=`"$storageConnectionString`""
}

# Get Cosmos DB
$cosmosAccountName = az cosmosdb list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($cosmosAccountName) {
    Write-Host "Found Cosmos DB: $cosmosAccountName"
    $cosmosEndpoint = az cosmosdb show --name $cosmosAccountName --resource-group $ResourceGroup --query "documentEndpoint" -o tsv
    $cosmosKey = az cosmosdb keys list --name $cosmosAccountName --resource-group $ResourceGroup --query "primaryMasterKey" -o tsv
    $cosmosConnectionString = "AccountEndpoint=$cosmosEndpoint;AccountKey=$cosmosKey;"
    Add-Content $envFile "COSMOS_ENDPOINT=`"$cosmosEndpoint`""
    Add-Content $envFile "COSMOS_KEY=`"$cosmosKey`""
    Add-Content $envFile "COSMOS_CONNECTION_STRING=`"$cosmosConnectionString`""
}

# Get AI Search Service
$searchServiceName = az search service list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($searchServiceName) {
    Write-Host "Found AI Search Service: $searchServiceName"
    $searchKey = az search admin-key show --resource-group $ResourceGroup --service-name $searchServiceName --query "primaryKey" -o tsv
    $searchEndpoint = "https://$searchServiceName.search.windows.net"
    Add-Content $envFile "SEARCH_SERVICE_NAME=`"$searchServiceName`""
    Add-Content $envFile "SEARCH_SERVICE_KEY=`"$searchKey`""
    Add-Content $envFile "SEARCH_SERVICE_ENDPOINT=`"$searchEndpoint`""
}

# Get AI Foundry Hub (Cognitive Services)
$aiFoundryHubName = az cognitiveservices account list --resource-group $ResourceGroup --query "[?kind=='AIServices'].name | [0]" -o tsv
if ($aiFoundryHubName) {
    Write-Host "Found AI Foundry Hub: $aiFoundryHubName"
    $aiFoundryEndpoint = az cognitiveservices account show --name $aiFoundryHubName --resource-group $ResourceGroup --query "properties.endpoint" -o tsv
    $aiFoundryKey = az cognitiveservices account keys list --name $aiFoundryHubName --resource-group $ResourceGroup --query "key1" -o tsv
    Add-Content $envFile "AI_FOUNDRY_HUB_NAME=`"$aiFoundryHubName`""
    Add-Content $envFile "AI_FOUNDRY_ENDPOINT=`"$aiFoundryEndpoint`""
    Add-Content $envFile "AI_FOUNDRY_KEY=`"$aiFoundryKey`""
    
    # For OpenAI compatibility
    $azureOpenAIEndpoint = "https://$aiFoundryHubName.openai.azure.com/"
    Add-Content $envFile "AZURE_OPENAI_SERVICE_NAME=`"$aiFoundryHubName`""
    Add-Content $envFile "AZURE_OPENAI_ENDPOINT=`"$azureOpenAIEndpoint`""
    Add-Content $envFile "AZURE_OPENAI_KEY=`"$aiFoundryKey`""
    Add-Content $envFile "AZURE_OPENAI_DEPLOYMENT_NAME=`"gpt-4o-mini`""
    Add-Content $envFile "MODEL_DEPLOYMENT_NAME=`"gpt-4o-mini`""
}

# Get Container Registry
$acrName = az acr list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($acrName) {
    Write-Host "Found Container Registry: $acrName"
    $acrUsername = az acr credential show --name $acrName --query "username" -o tsv
    $acrPassword = az acr credential show --name $acrName --query "passwords[0].value" -o tsv
    $acrLoginServer = az acr show --name $acrName --resource-group $ResourceGroup --query "loginServer" -o tsv
    Add-Content $envFile "ACR_NAME=`"$acrName`""
    Add-Content $envFile "ACR_USERNAME=`"$acrUsername`""
    Add-Content $envFile "ACR_PASSWORD=`"$acrPassword`""
    Add-Content $envFile "ACR_LOGIN_SERVER=`"$acrLoginServer`""
}

# Get Application Insights
$appInsightsName = az resource list --resource-group $ResourceGroup --resource-type "Microsoft.Insights/components" --query "[0].name" -o tsv
if ($appInsightsName) {
    Write-Host "Found Application Insights: $appInsightsName"
    $appInsightsKey = az resource show --resource-group $ResourceGroup --name $appInsightsName --resource-type "Microsoft.Insights/components" --query "properties.InstrumentationKey" -o tsv
    $appInsightsConnectionString = az resource show --resource-group $ResourceGroup --name $appInsightsName --resource-type "Microsoft.Insights/components" --query "properties.ConnectionString" -o tsv
    Add-Content $envFile "APPLICATION_INSIGHTS_INSTRUMENTATION_KEY=`"$appInsightsKey`""
    Add-Content $envFile "APPLICATION_INSIGHTS_CONNECTION_STRING=`"$appInsightsConnectionString`""
    Add-Content $envFile "APPLICATIONINSIGHTS_CONNECTION_STRING=`"$appInsightsConnectionString`""
}

# Get API Management
$apimName = az apim list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($apimName) {
    Write-Host "Found API Management: $apimName"
    $apimGatewayUrl = az apim show --name $apimName --resource-group $ResourceGroup --query "gatewayUrl" -o tsv
    Add-Content $envFile "APIM_NAME=`"$apimName`""
    Add-Content $envFile "APIM_GATEWAY_URL=`"$apimGatewayUrl`""
}

Write-Host ""
Write-Host "Environment file created successfully: $envFile"
Write-Host "Configuration Summary:"
Write-Host "- Storage Account: $storageAccountName"
Write-Host "- Cosmos DB: $cosmosAccountName"
Write-Host "- AI Search: $searchServiceName"
Write-Host "- AI Foundry Hub: $aiFoundryHubName"
Write-Host "- Container Registry: $acrName"
Write-Host "- Application Insights: $appInsightsName"
Write-Host "- API Management: $apimName"