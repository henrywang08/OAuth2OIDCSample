# Configuration
$tenantId = "0b2d3daf-def5-44ef-a5df-de3f83f6be03" # "your-tenant-id"
$clientId = "af1b0124-a1b1-455a-80f2-86246d914e00"  # "your-client-id", Client app is "My OAuth Hybrid Flow"
$redirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$scope = "openid profile email offline_access https://graph.microsoft.com/.default"
$authorizeUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize"
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Step 1: Generate the Authorization URL
$authUrl = "$($authorizeUrl)?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&response_mode=query&scope=$scope&state=12345"
Write-Output "Go to the following URL in your browser and sign in:"
Write-Output $authUrl

# Step 2: Prompt user to paste full redirect URL after login
$redirectResponse = Read-Host "Paste the full redirected URL after authentication"

# Step 3: Extract the Authorization Code
if ($redirectResponse -match "code=([^&]+)") {
    $authCode = $matches[1]
    $authCodeEncoded = [System.Web.HttpUtility]::UrlEncode($authCode) # Ensure URL encoding
} else {
    Write-Output "Error: Authorization code could not be extracted. Check the URL format."
    exit
}


# Step 4: Exchange Authorization Code for Access & ID Token
$body = @{
    grant_type    = "authorization_code"
    client_id     = $clientId
    redirect_uri  = $redirectUri
    code          = $authCodeEncoded
    scope         = $scope  # Only resource scope
    
}

$body

$response = Invoke-RestMethod -Uri $($tokenEndpoint) -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Extract ID Token and Access Token
$idToken = $response.id_token
$accessToken = $response.access_token
$refreshToken = $response.refresh_token

Write-Output "`nID Token:"
Write-Output $idToken
Write-Output "`nAccess Token:"
Write-Output $accessToken
Write-Output "`nRefresh Token:"
Write-Output $refreshToken

# Step 5: Use Access Token to get user information from Microsoft Graph
$graphApiUrl = "https://graph.microsoft.com/v1.0/me"
$userInfo = Invoke-RestMethod -Uri $graphApiUrl -Headers @{Authorization = "Bearer $accessToken"} -Method Get

Write-Output "`nUser Information:"
Write-Output $userInfo