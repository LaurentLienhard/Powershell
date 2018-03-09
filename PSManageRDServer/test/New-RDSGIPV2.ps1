Param(
    [Parameter(Mandatory = $true)][string]$Server,
    [Parameter(Mandatory = $true)][string]$IP,
    [Parameter(Mandatory = $false)][string]$VCenter = "SRV-VCGIP",
    [Parameter(Mandatory = $false)][string]$CustomFile = "Deploy_RDSGIP_V2",
    [Parameter(Mandatory = $false)][string]$TemplateFile = "RDSGIPV2",
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

New-RDSServer -Server $server -IP $IP -VCenter $VCenter -CustomFile $CustomFile -TemplateFile $TemplateFile

        


if (Get-VM -Name $Server) {
    Set-RDSServer -Server $Server -AddToCollection -Collection $Collection -VCenter $VCenter -ConnectionBroker $ConnectionBroker
}

#region <tache de post installation>


        write-verbose "[$Scriptname] - Ajout des taches planifiees..."
        $ScheduledTaskScript = 'Import-module ActiveDirectory
        Install-ADServiceAccount -Identity msaRDSService

        $action = New-ScheduledTaskAction� "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\RestartComputer.ps1"
        $trigger = New-ScheduledTaskTrigger -At 23:00 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask RebootRDSDaily -Action $action -Trigger $trigger -Principal $principal -TaskPath \Maintenance -Force

        $action = New-ScheduledTaskAction� "C:\Scripts\RemoveLogNsClient.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask RemoveLogNsclient �Action $action �Trigger $trigger �Principal $principal -TaskPath \Maintenance -Force        
 
        $action = New-ScheduledTaskAction� "C:\Tools\Defrag_DB_WindowsSearch.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask "Defragmentation Base de donn�e Windows Search" �Action $action �Trigger $trigger �Principal $principal -TaskPath \Maintenance -Force

        $action = New-ScheduledTaskAction� "C:\Tools\MAJ_PREM.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:30 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask "MAJ_PREM" �Action $action �Trigger $trigger �Principal $principal -TaskPath \Maintenance -Force

        Get-ScheduledTask -TaskName "MAJ_PREM" | Start-ScheduledTask'
        Invoke-VMScript -ScriptText $ScheduledTaskScript -VM $Server -GuestCredential $cred

        write-verbose "[$Scriptname] - Installation de l'antivirus Trend..."
        $InstallAVScript = '\\srv-av02\ofcscan\AutoPcc.exe'
        Invoke-VMScript -ScriptText $InstallAVScript -VM $Server -GuestCredential $cred -ScriptType Bat

        write-verbose "[$Scriptname] - Lancement d'un premier invventaire GLPI..."
        $LaunchInventoryScript = '"C:\Program Files\FusionInventory-Agent\fusioninventory-agent.bat"'
        Invoke-VMScript -ScriptText $LaunchInventoryScript -VM $Server -GuestCredential $cred -ScriptType Bat
        #endregion





