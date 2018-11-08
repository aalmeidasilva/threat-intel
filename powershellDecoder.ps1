$input = Read-Host -Prompt 'Base64 Text'
$decoded = $(New-Object IO.StreamReader ($(New-Object IO.Compression.DeflateStream($(New-Object IO.MemoryStream(,$([Convert]::FromBase64String($input)))), [IO.Compression.CompressionMode]::Decompress)), [Text.Encoding]::ASCII)).ReadToEnd();

Write-Host "----- Decoded -----"
Write-Host $decoded
Write-Host "----- Decoded End -----"
