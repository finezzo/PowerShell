$sLogFolder = "C:\inetpub\logs\LogFiles"
$iMaxAge = 30   # in days

$objFSO = New-Object -ComObject Scripting.FileSystemObject
$colFolder = $objFSO.GetFolder($sLogFolder)

foreach ($colSubfolder in $colFolder.SubFolders) {
    $objFolder = $objFSO.GetFolder($colSubfolder.Path)
    $cutOffDate = (Get-Date).AddDays(-($iMaxAge + 1))

    foreach ($objFile in $objFolder.Files) {
        $iFileAge = $objFile.DateLastModified

        if ($iFileAge -lt $cutOffDate) {
            $objFSO.DeleteFile($objFile.Path, $true)
        }
    }
}
