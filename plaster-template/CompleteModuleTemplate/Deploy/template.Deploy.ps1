if (!(Get-Module -ListAvailable -Name PSDeploy)) {
    Install-Module -Name PSDeploy -Scope CurrentUser
}
Import-Module PSDeploy
$path  = $env:OneDrive + '\Documents\01-DEV\VSTS\' + $PLASTER_PARAM_ModuleName + '\Deploy\Deployments.yml'
Invoke-PSDeployment -Path $path -Force -Verbose
