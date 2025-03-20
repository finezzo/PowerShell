# Connect to Microsoft Graph API
Connect-MgGraph -Scopes 'Policy.Read.All', 'User.Read.All', 'Group.Read.All', 'Application.Read.All'

# Pfad für den Export
$ExportPath = "C:\temp\CA"
$OutputFile = "$ExportPath\CAPoliciesSummary.txt"
$RoleMappingFile = "$ExportPath\RoleMapping.json"

##############################
# INFOS
# Bei Fehlern ggf. in Zeile 303 die Resolve-ApplicationEnforcedRestrictions auskommentieren
##############################

# Prüfen, ob der Benutzer Global Admin Rechte hat
# Ohne Global Admin muss das RollenID Matching mittels der JSON Datei geschehen
$UseAdminAPI = $false
$adminResponse = Read-Host "Haben Sie Global Admin Rechte? (Ja/Nein)"
if ($adminResponse -match "^j|J") {
    Connect-MgGraph -Scopes 'RoleManagement.Read.All' -ErrorAction SilentlyContinue
    $UseAdminAPI = $true
}

# Funktion zur Auflösung von Benutzer-IDs zu UPNs
function Resolve-UserID($userIds) {
    $resolvedUsers = @()
    foreach ($userId in $userIds) {
        if ($userId -eq "All") {
            $resolvedUsers += "All Users"
        } elseif ($userId -eq "GuestsOrExternalUsers") {
            $resolvedUsers += "Guests/External Users"
        } else {
            try {
                $user = Get-MgUser -UserId $userId -ErrorAction Stop
                $resolvedUsers += $user.UserPrincipalName
            }
            catch {
                $resolvedUsers += "$userId (Not Found)"
            }
        }
    }
    return ($resolvedUsers -join ", ")
}

# Funktion zur Auflösung von Gruppen-IDs zu Namen
function Resolve-GroupID($groupIds) {
    $resolvedGroups = @()
    foreach ($groupId in $groupIds) {
        try {
            $group = Get-MgGroup -GroupId $groupId -ErrorAction Stop
            $resolvedGroups += $group.DisplayName
        }
        catch {
            $resolvedGroups += "$groupId (Not Found)"
        }
    }
    return ($resolvedGroups -join ", ")
}

# Funktion zur Auflösung von Rollen-IDs zu Namen
function Resolve-RoleID($roleIds) {
    $resolvedRoles = @()
    if ($UseAdminAPI) {
        foreach ($roleId in $roleIds) {
            try {
                $role = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleId -ErrorAction Stop
                $resolvedRoles += $role.DisplayName
            }
            catch {
                $resolvedRoles += "$roleId (Not Found)"
            }
        }
    } else {
        $RoleMapping = @{ }
        if (Test-Path $RoleMappingFile) {
            $jsonData = Get-Content $RoleMappingFile | ConvertFrom-Json
            $RoleMapping = @{}
            $jsonData.PSObject.Properties | ForEach-Object { $RoleMapping[$_.Name] = $_.Value }
        }
        foreach ($roleId in $roleIds) {
            if ($RoleMapping.ContainsKey($roleId)) {
                $resolvedRoles += $RoleMapping[$roleId]
            } else {
                $resolvedRoles += "$roleId (Unknown)"
            }
        }
    }
    return ($resolvedRoles -join ", ")
}

# Funktion zur Auflösung von Application-IDs zu Namen
function Resolve-AppID($appIds) {
    $resolvedApps = @()
    foreach ($appId in $appIds) {
        try {
            $app = Get-MgApplicationByAppId -AppId $appId -ErrorAction Stop
            $resolvedApps += $app.DisplayName
        }
        catch {
            $resolvedApps += "$appId (Not Found)"
        }
    }
    return ($resolvedApps -join ", ")
}

# Funktion zur Auflösung von Standort-IDs zu Namen
function Resolve-LocationID($locationIds) {
    $resolvedLocations = @()
    foreach ($locationId in $locationIds) {
        try {
            $location = Get-MgIdentityConditionalAccessNamedLocation -NamedLocationId $locationId -ErrorAction Stop
            $resolvedLocations += $location.DisplayName
        }
        catch {
            $resolvedLocations += "$locationId (Not Found)"
        }
    }
    return ($resolvedLocations -join ", ")
}

