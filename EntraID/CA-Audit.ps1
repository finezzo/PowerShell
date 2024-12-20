# Melde dich an
Connect-AzureAD
Connect-MsolService

# Abrufen aller Policies
$policies = Get-AzureADMSConditionalAccessPolicy

# Abrufen aller Benutzer, Gruppen und Rollen
$allUsers = Get-AzureADUser | Select-Object ObjectId, DisplayName, UserPrincipalName
$allGroups = Get-AzureADGroup | Select-Object ObjectId, DisplayName
$allRoles = Get-MsolRole | Select-Object ObjectId, Name

# Ausgabe-Datei
$outputFile = "ConditionalAccessPolicies_CompleteDetails_with_Groups.txt"

# Kopfzeile in die Datei schreiben
"Export von Conditional Access Policies - Vollständige Details" | Out-File -FilePath $outputFile
"=============================================================" | Out-File -FilePath $outputFile -Append

# Jede Policy einzeln verarbeiten
foreach ($policy in $policies) {
    # Header für die Policy
    "---------------------------------------------" | Out-File -FilePath $outputFile -Append
    "Policy Name: $($policy.DisplayName)" | Out-File -FilePath $outputFile -Append
    "State: $($policy.State)" | Out-File -FilePath $outputFile -Append

    # Bedingungen extrahieren
    $conditions = $policy.Conditions

    # Anwendungen
    $includeApplications = if ($conditions.Applications.IncludeApplications) { $conditions.Applications.IncludeApplications -join ', ' } else { "Keine Angaben" }
    $excludeApplications = if ($conditions.Applications.ExcludeApplications) { $conditions.Applications.ExcludeApplications -join ', ' } else { "Keine Angaben" }
    "  Include Applications: $includeApplications" | Out-File -FilePath $outputFile -Append
    "  Exclude Applications: $excludeApplications" | Out-File -FilePath $outputFile -Append

    # Benutzer
    $includeUsers = @()
    $excludeUsers = @()
    if ($conditions.Users.IncludeUsers) {
        foreach ($userId in $conditions.Users.IncludeUsers) {
            $resolvedUser = $allUsers | Where-Object { $_.ObjectId -eq $userId }
            $includeUsers += if ($resolvedUser) { "$($resolvedUser.DisplayName) ($($resolvedUser.UserPrincipalName))" } else { "$userId (Nicht aufgelöst)" }
        }
    } else {
        $includeUsers = "Keine Angaben"
    }
    if ($conditions.Users.ExcludeUsers) {
        foreach ($userId in $conditions.Users.ExcludeUsers) {
            $resolvedUser = $allUsers | Where-Object { $_.ObjectId -eq $userId }
            $excludeUsers += if ($resolvedUser) { "$($resolvedUser.DisplayName) ($($resolvedUser.UserPrincipalName))" } else { "$userId (Nicht aufgelöst)" }
        }
    } else {
        $excludeUsers = "Keine Angaben"
    }
    "  Include Users: $($includeUsers -join ', ')" | Out-File -FilePath $outputFile -Append
    "  Exclude Users: $($excludeUsers -join ', ')" | Out-File -FilePath $outputFile -Append

    # Gruppen
    $includeGroups = @()
    $excludeGroups = @()
    if ($conditions.Users.IncludeGroups) {
        foreach ($groupId in $conditions.Users.IncludeGroups) {
            $resolvedGroup = $allGroups | Where-Object { $_.ObjectId -eq $groupId }
            $includeGroups += if ($resolvedGroup) { "$($resolvedGroup.DisplayName)" } else { "$groupId (Nicht aufgelöst)" }
        }
    } else {
        $includeGroups = "Keine Angaben"
    }
    if ($conditions.Users.ExcludeGroups) {
        foreach ($groupId in $conditions.Users.ExcludeGroups) {
            $resolvedGroup = $allGroups | Where-Object { $_.ObjectId -eq $groupId }
            $excludeGroups += if ($resolvedGroup) { "$($resolvedGroup.DisplayName)" } else { "$groupId (Nicht aufgelöst)" }
        }
    } else {
        $excludeGroups = "Keine Angaben"
    }
    "  Include Groups: $($includeGroups -join ', ')" | Out-File -FilePath $outputFile -Append
    "  Exclude Groups: $($excludeGroups -join ', ')" | Out-File -FilePath $outputFile -Append

    # Rollen
    $includeRoles = @()
    $excludeRoles = @()
    if ($conditions.Users.IncludeRoles) {
        foreach ($roleId in $conditions.Users.IncludeRoles) {
            $resolvedRole = $allRoles | Where-Object { $_.ObjectId -eq $roleId }
            $includeRoles += if ($resolvedRole) { "$($resolvedRole.Name)" } else { "$roleId (Nicht aufgelöst)" }
        }
    } else {
        $includeRoles = "Keine Angaben"
    }
    if ($conditions.Users.ExcludeRoles) {
        foreach ($roleId in $conditions.Users.ExcludeRoles) {
            $resolvedRole = $allRoles | Where-Object { $_.ObjectId -eq $roleId }
            $excludeRoles += if ($resolvedRole) { "$($resolvedRole.Name)" } else { "$roleId (Nicht aufgelöst)" }
        }
    } else {
        $excludeRoles = "Keine Angaben"
    }
    "  Include Roles: $($includeRoles -join ', ')" | Out-File -FilePath $outputFile -Append
    "  Exclude Roles: $($excludeRoles -join ', ')" | Out-File -FilePath $outputFile -Append

    # Plattformen
    $platforms = if ($conditions.Platforms.IncludePlatforms) { $conditions.Platforms.IncludePlatforms -join ', ' } else { "Keine Angaben" }
    "  Platforms: $platforms" | Out-File -FilePath $outputFile -Append

    # Locations
    $locations = if ($conditions.Locations.IncludeLocations) { $conditions.Locations.IncludeLocations -join ', ' } else { "Keine Angaben" }
    "  Locations: $locations" | Out-File -FilePath $outputFile -Append

    # Kontrollmaßnahmen (Grant Controls)
    $grantControls = $policy.GrantControls
    "Grant Controls:" | Out-File -FilePath $outputFile -Append
    "  Operator: $($grantControls._Operator)" | Out-File -FilePath $outputFile -Append
    "  Built-in Controls: $($grantControls.BuiltInControls -join ', ')" | Out-File -FilePath $outputFile -Append
    "  Custom Authentication Factors: $(if ($grantControls.CustomAuthenticationFactors.Count -eq 0) { 'Keine' } else { $grantControls.CustomAuthenticationFactors -join ', ' })" | Out-File -FilePath $outputFile -Append
    "  Terms of Use: $(if ($grantControls.TermsOfUse.Count -eq 0) { 'Keine' } else { $grantControls.TermsOfUse -join ', ' })" | Out-File -FilePath $outputFile -Append

    # Session Controls
    $sessionControls = $policy.SessionControls
    "Session Controls:" | Out-File -FilePath $outputFile -Append
    if ($sessionControls) {
        "  Application Enforced Restrictions: $($sessionControls.ApplicationEnforcedRestrictions)" | Out-File -FilePath $outputFile -Append
        "  Persistent Browser Session: $($sessionControls.PersistentBrowser)" | Out-File -FilePath $outputFile -Append
    } else {
        "  Keine Angaben" | Out-File -FilePath $outputFile -Append
    }
}

# Hinweis für den Benutzer
Write-Host "Export abgeschlossen! Die Details sind in der Datei $outputFile gespeichert."
