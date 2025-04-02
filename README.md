The scripts in this repository are provided "as is" and without any warranties. Use them at your own risk. The authors are not liable for any damage or issues that may arise from using these scripts. Please test thoroughly before use in any critical environment.

ConvertHEXtoBASE32.ps1
- Used for converting HEX to BASE32. My use case was converting the HEX-Delivered Secret Keys of FEITAN TOTP Hardware Tokens for importing them in ENTRA ID

- Disable-Hiberboot.ps1
  Disable Fastboot on Windows Systems. Fastboot often leads to problems, because systems are not shutting down correctly and a clean reboot is not performed normally. This disables that behaviour.

--- Active Directory ---

Get-ADComputers-WithOS-toCSV.ps1
- Provides a csv Output of all computer objects in Active Directory with Name, OS Version, Logon Date and End of Service Information for Windows 10 and Windows 11

--- Exchange ---

Cleanup-INETPUBLOGS.ps1
Provides a cleanup script to delete Inetpub Logs older than a certain time

--- EntraID ---

CA-Audit.ps1
Provides a fast way to export all Conditional Access Policies

Stage-OATH-Tokens-from-CSV.ps1
Provides an easy way Stage OATH Hardware Tokens and make them ready for Self Service Enrollment
