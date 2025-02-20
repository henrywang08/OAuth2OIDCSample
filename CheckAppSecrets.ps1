# Install the Microsoft.Graph module if not installed

$RequiredModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Applications")
foreach ($module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Force -AllowClobber
    }
}

# Import the required modules
foreach ($module in $RequiredModules) {
    Import-Module $module
}

# Authenticate to Microsoft Graph

    Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All" 

# Check if you're authenticated by attempting to retrieve a user object
$context = Get-MgContext

# If you're authenticated, this should return user details without error
Write-Host "Authenticated as: $($context.Account)"



# Get all registered applications
$apps = Get-MgApplication 

# Initialize an empty array to store output
$output = @()

foreach ($app in $apps) {
    # Get App owner
    Get-MgApplicationOwner -ApplicationId $($app.Id) | Select-Object -ExpandProperty AdditionalProperties | Select-Object displayName, userPrincipalName
    
    
    # Get secrets for the current app
    if ($app.PasswordCredentials.count -gt 0)
    {
        $secrets = $app.PasswordCredentials
    } else {
        continue
    }
    

    foreach ($secret in $secrets) {
        # Check if the secret is expired
        $secretExpiration = $secret.EndDateTime
        $currentDate = Get-Date

        # Prepare the output with expiration status
        $status = if ($secretExpiration -lt $currentDate) { "Expired" } else { "Active" }
        
        # Create an object to hold the output data
        $appInfo = [PSCustomObject]@{
            AppName          = $app.DisplayName
            AppId            = $app.AppId
            SecretId         = $secret.Id
            SecretExpiration = $secretExpiration
            Status           = $status
        }

        # Add to output array
        $output += $appInfo
    }
}

# Display the results with colors
foreach ($entry in $output) {
    if ($entry.Status -eq "Expired") {
        Write-Host "$($entry.AppName) - Secret Expired - Expired" -ForegroundColor Red
    } else {
        Write-Host "$($entry.AppName) - Secret Active - $($entry.SecretExpiration)" -ForegroundColor Green
    }
}

Disconnect-MgGraph
