function ConvertTo-Base32 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HexString
    )

    # Hilfsfunktionen
    function HexToBytes {
        param (
            [string]$hex
        )
        $bytes = [System.Collections.Generic.List[byte]]::new()
        for ($i = 0; $i -lt $hex.Length; $i += 2) {
            $bytes.Add([System.Convert]::ToByte($hex.Substring($i, 2), 16))
        }
        return $bytes.ToArray()
    }

    function BytesToBase32 {
        param (
            [byte[]]$bytes
        )
        $base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        $base32 = ""
        $buffer = 0
        $bitCount = 0

        foreach ($byte in $bytes) {
            $buffer = ($buffer -shl 8) -bor $byte
            $bitCount += 8

            while ($bitCount -ge 5) {
                $bitCount -= 5
                $index = ($buffer -shr $bitCount) -band 31
                $base32 += $base32Alphabet[$index]
                $buffer = $buffer -band ((1 -shl $bitCount) - 1)
            }
        }

        if ($bitCount -gt 0) {
            $index = ($buffer -shl (5 - $bitCount)) -band 31
            $base32 += $base32Alphabet[$index]
        }

        while (($base32.Length % 8) -ne 0) {
            $base32 += '='
        }

        return $base32
    }

    # Hex-Wert in Bytes umwandeln
    $byteArray = HexToBytes -hex $HexString

    # Bytes in Base32 umwandeln
    $base32Result = BytesToBase32 -bytes $byteArray

    return $base32Result
}

# Hex-Wert
$hexValue = "904EAA707DC62A759B9832C6FBE91932BD78CCC1"

# Konvertierung durchführen
$base32Result = ConvertTo-Base32 -HexString $hexValue

# Ergebnis ausgeben
Write-Output $base32Result
