Import-Module Microsoft.Graph.Authentication

Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All" -ContextScope Process

# Query the audit logs for app creation events:


$filter = "category eq 'ApplicationManagement' and activityDisplayName eq 'Add application'"
$appAudit = Get-MgAuditLogDirectoryAudit -Filter $filter -Top 1000
$appAudit | Select-Object @{N='AppName';E={$_.TargetResources[0].DisplayName}}, `
            ActivityDateTime, `
            @{N='UserPrincipalName';E={$_.InitiatedBy.User.UserPrincipalName}}, `
            @{N='DisplayName';E={$_.InitiatedBy.User.DisplayName}}

