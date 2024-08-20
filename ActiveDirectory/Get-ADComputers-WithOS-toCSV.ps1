# Importieren des Active Directory-Moduls
Import-Module ActiveDirectory

# Abrufen aller Computer im Active Directory
$computers = Get-ADComputer -Filter * -Properties Name,OperatingSystem,OperatingSystemVersion,LastLogonDate

# Mapping-Tabelle für Windows-Versionen
$versionMapping = @{
    '10.0 (19045)' = 'Version 22H2 (OS build 19045) - Ende des Service: 14. Oktober 2025'
    '10.0 (19044)' = 'Version 21H2 (OS build 19044) - Ende des Service: 13. Juni 2023'
    '10.0 (19043)' = 'Version 21H1 (OS build 19043) - Serviceende: 13. Dezember 2022'
    '10.0 (19042)' = 'Version 20H2 (OS build 19042) - Serviceende: 9. Mai 2022'
    '10.0 (19041)' = 'Version 2004 (OS build 19041) - Serviceende: 14. Dezember 2021'
    '10.0 (18363)' = 'Version 1909 (OS build 18363) - Serviceende: 11. Mai 2021'
    '10.0 (18362)' = 'Version 1903 (OS build 18362) - Serviceende: 8. Dezember 2020'
    '10.0 (17763)' = 'Version 1809 (OS build 17763) - Serviceende: 11. Mai 2021'
    '10.0 (17134)' = 'Version 1803 (OS build 17134) - Serviceende: 12. November 2019'
    '10.0 (16299)' = 'Version 1709 (OS build 16299) - Serviceende: 9. April 2019'
    '10.0 (15063)' = 'Version 1703 (OS build 15063) - Serviceende: 8. Oktober 2018'
    '10.0 (14393)' = 'Version 1607 (OS build 14393) - Serviceende: 10. April 2018'
    '10.0 (10586)' = 'Version 1511 (OS build 10586) - Serviceende: 10. Oktober 2017'
    '10.0 (10240)' = 'Version 1507 (RTM) (OS build 10240) - Serviceende: 9. Mai 2017'
    '10.0 (22000)' = 'Windows 11 Version 21H2 (OS build 22000) - Ende des Service: 8. Oktober 2024'
    '10.0 (22621)' = 'Windows 11 Version 22H2 (OS build 22621) - Ende des Service: 14. Oktober 2025'
    '10.0 (22631)' = 'Windows 11 Version 23H2 (OS build 22631) - Ende des Service: Noch nicht festgelegt'
}

# Output-Array für die CSV
$outputArray = @()

# Durchlaufen der Computer und Anzeigen der Windows-Version und des letzten Anmeldedatums
foreach ($computer in $computers) {
    $computerName = $computer.Name
    $operatingSystem = $computer.OperatingSystem
    $operatingSystemVersion = $computer.OperatingSystemVersion
    $lastLogonDate = $computer.LastLogonDate

    # Überprüfen, ob die Version vorhanden und nicht NULL ist
    if ($operatingSystemVersion -ne $null -and $versionMapping.ContainsKey($operatingSystemVersion)) {
        $mappedVersion = $versionMapping[$operatingSystemVersion]
    } else {
        $mappedVersion = 'Unbekannte Version'
    }

    # Erstellen von Objekten für jede Zeile in der CSV
    $outputObject = [PSCustomObject]@{
        'Computer' = $computerName
        'Betriebssystem' = $operatingSystem
        'Betriebssystemversion' = $mappedVersion
        'Letztes Anmeldedatum' = $lastLogonDate
    }

    # Hinzufügen des Objekts zum Output-Array
    $outputArray += $outputObject
}

# Pfad zur CSV-Datei
$csvPath = "C:\ComputerOSVersions.csv"

# Exportieren des Output-Arrays in die CSV-Datei
$outputArray | Export-Csv -Path $csvPath -NoTypeInformation

# Meldung, dass der Export abgeschlossen ist
Write-Host "Der Export wurde in die CSV-Datei '$csvPath' abgeschlossen."
