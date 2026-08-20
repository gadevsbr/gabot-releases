$ErrorActionPreference = 'Stop'
$repo = 'gadevsbr/gabot-releases'
$installDir = Join-Path $env:LOCALAPPDATA 'GaBOT'
$download = "https://github.com/$repo/releases/latest/download/gabot-windows-amd64.exe"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
$binary = Join-Path $installDir 'gabot.exe'
$temporary = Join-Path $env:TEMP ("gabot-" + [guid]::NewGuid().ToString('N') + '.exe')
$checksums = Join-Path $env:TEMP ("gabot-" + [guid]::NewGuid().ToString('N') + '.sha256')
try {
    Invoke-WebRequest -UseBasicParsing -Uri $download -OutFile $temporary
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$repo/releases/latest/download/SHA256SUMS.txt" -OutFile $checksums
    $line = Get-Content -LiteralPath $checksums | Where-Object { $_ -match 'gabot-windows-amd64\.exe$' } | Select-Object -First 1
    if (-not $line) { throw 'Checksum do Windows nao encontrado na release.' }
    $expected = ($line -split '\s+')[0].ToLowerInvariant()
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporary).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { throw 'Download recusado: checksum SHA-256 nao confere.' }
    Move-Item -LiteralPath $temporary -Destination $binary -Force
} finally {
    Remove-Item -LiteralPath $temporary,$checksums -Force -ErrorAction SilentlyContinue
}
$launcher = Join-Path $installDir 'Iniciar GaBOT.cmd'
"@echo off`r`ncd /d `"$installDir`"`r`ngabot.exe serve`r`npause`r`n" | Set-Content -LiteralPath $launcher -Encoding ASCII
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'GaBOT.lnk'))
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = 'Iniciar GaBOT'
$shortcut.Save()
$uninstall = Join-Path $installDir 'Desinstalar GaBOT.ps1'
@"
`$ErrorActionPreference='Stop'
Remove-Item -LiteralPath (Join-Path ([Environment]::GetFolderPath('Desktop')) 'GaBOT.lnk') -Force -ErrorAction SilentlyContinue
Write-Host 'O programa sera removido. A pasta data sera preservada para backup.'
Remove-Item -LiteralPath '$binary','$launcher' -Force -ErrorAction SilentlyContinue
"@ | Set-Content -LiteralPath $uninstall -Encoding UTF8
Write-Host "GaBOT instalado em $installDir" -ForegroundColor Green
Write-Host 'O assistente de configuracao sera aberto agora.'
Push-Location $installDir
try {
    if (-not (Test-Path (Join-Path $installDir 'data\credentials.env'))) { & $binary setup }
    else { Write-Host 'Dados existentes preservados. Use o atalho GaBOT para iniciar.' -ForegroundColor Cyan }
} finally { Pop-Location }
