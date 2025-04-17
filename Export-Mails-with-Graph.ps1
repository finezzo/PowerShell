# Berechtigungen die benötigt werden 
#Mail.Read
#Mail.ReadBasic
#Mail.ReadBasic.All
#MailboxFolder.Read.All
#MailboxItem.Read.All
#User-Mail.ReadWrite.All

# Zeile 18 - UPN Eintragen
# Zeile 19 - Export Ordner für die PSTs festlegen
# Zeile 20 - Datei mit den Message IDs referenzieren

$clientID = ""
$ClientSecret = ""
$tennent_ID = ""

#die UPN des Postfachs, das du durchsuchen möchtest, und der Ordner, in dem die Nachrichten gespeichert werden sollen.
$Search_UPN = "user@example.com"
$OutFolder = "C:\Temp\Mail"
$list_of_MessageIDS = "c:\temp\MessageIDs.txt"

#Auth
$AZ_Body = @{
    Client_Id       = $clientID
    Scope           = "https://graph.microsoft.com/.default"
    Client_Secret   = $ClientSecret
    Grant_Type      = "client_credentials"
}
$token = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tennent_ID/oauth2/v2.0/token" -Body $AZ_Body)
$Auth_headers = @{
    "Authorization" = "Bearer $($token.access_token)"
    "Content-type"  = "application/json"
}

#parse die Liste der Nachrichten-IDs aus einer Datei
$list = get-content $list_of_MessageIDS

#Nachrichten parsen
foreach($INetMessageID in $list) {
    #Variablen löschen und einen Dateinamen ohne Sonderzeichen erstellen
    $Search_body = ""
    $message = ""
    $messageID = ""
    $body_Content = ""
    $message_Content = ""
    $result = ""
    $fname = $INetMessageID.replace("<","").replace(">","").replace("@","_").replace(".","_").replace(" ","_").replace("+","_").replace("=","_")

    #Suche nach der Nachricht und parse die Nachrichten-ID
    $Search_body = "https://graph.microsoft.com/v1.0/users/$Search_UPN/messages/?`$filter=internetMessageId eq '${INetMessageID}'"
    Write-Host $Search_body
    $result = Invoke-WebRequest -Uri $Search_body  -Method Get -Headers $Auth_headers
    $messageID = ($result.Content | convertfrom-json).value.id
    #write-host $messageID

    #wenn die Nachrichten-ID nicht null ist, hole den Nachrichtenwert und speichere den Inhalt in einer Datei
    if(!([string]::IsNullOrEmpty($messageID))) {
        $body_Content = "https://graph.microsoft.com/v1.0/users/$Search_UPN/messages/$messageID/`$value"
        $message_Content = Invoke-webrequest -Uri $body_Content -Method Get -Headers $Auth_headers 
        $message_Content.Content | Out-File "$OutFolder\$fname.eml" -Encoding utf8 -Force
        #write-host $message_Content
    }
}
