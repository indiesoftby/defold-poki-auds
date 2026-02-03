# Download Defold bob.jar (PowerShell)
# No external dependencies - uses only built-in PowerShell cmdlets

$ErrorActionPreference = "Stop"

$bobDir = ".internal"
$bobPath = "$bobDir/bob.jar"

# Create directory if needed
if (-not (Test-Path $bobDir)) {
    New-Item -ItemType Directory -Path $bobDir -Force | Out-Null
    Write-Host "Created $bobDir directory"
}

# Fetch stable info.json to get SHA1
Write-Host "Fetching Defold stable version info..."
$infoUrl = "https://d.defold.com/stable/info.json"
$infoJson = Invoke-RestMethod -Uri $infoUrl
$bobSha1 = $infoJson.sha1
Write-Host "Latest stable SHA1: $bobSha1"

# Check local bob.jar version if exists
$localSha1 = ""
if (Test-Path $bobPath) {
    try {
        $versionOutput = java -jar $bobPath --version 2>&1
        if ($versionOutput -match "(\w{40})") {
            $localSha1 = $Matches[1]
        }
        Write-Host "Local bob.jar SHA1: $localSha1"
    } catch {
        Write-Host "Could not get local bob.jar version"
    }
}

# Download if version mismatch or missing
if ($localSha1 -ne $bobSha1) {
    $bobUrl = "https://d.defold.com/archive/$bobSha1/bob/bob.jar"
    Write-Host "Downloading bob.jar from $bobUrl..."
    # Use .NET WebClient to handle redirects properly
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($bobUrl, (Resolve-Path $bobDir).Path + "/bob.jar")
    Write-Host "Downloaded bob.jar to $bobPath"
} else {
    Write-Host "bob.jar is up to date"
}

Write-Host "Done. bob.jar ready at $bobPath"
