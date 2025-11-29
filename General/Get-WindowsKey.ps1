function Get-WindowsKey {
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $digitalID = (Get-ItemProperty $path).DigitalProductId

    # Decode the key:
    $key = ''
    $chars = "BCDFGHJKMPQRTVWXY2346789"
    $isWin8 = ($digitalID[66] / 6) -as [int]
    $digitalID[66] = ($digitalID[66] -band 0xF7)

    for ($i = 24; $i -ge 0; $i--) {
        $current = 0

        for ($j = 14; $j -ge 0; $j--) {
            $current = ($current * 256) -bxor $digitalID[$j + 52]
            $digitalID[$j + 52] = [math]::Floor($current / 24)
            $current = $current % 24
        }

        $key = $chars[$current] + $key
    }

    # Insert hyphens
    $key = $key.Insert(5, '-').Insert(11, '-').Insert(17, '-').Insert(23, '-')
    return $key
}

Get-WindowsKey
