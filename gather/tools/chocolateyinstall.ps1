$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  softwareName   = 'Gather*'
  fileType       = 'exe'
  silentArgs     = '/S'
  validExitCodes = @(0)
  url            = '[[URL]]'
  checksum       = '[[CHECKSUM]]'
  checksumType   = 'sha256'
}

Install-ChocolateyPackage @packageArgs
