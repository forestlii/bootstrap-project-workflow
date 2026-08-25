[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$skillName = 'bootstrap-project-workflow'
$source = Join-Path $PSScriptRoot "skill\$skillName"
$requiredFiles = @(
    (Join-Path $source 'SKILL.md'),
    (Join-Path $source 'agents\openai.yaml')
)

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Skill source is incomplete: $requiredFile"
    }
}

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
    throw 'USERPROFILE is not available.'
}

$destinationRoot = Join-Path $env:USERPROFILE '.agents\skills'
$destination = Join-Path $destinationRoot $skillName

if (Test-Path -LiteralPath $destination) {
    throw "Skill is already installed: $destination"
}

New-Item -ItemType Directory -Path $destinationRoot -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Recurse

Write-Host "Installed $skillName for Codex: $destination"
