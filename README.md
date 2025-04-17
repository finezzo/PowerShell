Haftungsausschluss für die Nutzung
----------------------------------
Dieses Skript wird ohne jegliche Gewährleistung bereitgestellt. Die Nutzung erfolgt auf eigene Gefahr. Der Autor übernimmt keine Verantwortung für Schäden, Datenverluste oder andere Probleme, die durch die Nutzung dieses Skripts entstehen könnten. Bitte prüfen Sie das Skript sorgfältig, bevor Sie es in einer produktiven Umgebung einsetzen. Der Nutzer ist allein verantwortlich für alle Folgen, die sich aus der Anwendung des Skripts ergeben.

Disclaimer for Script Usage
---------------------------
This script is provided “as is” without any warranty of any kind. Use it at your own risk. The author is not responsible for any damages, data loss, or other issues that may arise from using this script. Please review the script carefully before using it in a production environment. The user assumes full responsibility for any consequences resulting from the use of this script.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
General
-------
**ConvertHEXtoBASE32.ps1**
Used for converting HEX to BASE32. My use case was converting the HEX-Delivered Secret Keys of FEITAN TOTP Hardware Tokens for importing them in ENTRA ID

**Disable-Hiberboot.ps1**
Disable Fastboot on Windows Systems. Fastboot often leads to problems, because systems are not shutting down correctly and a clean reboot is not performed normally. This disables that behaviour.

**Export-Mails-with-Graph.ps1**
Used for batch exporting Mails based on the MessageID as EML file.

Active Directory
----------------

**Get-ADComputers-WithOS-toCSV.ps1**
- Provides a csv Output of all computer objects in Active Directory with Name, OS Version, Logon Date and End of Service Information for Windows 10 and Windows 11

Exchange on Prem
----------------

**Cleanup-INETPUBLOGS.ps1**
Provides a cleanup script to delete Inetpub Logs older than a certain time

EntraID
-------

**CA-Audit.ps1**
Provides a fast way to export all Conditional Access Policies

**Stage-OATH-Tokens-from-CSV.ps1**
Provides an easy way Stage OATH Hardware Tokens and make them ready for Self Service Enrollment