# Funktion zur Auflösung von Application Enforced Restrictions
function Resolve-ApplicationEnforcedRestrictions($sessionControl) {
    if ($sessionControl -and $sessionControl.IsEnabled -ne $null) {
        if ($sessionControl.IsEnabled) {
            return "Enabled"
        }
        else {
            return "Disabled"
        }
    }
    return "Not Configured"
}

# Funktion zur Auflösung der Sign-In Frequency
function Resolve-SignInFrequency($signInControl) {
    if ($signInControl -and $signInControl.IsEnabled -eq $true) {
        $value = if ($signInControl.Value -ne $null) { $signInControl.Value } else { "Not Set" }
        $unit = if ($signInControl.Type -ne $null) { $signInControl.Type } else { "Unknown Unit" }
        
        return "Enabled ($value $unit)"
    }
    return "Not Configured"
}

# Funktion zur Auflösung aller Standort-ID Eigenschaften
function Get-NamedLocations {
$locations = Get-MgIdentityConditionalAccessNamedLocation -All | Select-Object Id, DisplayName, AdditionalProperties, CreatedDateTime, ModifiedDateTime

    # Check if any Named Locations are found
    if (-not $locations) {
        Write-Host "No Named Locations found in Microsoft Entra ID." -ForegroundColor Cyan
        return
    }

    # Retrieve all Conditional Access Policies
    $CAPolicy = Get-MgIdentityConditionalAccessPolicy -All | Select-Object Id, DisplayName, Conditions

    # Initialize a new list to store report data
    $Report = [System.Collections.Generic.List[Object]]::new()

    # Get all specific cultures and store them in $cultures
    $cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::SpecificCultures)

    # Create a dictionary for country code to full country name mapping
    $countryNames = @{}
    foreach ($culture in $cultures) {
        $region = [System.Globalization.RegionInfo]::new($culture.Name)
        if (-not $countryNames.ContainsKey($region.TwoLetterISORegionName)) {
            $countryNames[$region.TwoLetterISORegionName] = $region.EnglishName
        }
    }

    # Process the Named Locations
    foreach ($location in $locations) {

        # Extract the Location Name for Console Output
        $locationName = $location.DisplayName
        Write-Host "Verarbeite Benannten Standort - $locationName" -ForegroundColor Yellow

        # Determine the type of location (IP Ranges or Countries)
        $locationType = if ($location.AdditionalProperties.ipRanges) { "IP Ranges" } else { "Countries" }

        # Prepare list to hold country names
        $countries = [System.Collections.Generic.List[string]]::new()
        foreach ($countryCode in $location.AdditionalProperties.countriesAndRegions) {
            if ($countryNames.ContainsKey($countryCode)) {
                $countries.Add($countryNames[$countryCode])
            }
            else {
                $countries.Add($countryCode)
            }
        }

        # Translate country lookup method to a more descriptive string
        $countryLookupMethod = switch ($location.AdditionalProperties.countryLookupMethod) {
            "authenticatorAppGps" { "Determine location by GPS coordinates" }
            "clientIpAddress" { "Determine location by IP address (IPv4 and IPv6)" }
            default { $location.AdditionalProperties.countryLookupMethod }
        }

        # Check which policies include or exclude this Named Location
        $policies = [System.Collections.Generic.List[string]]::new()
        foreach ($Policy in $CAPolicy) {
            $InclLocation = $Policy.Conditions.Locations.IncludeLocations
            $ExclLocation = $Policy.Conditions.Locations.ExcludeLocations
            if ($InclLocation -contains $location.Id -or $ExclLocation -contains $location.Id) {
                $policies.Add($Policy.DisplayName)
            }
        }

        # Create a formatted string for the text file
        $ReportLine = @"
--------------------------------------------------------------------------------
Display Name:      $($location.DisplayName)
Location Type:     $locationType
Is Trusted:        $($location.AdditionalProperties.isTrusted)
IP Ranges:        $($location.AdditionalProperties.ipRanges.cidrAddress -join ',')
Countries:         $($countries -join ',')
Country Lookup:    $countryLookupMethod
Includes Unknown:  $($location.AdditionalProperties.includeUnknownCountriesAndRegions)
Created Date:      $($location.CreatedDate)
Modified Date:     $($location.ModifiedDateTime)
Policies:          $($policies -join ',')

"@
        $Report.Add($ReportLine)
    }

    # Sort the report by the DisplayName
    $SortedReport = $Report | Sort-Object

    # Ausgabe als Tabelle in der Konsole
    # $SortedReport | Out-Host

    # Überschrift definieren
    $header = "---------------------------------NAMED LOCATIONS--------------------------------`n"

    # Speichern in eine TXT-Datei
    $header | Add-Content -Path $OutputFile -Encoding utf8
    $SortedReport | Add-Content -Path $OutputFile -Encoding utf8
    Write-Host "Benannte Standortinformationen wurden an die Datei angehängt." -ForegroundColor Green
}

