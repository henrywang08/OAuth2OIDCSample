# Configuration
$tenantId = "<Tenant ID>"                 # Azure AD Tenant ID
$clientId = "<WebApp-GroupClaims>"                 # Client ID 
$clientSecret = "<App secret>"          # Your Application Client Secret
$redirectUri = "https://localhost:44321/signin-oidc"           # Must match the redirect URI configured in Azure AD
$scope = "openid profile email offline_access https://graph.microsoft.com/.default"  # Hybrid flow scopes
$authorizeUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize"
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Step 1: Generate the Authorization URL
$authUrl = "$($authorizeUrl)?client_id=$clientId&response_type=id_token+code&redirect_uri=$redirectUri&response_mode=fragment&scope=$scope&state=12345&nonce=67890"
Write-Output "Go to the following URL in your browser and sign in to grant permissions:"
Write-Output $authUrl

# Step 2: Prompt the user to paste the full redirect URL after signing in
$redirectResponse = Read-Host "Paste the full URL after authentication (including id_token and code)"

# Step 3: Extract id_token and authorization code from the URL
$redirectParams = $redirectResponse -split "&"

$idToken = ($redirectParams -match "id_token=") -replace "id_token=", ""

if ($redirectResponse -match "code=([^&]+)") {
    $authCode = $matches[1]
} else {
    Write-Output "Error: Authorization code could not be extracted. Check the URL format."
    exit
}

# Output ID Token, but it will NOT be the full ID Toen content, as PowerShell truncate the content 
# during "paste the full redirect URL after signing in." Use extract.html to extract Id Token and Auth code. 

Write-Output "`nID Token:"
Write-Output $idToken

# Step 4: Exchange Authorization Code for Access Token
$body = @{
    grant_type    = "authorization_code"
    client_id     = $clientId
    redirect_uri  = $redirectUri
    code          = $authCode
    scope         = $scope
    client_secret = $clientSecret
}

$response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Extract Access Token and Refresh Token
$accessToken = $response.access_token
$refreshToken = $response.refresh_token

# Output Tokens
Write-Output "`nAccess Token:"
Write-Output $accessToken
Write-Output "`nRefresh Token:"
Write-Output $refreshToken

# Step 5: Use Access Token to Call Microsoft Graph API
$graphApiUrl = "https://graph.microsoft.com/v1.0/me"
$headers = @{ Authorization = "Bearer $accessToken" }

$userResponse = Invoke-RestMethod -Uri $graphApiUrl -Headers $headers -Method Get

Write-Output "`nUser Profile from Microsoft Graph API:"
Write-Output $userResponse | ConvertTo-Json -Depth 2
