$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

. $toolsDir\helpers.ps1
Invoke-UninstallOldTrueView

#REMOVE REBOOT REQUESTS
$RegRebootRequired = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
if (Test-path $RegRebootRequired) { Remove-Item -Path $RegRebootRequired }


#INSTALLATION SETTINGS
$checksum = '[[Checksum]]'
$extractor = Join-Path $toolsDir -ChildPath 'DWGTrueView_2023_English_64bit_dlm.sfx.exe'
$file = Join-Path $env:TEMP 'DWGTrueView_2023_English_64bit_dlm\Setup.exe'


$packageArgsUnzip = @{
  packageName    = 'DWG TrueView Installation Files'
  fileType       = 'exe'
  file            = $extractor
  softwareName   = 'DWG TrueView Installation Files*'
  checksum       = $checksum
  checksumType   = 'sha256'
  silentArgs     = "-suppresslaunch -d $env:TEMP"
  validExitCodes = @(0, 3010, 1641)
}
Install-ChocolateyPackage @packageArgsUnzip

$packageArgs  = @{
  packageName    = 'DWG TrueView'
  fileType       = 'exe'
  file           = $file
  softwareName   = 'DWG TrueView*'
  silentArgs     = '-q'
  validExitCodes = @(0, 3010, 1641)
}
Install-ChocolateyInstallPackage @packageArgs
