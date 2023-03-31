[CmdletBinding()]
Param(
    [Parameter()]
    [Switch]
    $GeneratePackage,

    [Parameter()]
    [Switch]
    $CopyTemplate,

    [Parameter()]
    [Switch]
    $PublishPackage
)

begin {
    function Assert-PackageVersion {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            [String]
            $PackageId
        )
    
        process {
            $chocoArgs = @('search', $PackageId, '--source="https://community.chocolatey.org/api/v2/"', '-r')
            
            Write-Verbose -Message "Getting latest version information from Chocolatey Community Repository"
            $version = & choco @chocoArgs | ConvertFrom-Csv -Delimiter '|' -Header Id, Version | Select-Object -ExpandProperty Version
            return $version
        }
    }
    
    function Get-DWGTrueviewDownloadUrl {
        [CmdletBinding()]
        Param(
            [Parameter()]
            [String]
            $PackageId = 'dwgtrueview'
        )
    
        process {
            Write-Verbose -Message "Getting latest download url for DWG Trueview installer"
            $tempPath = $env:TEMP | Join-Path -ChildPath "$((New-GUId).Guid)"
    
            $chocoargs = @('download', $PackageId, '-s https://community.chocolatey.org/api/v2/', "--output-directory='$TempPath'")
    
            if ($SuppressChocoOutput) {
                & choco @chocoArgs > $null
            }
            else {
                & choco @chocoArgs
            }
    
            $toolsDir = Join-Path $tempPath -ChildPath "download\$PackageId\tools"
            $installScript = Join-Path $toolsDir -ChildPath 'chocolateyinstall.ps1'
    
            $matcher = "(?<url>(?<=')https:\/\/.+English.+(?='))"
            $content = Get-Content $installScript -Raw
            $null = $content -match $matcher
            
            return $matches.url
            
        }
    
        end {
            Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    function Get-DWGTrueView {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            [String]
            $DownloadUrl
        )
    
        process {
            $env:TrueViewTempPath = $env:TEMP | Join-Path -ChildPath "$((New-GUId).Guid)"
    
            if (-not (Test-Path $env:TrueViewTempPath)) {
                $null = New-Item $env:TrueViewTempPath -ItemType Directory
            }
    
            $downloader = [System.Net.WebClient]::new()
    
            $fileName = Join-Path $env:TrueViewTempPath -ChildPath (Split-Path -Leaf $DownloadUrl)
    
            Write-Verbose -Message "Downlaoding DWG Trueview to $env:TrueViewTempPath"
            $downloader.DownloadFile($DownloadUrl, $fileName)
            $downloader.Dispose()
            return $fileName
        }
    }
    
    function New-DwgTrueviewPackage {
        [CmdletBinding()]
        Param(
            [Parameter()]
            [String]
            $PackageId = 'dwgtrueview',
    
            [Parameter()]
            [string]
            $Version = (Assert-PackageVersion -PackageId $PackageId),
    
            [Parameter()]
            [string]
            $Template = 'trueview',
    
            [Parameter()]
            [Switch]
            $SuppressChocoOutput
        )
    
        begin {
            $tempPath = $env:TEMP | Join-Path -ChildPath "$((New-GUId).Guid)"
            if (-not (Test-Path $tempPath)) {
                $null = New-Item $tempPath -ItemType Directory
            }
        }
        process {
            $outputDirectory = $tempPath
            $file = Download-DWGTrueView -DownloadUrl (Get-DWGTrueviewDownloadUrl)
    
            Write-Verbose -Message "Getting checksum for DWG Trueview installer"
            $checksum = (Get-FileHash $file).Hash
    
            Write-Verbose "Creating dwgtrueview package based off template $Template"
            $chocoArgs = @('new', $PackageId, "--template='$Template'", "--output-directory='$outputDirectory'", "Checksum=$checksum", "Version=$version")
            
            
            if ($SuppressChocoOutput) {
                & choco @chocoArgs > $null
            }
            else {
                & choco @chocoArgs
            }
    
            $toolsDir = Join-Path $outputDirectory -ChildPath "$PackageId\tools"
            Write-Verbose "Moving installer to package"
            Move-Item $file -Destination $toolsDir
    
            Write-Verbose -Message "Package created, generating nupkg"
            $nuspecFile = Join-Path $outputDirectory -ChildPath "$PackageId\$Packageid.nuspec"
            $packArgs = @('pack', $nuspecFile, "--output-directory='$outputDirectory'")
            if ($SuppressChocoOutput) {
                & choco @packArgs > $null
    
            }
            else {
                & choco @packArgs
            }
            
            Write-Host "Package available at the following location" -ForegroundColor Green
    
            return $outputDirectory
        }   
    
        end {
            Remove-Item (Split-Path -Parent $file) -Recurse -Force
        }
    }
}

process {
    switch($true){
        $GeneratePackage {}

        $CopyTemplate {

            Write-host "Working from $PWD"
            $chocolateyTemplateFolder = Join-Path $env:ChocolateyInstall -ChildPath 'templates\'

            if(-not (Test-Path $chocolateyTemplateFolder)){
                $null = New-Item $chocolateyTemplateFolder -ItemType Directory
            }

            $trueViewTemplate = Join-Path $PWD -ChildPath 'templates\trueview\'

            Write-Host "Got template: $trueViewTemplate"
            Write-Host "Destination: $chocolateyTemplateFolder"

            Copy-Item $trueViewTemplate -Destination $chocolateyTemplateFolder -Force -Recurse
        }
        
        $PublishPackage {}
    }
}