# Funktion zur Generierung der Rollenzuordnung
function Generate-RoleMapping {
    $roleDefinitions = Get-MgRoleManagementDirectoryRoleDefinition -All
    $roleHashTable = @{}
    foreach ($role in $roleDefinitions) {
        $roleHashTable[$role.Id] = $role.DisplayName
    }
    $roleHashTable | ConvertTo-Json | Set-Content $RoleMappingFile
    Write-Host "Rollen-Mapping gespeichert unter $RoleMappingFile"
}

# Falls der Benutzer Global Admin ist, kann die Datei generiert werden
if ($UseAdminAPI) {
    Write-Host "Generiere neues Rolemapping File"
    Generate-RoleMapping
}

Write-Host "Lade Policyinformationen" -ForegroundColor Green

try {
    $AllPolicies = Get-MgIdentityConditionalAccessPolicy -All

    if ($AllPolicies.Count -eq 0) {
        Write-Host "Es wurden keine CA Policies gefunden." -ForegroundColor Yellow
        return
    }

    $summaryContent = ""

    foreach ($Policy in $AllPolicies) {
        
        # Grundlegende Policy-Daten
        $displayName   = $Policy.DisplayName
        $state         = $Policy.State
        $createdDate   = $Policy.CreatedDateTime
        $modifiedDate  = $Policy.ModifiedDateTime
        $description   = $Policy.Description

        # Ausgeben welche Policy gerade verarbeitet wird
        Write-Host "Verarbeite Policy - $($displayName)" -ForegroundColor Yellow

        # User, Group & Role IDs auflösen
        $includeUsers  = if ($Policy.Conditions.Users.IncludeUsers) { Resolve-UserID $Policy.Conditions.Users.IncludeUsers } else { "" }
        $excludeUsers  = if ($Policy.Conditions.Users.ExcludeUsers) { Resolve-UserID $Policy.Conditions.Users.ExcludeUsers } else { "" }
        $includeGroups = if ($Policy.Conditions.Users.IncludeGroups) { Resolve-GroupID $Policy.Conditions.Users.IncludeGroups } else { "" }
        $excludeGroups = if ($Policy.Conditions.Users.ExcludeGroups) { Resolve-GroupID $Policy.Conditions.Users.ExcludeGroups } else { "" }
        $includeRoles  = if ($Policy.Conditions.Users.IncludeRoles) { Resolve-RoleID $Policy.Conditions.Users.IncludeRoles } else { "" }
        $excludeRoles  = if ($Policy.Conditions.Users.ExcludeRoles) { Resolve-RoleID $Policy.Conditions.Users.ExcludeRoles } else { "" }

        # Applications auflösen
        $includeApps   = if ($Policy.Conditions.Applications.IncludeApplications) { Resolve-AppID $Policy.Conditions.Applications.IncludeApplications } else { "" }
        $excludeApps   = if ($Policy.Conditions.Applications.ExcludeApplications) { Resolve-AppID $Policy.Conditions.Applications.ExcludeApplications } else { "" }

        # Weitere Felder
        $includePlatforms = if ($Policy.Conditions.Platforms.IncludePlatforms) { ($Policy.Conditions.Platforms.IncludePlatforms) -join ", " } else { "" }
        $excludePlatforms = if ($Policy.Conditions.Platforms.ExcludePlatforms) { ($Policy.Conditions.Platforms.ExcludePlatforms) -join ", " } else { "" }
        $includeLocations = if ($Policy.Conditions.Locations.IncludeLocations) { Resolve-LocationID $Policy.Conditions.Locations.IncludeLocations } else { "" }
        $excludeLocations = if ($Policy.Conditions.Locations.ExcludeLocations) { Resolve-LocationID $Policy.Conditions.Locations.ExcludeLocations } else { "" }
        $signInRiskLevels = if ($Policy.Conditions.SignInRiskLevels) { ($Policy.Conditions.SignInRiskLevels) -join ", " } else { "" }
        $clientAppTypes   = if ($Policy.Conditions.ClientAppTypes) { ($Policy.Conditions.ClientAppTypes) -join ", " } else { "" }
        $grantOperator    = if ($Policy.GrantControls.Operator) { $Policy.GrantControls.Operator } else { "" }
        $grantBuiltIn     = if ($Policy.GrantControls.BuiltInControls) { ($Policy.GrantControls.BuiltInControls) -join ", " } else { "" }
        $sessionAppEnforced = Resolve-ApplicationEnforcedRestrictions $Policy.SessionControls.ApplicationEnforcedRestrictions
        $sessionCloudAppSecurity = if ($Policy.SessionControls.CloudAppSecurityType) { $Policy.SessionControls.CloudAppSecurityType } else { "" }
        $sessionSignInFrequency = Resolve-SignInFrequency $Policy.SessionControls.SignInFrequency
        $sessionPersistentBrowser = if ($Policy.SessionControls.PersistentBrowserSession) { $Policy.SessionControls.PersistentBrowserSession } else { "" }

        # Authentication Flows hinzufügen
        $authenticationFlows = if ($Policy.Conditions.AuthenticationFlows) { ($Policy.Conditions.AuthenticationFlows) -join ", " } else { "" }

        # Formatierter Block für die aktuelle Policy
        $policySummary = @"
Policy Name: $displayName
State: $state
Created Date: $createdDate
Modified Date: $modifiedDate
Description: $description
Conditions:
  Include Applications: $includeApps
  Exclude Applications: $excludeApps
Users:
  Include Users: $includeUsers
  Exclude Users: $excludeUsers
Groups:
  Include Groups: $includeGroups
  Exclude Groups: $excludeGroups
Roles:
  Include Roles: $includeRoles
  Exclude Roles: $excludeRoles
Platforms:
  Include Platforms: $includePlatforms
  Exclude Platforms: $excludePlatforms
Locations:
  Include Locations: $includeLocations
  Exclude Locations: $excludeLocations
Sign-In Risk Levels: $signInRiskLevels
Client App Types: $clientAppTypes
Grant Controls:
  Operator: $grantOperator
  Built-in Controls: $grantBuiltIn
Session Controls:
  Application Enforced Restrictions: $sessionAppEnforced
  Cloud App Security Type: $sessionCloudAppSecurity
  Sign-In Frequency: $sessionSignInFrequency
  Persistent Browser Session: $sessionPersistentBrowser
Authentication Flows: $authenticationFlows

--------------------------------------------------------------------------------

"@

        $summaryContent += $policySummary
    }

    # Gesamten Inhalt in die Datei schreiben
    $summaryContent | Out-File -FilePath $OutputFile -Force
    Write-Host "Policyinformationen gelesen" -ForegroundColor Green

    # Named Locations über die Funktion hinzufügen
    Write-Host "Füge Benannte Standortinformationen hinzu" -ForegroundColor Green
    Get-NamedLocations

    Write-Host "Erfolgreich exportiert: $OutputFile" -ForegroundColor Green
}
catch {
    Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
}
Disconnect-Graph
