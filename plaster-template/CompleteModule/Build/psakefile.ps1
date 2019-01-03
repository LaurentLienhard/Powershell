[cmdletbinding()]

$SourceFolder = split-path $PSScriptRoot

if (-not (Get-Module PSDepend -ListAvailable)) {

    Install-Module PSDepend -Repository (Get-PSRepository)[0].Name -Scope CurrentUser

}

Push-Location $PSScriptRoot -StackName BuildScript
Invoke-PSDepend -Path $SourceFolder -Confirm:$false
Pop-Location -StackName BuildScript



Write-Verbose -Message "Working in $SourceFolder"

$Module = Get-ChildItem -Path $SourceFolder -Filter *.psd1 -Recurse |

    Where-Object {$_.FullName -notlike '*Output*'} |

    Select-String -Pattern 'RootModule' |

    Select-Object -First 1 -ExpandProperty Path



$Module = Get-Item -Path $Module



$OutputFolder = Join-Path -Path $($Module.Directory.FullName) -ChildPath "Output\"

$null = New-Item -Path $OutputFolder -ItemType Directory -Force -Confirm:$false

$DestinationModule = Join-Path -Path $($Module.Directory.FullName) -ChildPath "Output\$($Module.BaseName).psm1"

$OutputManifest = Join-Path -Path $($Module.Directory.FullName) -ChildPath "Output\$($Module.BaseName).psd1"

Copy-Item -Path $Module.FullName -Destination $OutputManifest -Force



Write-Verbose -Message "Attempting to work with $DestinationModule"



if (Test-Path -Path $DestinationModule ) {

    Remove-Item -Path $DestinationModule -Confirm:$False -force

}


$PublicClass = Get-ChildItem -Path $SourceFolder -Include 'Class', 'Classe' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File

$PublicFunctions = Get-ChildItem -Path $SourceFolder -Include 'Public', 'External' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File

$PrivateFunctions = Get-ChildItem -Path $SourceFolder -Include 'Private', 'Internal' -Recurse -Directory | Get-ChildItem -Include *.ps1 -File


Foreach ($Class in $PublicClass) {

    Get-Content -Path $Class.FullName | Add-Content -Path $DestinationModule

}

Write-Verbose -Message "Found $($PublicClass.Count) Public Class and added them to the psm1."

if ($PublicFunctions -or $PrivateFunctions) {

    Write-Verbose -message "Found Private or Public functions. Will compile these into the psm1 and only export public functions."



    Foreach ($PrivateFunction in $PrivateFunctions) {

        Get-Content -Path $PrivateFunction.FullName | Add-Content -Path $DestinationModule

    }

    Write-Verbose -Message "Found $($PrivateFunctions.Count) Private functions and added them to the psm1."

}

else {

    Write-Verbose -Message "Didnt' find any Private or Public functions, will assume all functions should be made public."



    $PublicFunctions = Get-ChildItem -Path $SourceFolder -Include *.ps1 -Recurse -File

}



Foreach ($PublicFunction in $PublicFunctions) {

    Get-Content -Path $PublicFunction.FullName | Add-Content -Path $DestinationModule

}

Write-Verbose -Message "Found $($PublicFunctions.Count) Public functions and added them to the psm1."


$PublicFunctionNames = $PublicFunctions |

    Select-String -Pattern 'Function (\w+-\w+) {' -AllMatches |

    Foreach-Object {

    $_.Matches.Groups[1].Value

}

Write-Verbose -Message "Making $($PublicFunctionNames.Count) functions available via Export-ModuleMember"


"Export-ModuleMember -Function $($PublicFunctionNames -join ',')" | Add-Content -Path $DestinationModule

$Null = Get-Command -Module Configuration

Update-Metadata -Path $OutputManifest -PropertyName FunctionsToExport -Value $PublicFunctionNames

Write-Verbose "Deploy Module"
$source  =   $SourceFolder +'\Deploy\Deploy.ps1'

Invoke-PSDeploy -Path $Source -tag "DEV" -Force

Write-Verbose "Pester Module"
Invoke-Pester -Script $SourceFolder -CodeCoverage $DestinationModule

Write-Verbose "ScriptAnalyser Module"
Invoke-ScriptAnalyzer -Path $DestinationModule
