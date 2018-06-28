param(
    [ValidateSet("Dev","Prod", "Gallery")][string]$Tag = "Dev"
)

if (!(Get-Module -ListAvailable -Name PSDeploy)) {
    Install-Module -Name PSDeploy -Scope CurrentUser
}
Import-Module PSDeploy

$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"
$source  = 'C:\Users\Laurent.Lienhard\OneDrive - PoleHabitatStrasbourg\01-Devs\Powershell\' + $ModuleName  + '\Deploy\Deploy.ps1'

Invoke-PSDeploy -Path $source -tag $Tag -Force -Verbose