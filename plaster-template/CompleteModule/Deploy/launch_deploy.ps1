param(
    [ValidateSet("Dev","Prod", "Gallery")][string]$Tag = "Dev"
)

if (!(Get-Module -ListAvailable -Name PSDeploy)) {
    Install-Module -Name PSDeploy -Scope CurrentUser -Confirm:$false -AllowClobber -Force
}
Import-Module PSDeploy

$source  =   $PSScriptRoot +'\Deploy.ps1'

Invoke-PSDeploy -Path $source -tag $Tag -Force -Verbose