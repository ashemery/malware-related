# Ensure script accepts two arguments
if ($args.Count -ne 2) {
    Write-Host "Usage: .\wrapper.ps1 <obfuscatedFilePath> <password>"
    exit
}

$obfuscatedFilePath = $args[0]
$password = $args[1]

function Decrypt-String {
    param (
        [string]$cipherText,
        [string]$password
    )

    # Generate AES key and IV from the password
    $aes = [System.Security.Cryptography.Aes]::Create()
    $deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($password, [System.Text.Encoding]::UTF8.GetBytes("SaltIsGoodForSecurity"))
    $aes.Key = $deriveBytes.GetBytes(32)
    $aes.IV = $deriveBytes.GetBytes(16)

    # Decrypt the cipher text
    $decryptor = $aes.CreateDecryptor()
    $encryptedBytes = [Convert]::FromBase64String($cipherText)
    $memoryStream = New-Object System.IO.MemoryStream
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $cryptoStream.Write($encryptedBytes, 0, $encryptedBytes.Length)
    $cryptoStream.Close()
    $memoryStream.Close()

    # Convert decrypted bytes to plain text
    $decryptedBytes = $memoryStream.ToArray()
    return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
}

function Load-ObfuscatedModule {
    param (
        [string]$obfuscatedFilePath,
        [string]$password
    )

    # Read the obfuscated content from the file
    $base64Content = Get-Content -Path $obfuscatedFilePath -Raw

    # Decrypt the obfuscated content
    $scriptContent = Decrypt-String -cipherText $base64Content -password $password

    # Save the decrypted script content to a temporary file
    $tempPath = [System.IO.Path]::GetTempFileName() + ".psm1"
    Set-Content -Path $tempPath -Value $scriptContent

    # Import the module
    Import-Module $tempPath

    # Optionally remove the temporary file after loading
    Remove-Item -Path $tempPath
}

# Load the obfuscated module
Load-ObfuscatedModule -obfuscatedFilePath $obfuscatedFilePath -password $password
