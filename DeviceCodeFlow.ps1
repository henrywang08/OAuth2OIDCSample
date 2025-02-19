# Azure AD App Configuration
$ClientId = "<MSAL Verification App ID>"
# $TenantId = "<Tenant ID>"

# For multi-tenant app, TenantId is 'common'. 
$TenantId = 'common'
$Authority = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0"


# $Scopes = "https://graph.microsoft.com/.default offline_access"  # To get Access and refresh token
$Scopes = "https://graph.microsoft.com/.default offline_access openid profile email" # To get Access, refresh, and Id token

# Step 1: Request a device code
$DeviceCodeEndpoint = "$Authority/devicecode"
$DeviceCodeResponse = Invoke-RestMethod -Uri $DeviceCodeEndpoint -Method POST -ContentType "application/x-www-form-urlencoded" -Body @{
    client_id = $ClientId
    scope     = $Scopes
}

# Display the user code and verification URL
Write-Output "To authenticate, open the following URL in a browser:"
Write-Output $DeviceCodeResponse.verification_uri
Write-Output "Enter the code: $($DeviceCodeResponse.user_code)"
Write-Output "This code expires in $($DeviceCodeResponse.expires_in) seconds."

# Step 2: Poll the token endpoint until the user authenticates
$TokenEndpoint = "$Authority/token"
$AuthToken = $null
while ($null -eq $AuthToken) {
    try {
        $AuthToken = Invoke-RestMethod -Uri $TokenEndpoint -Method POST -ContentType "application/x-www-form-urlencoded" -Body @{
            client_id  = $ClientId
            scope      = $Scopes
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            device_code = $DeviceCodeResponse.device_code
        }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            # Wait for the user to authenticate
            Start-Sleep -Seconds $DeviceCodeResponse.interval
        } else {
            Write-Output "An error occurred: $($_.Exception.Message)"
            break
        }
    }
}

# Step 3: Output the tokens
if ($AuthToken -ne $null) {
    Write-Output "Access Token:"
    Write-Output $AuthToken.access_token

    if ($AuthToken.refresh_token -ne $null) {
        Write-Output "Refresh Token:"
        Write-Output $AuthToken.refresh_token
    }
       
        if ($AuthToken.id_token -ne $null) {
            Write-Output "Id Token:"
            Write-Output $AuthToken.id_token
        }
} else {
    Write-Output "Authentication was not completed."
}
