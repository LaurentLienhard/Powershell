
<#PSScriptInfo

.VERSION 1.0

.GUID 971e3db7-f0a4-4071-882f-77a2d70b5d28

.AUTHOR Laurent.Lienhard

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Create a New RDS Server 

#> 
Param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$IP,
    [Parameter(Mandatory = $false)][string]$VCenter = "SRV-VCGIP",
    [Parameter(Mandatory = $false)][string]$CustomFile = "Deploy_RDSGIP_V2",
    [Parameter(Mandatory = $false)][string]$TemplateFile = "RDSGIPV2",
    [Parameter(Mandatory = $false)][string]$Collection = "BUREAU GIPV2",
    [Parameter(Mandatory = $false)][string]$ConnectionBroker = "SRV-RDSMGMT01",
    [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]
    [Parameter(Mandatory = $true)]$Cred = [System.Management.Automation.PSCredential]::Empty
)


Import-Module PSManageRDServer
Import-Module VMware.VimAutomation.Core

New-RDSServer -Server $server -IP $IP -VCenter $VCenter -CustomFile $CustomFile -TemplateFile $TemplateFile -Cred $Cred

if (Get-VM -Name $Server) {
    Set-RDSServer -Server $Server -AddToCollection -Collection $Collection -VCenter $VCenter -ConnectionBroker $ConnectionBroker -Cred $Cred
}



