[cmdletbinding()]
Param()

Write-Verbose 'Fetching latest release information from Github'

$LatestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/gathertown/gather-town-desktop-releases/releases/latest'
| Select-Object -ExpandProperty Assets
| Where-Object { $_.name -match 'exe$' }

$Binary = $LatestRelease.name
$null   = $LatestRelease.name -match '(?<version>\d+(\.\d+)+)'
$Version = $matches.version

Write-Verbose "Found release for: $binary"
Write-Verbose "Version set to: $Version"

$CurrentVersion = choco list gather --exact -r -s https://chocolatey.org/api/v2
| ConvertFrom-CSV -Delimiter '|' -Header 'Name', 'Version'

if ($null -eq $CurrentVersion) {
  $CurrentVersion = [pscustomobject]@{ 'Version' = '0.0.0' }
}

if ([version]$($CurrentVersion.Version) -lt $Version) {
  $ToolsDirectory = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
  $OutputDirectory = "$ToolsDirectory/packages"

  If (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force
  }

  $Nuspec  = Get-ChildItem $ToolsDirectory -Recurse -Filter 'gather.nuspec'
  | Select-Object -ExpandProperty FullName
  $Install = Get-ChildItem $ToolsDirectory -Recurse -Filter 'chocolateyInstall.ps1'
  | Where-Object { $_.Directory -match 'gather' }
  | Select-Object -ExpandProperty FullName

  Write-Verbose "Install Script: $Install"

  $TempPath = Join-Path -Path $env:TEMP -ChildPath ([GUID]::NewGuid()).GUID
  Write-Verbose "Creating temp directory: $TempPath"
  $null = New-Item -Path $TempPath -ItemType Directory

  Write-Verbose 'Generating checksum for binary'
  Write-Verbose "Downloading from: $($LatestRelease.browser_download_url)"
  Invoke-WebRequest -Uri $LatestRelease.browser_download_url -OutFile "$TempPath\$binary"
  $Checksum = ((Get-FileHash -Path "$TempPath\$binary").Hash).trim()

  Write-Verbose "Generated checksum: $Checksum"

  Write-Verbose 'Replacing content in files'
  (Get-Content "$Nuspec").Replace('[[VERSION]]', "$Version")
  | Set-Content "$Nuspec"
  (Get-Content "$Install").Replace('[[URL]]', "$($LatestRelease.browser_download_url)")
  | Set-Content "$Install"
  (Get-Content "$Install").Replace('[[CHECKSUM]]', "$Checksum")
  | Set-Content "$Install"

  Write-Verbose 'Verify install script contents'
  Get-Content $Install

  Write-Verbose 'Packing the package'
  choco pack $Nuspec --output-directory="$OutputDirectory"

  Write-Verbose 'Validate nupkg is correct and push'
  $Package = Get-ChildItem -Path $OutputDirectory -Filter gather.*.nupkg
  | Select-Object -ExpandProperty FullName
  choco push $Package -s https://push.chocolatey.org --api-key="'$env:CHOCOLATEY_TOKEN'"
}