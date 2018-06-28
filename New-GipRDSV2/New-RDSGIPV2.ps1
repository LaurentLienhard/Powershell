Param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$IP,
    [Parameter(Mandatory = $false)][string]$VCenter = "SRV-VCGIP",
    [Parameter(Mandatory = $false)][string]$CustomFile = "Deploy_RDSGIP_V2",
    [Parameter(Mandatory = $false)][string]$TemplateFile = "RDSGIPV2-O365",
    [Parameter(Mandatory = $false)][string]$Collection = "BUREAU GIPV2",
    [Parameter(Mandatory = $false)][string]$ConnectionBroker = "SRV-RDSMGMT01",
    [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()][Parameter(Mandatory = $true)]$Cred = [System.Management.Automation.PSCredential]::Empty
)


Import-Module PSManageRDServer
Import-Module VMware.VimAutomation.Core

try {
    Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false
    Connect-VIServer -Server $VCenter -Credential $cred
    }
    catch {
    Write-Warning "[$Scriptname] - Error connecting to VCenter end of script"
    Break
    }

New-RDSServer -Server $server -IP $IP -VCenter $VCenter -CustomFile $CustomFile -TemplateFile $TemplateFile -Cred $Cred -Verbose

if (Get-VM -Name $Server) {
    Set-RDSServer -Server $Server -AddToCollection -Collection $Collection -VCenter $VCenter -ConnectionBroker $ConnectionBroker -cred $Cred -Verbose
    Set-Task -Server $Server -Verbose -cred $Cred
}
