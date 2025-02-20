# Install the Microsoft.Graph module if not installed

$RequiredModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Applications", "Microsoft.Graph.Reports")
foreach ($module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Force -AllowClobber
    }
}

# Import the required modules
foreach ($module in $RequiredModules) {
    Import-Module $module
}

Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All" 

# Check if you're authenticated by attempting to retrieve a user object
$context = Get-MgContext

# If you're authenticated, this should return user details without error
Write-Host "Authenticated as: $($context.Account)"

# Query the audit logs for app creation events:


$filter = "category eq 'ApplicationManagement' and activityDisplayName eq 'Add application'"
$appAudit = Get-MgAuditLogDirectoryAudit -Filter $filter -Top 1000
$appAudit | Select-Object @{N='AppName';E={$_.TargetResources[0].DisplayName}}, `
            ActivityDateTime, `
            @{N='UserPrincipalName';E={$_.InitiatedBy.User.UserPrincipalName}}, `
            @{N='DisplayName';E={$_.InitiatedBy.User.DisplayName}}

Disconnect-MgGraph
