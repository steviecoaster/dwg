Write-host "Working from $PWD"
$chocolateyTemplateFolder = Join-Path $env:ChocolateyInstall -ChildPath 'templates'

if(-not (Test-Path $chocolateyTemplateFolder)){
    $null = New-Item $chocolateyTemplateFolder
}

$trueViewTemplate = Join-Path $PWD -ChildPath 'templates\trueview\'

Write-Host "Got template: $trueViewTemplate"
Write-Host "Destination: $chocolateyTemplateFolder"

Copy-Item $trueViewTemplate -Destination $chocolateyTemplateFolder -Force