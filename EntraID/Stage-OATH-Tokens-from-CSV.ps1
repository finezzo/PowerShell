# User must have at least Authentication Policy Administrator Role and Global Reader
# Make sure you have already installed the Microsoft Graph module
# Install-Module Microsoft.Graph -Scope AllUsers -Repository PSGallery -Force
# Or visit https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0

# Import-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.SignIns

# Authenticate with Microsoft Graph with the required scopes
Connect-MgGraph -Scopes "Directory.Read.All", "User.Read.All", "User.ReadWrite.All", "Policy.ReadWrite.AuthenticationMethod" -NoWelcome

# Path to CSV-File
$csvPath = "C:\Path\To\CSV\token.csv"

# Reading CSV-File
$tokens = Import-Csv -Path $csvPath

# Register tokens
foreach ($token in $tokens) {
    $serialNumber = $token.'serial number'
    $secretKey = $token.'secret key'
    $timeInterval = [int]$token.'timeinterval'
    $manufacturer = $token.'manufacturer'
    $model = $token.'model'

    # Registration of the OATH token via Microsoft Graph
    $body = @{
        displayName   = "$manufacturer $model"
        serialNumber  = $serialNumber
        manufacturer  = $manufacturer
        model        = $model
        secretKey    = $secretKey
        timeIntervalInSeconds  = $timeInterval
        hashFunction    = "hmacsha1"
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/directory/authenticationMethodDevices/hardwareOathDevices" -Body $body -ContentType "application/json"
        Write-Host -ForegroundColor Green "Token with Serialnumber $serialNumber registered successfully."
    } catch {
        Write-Host -ForegroundColor Yellow "Error registrating Token $serialNumber - Maybe the Token is already enrolled or staged"
    }
}

# Show Tokens in Staging Mode
Write-Host "The following Tokens are currently in Staging Mode"
$result = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/authenticationMethodDevices/hardwareOathDevices"
foreach ($item in $result.value) {
    $item | Format-Table Name, Value -AutoSize
    if ($item.Name -eq "hashFunction") {
        Write-Host ""
    }
}

# Verbindung trennen
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null


