function Add-ScheduleTask {
    <#
.SYNOPSIS
    Ajout de tâches planifiées sur les serveurs RDS
.DESCRIPTION
    Cette fonction ajoute des tâches planifiées de maintenance sur les serveurs RDS (2012 R2) tournant avec un Managed Service Account (MSA)
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        
    )
    
    begin {
        # Define this variable a the beginning ans use in write-verbose '[$Scriptname] - '
        $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand
        
        write-verbose "[$Scriptname] - BEGIN PROCESS" 
        
        write-verbose "[$Scriptname] - Test de la présence des outils RSAT AD..."
        if (!(Get-WindowsFeature -Name "RSAT-AD-PowerShell").Installed) {
            Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeManagementTools
        }

        Import-module ActiveDirectory
        write-verbose "[$Scriptname] - Installation du MSA..."
        Install-ADServiceAccount -Identity msaRDSService
    }
    
    process {
        #region <Reboot Serveur RDS>
        #Supprime l'ancienne tâche planifiée
        Unregister-ScheduledTask -TaskName rebootRDS_Powershell -Confirm:$false -ErrorAction Continue

        write-verbose "[$Scriptname] - Création de la nouvelle tâche planifiée RebootRDSDaily..."
        $action = New-ScheduledTaskAction  "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\RestartComputer.ps1"
        $trigger = New-ScheduledTaskTrigger -At 23:00 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password

        Register-ScheduledTask RebootRDSDaily –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force
        #endregion

        #region <RemoveLogNsclient>
        #Supprime l'ancienne tâche planifiée
        Unregister-ScheduledTask -TaskName RemoveLogNsclient -Confirm:$false -ErrorAction Continue

        write-verbose "[$Scriptname] - Création de la nouvelle tâche planifiée removeLogNsClient..."
        $action = New-ScheduledTaskAction  "C:\Scripts\RemoveLogNsClient.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password

        Register-ScheduledTask RemoveLogNsclient –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force
        #endregion

        #region <Ménage clé .bak et userprofile>
        #Supprime l'ancienne tâche planifiée
        Unregister-ScheduledTask -TaskName "Ménage clé .bak et userprofile" -Confirm:$false -ErrorAction Continue

        #Création de la nouvelle tâche planifiée
        #$action = New-ScheduledTaskAction  "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-noprofile -executionpolicy bypass -file C:\Scripts\remove-OldProfile.ps1"
        #$trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        #$principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password -RunLevel Highest

        #Register-ScheduledTask "Ménage clé .bak et userprofile" –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force
        #endregion

        #region <Defragmentation Base de donnée Windows Search>
        #Supprime l'ancienne tâche planifiée
        Unregister-ScheduledTask -TaskName "Defragmentation Base de donnée Windows Search" -Confirm:$false -ErrorAction Continue

        write-verbose "[$Scriptname] - Création de la nouvelle tâche planifiée Defragmentation Base de donnée Windows Search..."
        $action = New-ScheduledTaskAction  "C:\Tools\Defrag_DB_WindowsSearch.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password

        Register-ScheduledTask "Defragmentation Base de donnée Windows Search" –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force
        #endregion

        #region <MAJ_PREM>
        #Supprime l'ancienne tâche planifiée
        Unregister-ScheduledTask -TaskName "MAJ_PREM" -Confirm:$false -ErrorAction Continue

        write-verbose "[$Scriptname] - Création de la nouvelle tâche planifiée MAJ_PREM..."
        $action = New-ScheduledTaskAction  "C:\Tools\MAJ_PREM.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:30 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password

        Register-ScheduledTask "MAJ_PREM" –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force
        #endregion     
    }
    
    end {
        Remove-Module ActiveDirectory
    }
}







