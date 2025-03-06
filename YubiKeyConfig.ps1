# Function to check if a YubiKey is inserted and return its serial number
function Get-YubiKeySerial {
    $output = .\ykman.exe list
    if ($output -match 'Serial:\s*(\d+)') {
        return $matches[1]
    }
    return $null
}

# Function to configure the YubiKey
function Configure-YubiKey {
    # Add your ykman configuration commands here
    .\ykman.exe config usb --disable U2F -f
    .\ykman.exe config usb --disable OATH -f
    .\ykman.exe config usb --disable PIV -f
    .\ykman.exe config usb --disable OPENPGP -f
    .\ykman.exe config usb --disable HSMAUTH -f
    
    .\ykman.exe config nfc --disable OTP -f
    .\ykman.exe config nfc --disable OATH -f
    .\ykman.exe config nfc --disable U2F -f
    .\ykman.exe config nfc --disable PIV -f
    .\ykman.exe config nfc --disable OPENPGP -f
    .\ykman.exe config nfc --disable HSMAUTH -f

    # Add more configuration commands as needed
}

# Function to set the YubiKey lock code and return its value
function Set-LockCode {
    $output = .\ykman.exe config set-lock-code --generate -f
    Write-Host $output
    if ($output -match 'code:\s*(\w+)') {
        return $matches[1]
    }
    return $null
}

# Function to write the YubiKey Lock Codes
function Write-YubiKeyLockCode{
    param (
        [Parameter(Mandatory=$true)]
        $serialNumber,

        [Parameter(Mandatory=$true)]
        $lockCode
    )

$Content = [PSCustomObject]@{SerialNumber = $serialNumber; YubiKeyConfigurationLockCode = $lockcode}
$Content | Export-Csv -Path $env:USERPROFILE\YubiKeyLockCodes.csv -NoTypeInformation -Append
}

# Main script loop
$previousSerial = $null

while ($true) {
    Write-Host "Please insert a YubiKey..."
    
    # Wait for a new YubiKey to be inserted
    while ($true) {
        $currentSerial = Get-YubiKeySerial
        if ($currentSerial -and $currentSerial -ne $previousSerial) {
            $previousSerial = $currentSerial
            break
        }
        Start-Sleep -Seconds 1
    }
    
    Write-Host "YubiKey detected (Serial: $currentSerial). Configuring..."
    
    Configure-YubiKey

    $currentKeyLockCode = Set-LockCode

    Write-YubiKeyLockCode -lockCode $currentKeyLockCode -serialNumber $currentSerial

    Write-Host "Configuration complete. Please remove the YubiKey."
    
    # Wait for the YubiKey to be removed
    while ($true) {
        $currentSerial = Get-YubiKeySerial
        if (-not $currentSerial) {
            break
        }
        Start-Sleep -Seconds 1
    }
}