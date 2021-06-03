$ErrorActionPreference = 'Stop';
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  softwareName   = 'Gather*'
  fileType       = 'exe'
  silentArgs     = '/S'
  validExitCodes = @(0)
  url            = 'https://github.com/gathertown/gather-town-desktop-releases/releases/download/v0.0.9/Gather-Setup-0.0.9.exe'
  checksum       = '498DFFC48FD3D53A1CC65C564C99627084DBC931B163FF203CD4FF1F482614EF'
  checksumType   = 'sha256'
}

Install-ChocolateyPackage @packageArgs
