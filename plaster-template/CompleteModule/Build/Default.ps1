properties {
    $ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"
    $OriginePath = split-path $PSScriptRoot
 }

task Init -description "Initialisation" {
   #Write-Host "==> ModuleName : " $ModuleName 
   Write-host "Test de la présence du module"
   if (!(Get-Module -ListAvailable -Name $ModuleName)) {
    .\$OriginePath\Deploy\launch_deploy.ps1
}
}
 
task Compile -description "Compiler le code" {
   Write-Host "==> OriginePath : " $OriginePath
}
  
task default -depends init, compile -description "lancer toutes les tasks"