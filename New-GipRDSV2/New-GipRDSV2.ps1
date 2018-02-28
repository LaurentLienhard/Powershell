function New-GipRDSV2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VMName,
        [Parameter(Mandatory = $true)][string]$IP,
        [Parameter(Mandatory = $true)][string]$VCenter,
        [Parameter(Mandatory = $true)][string]$LocalPWord = 'Passw0rd',
        [Parameter(Mandatory = $false)][switch]$AddToCollection,
        [Parameter(Mandatory = $false)][switch]$AllowConnection
    )
    
    begin {
        Clear-Host

        $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand
        write-verbose "[$Scriptname] - BEGIN PROCESS" 
        
        Import-Module ActiveDirectory -Verbose:$false
        Import-Module -Name VMware.VimAutomation.Core -Verbose:$false
        $cred = Get-Credential -Message "Compte Admin VI"
        try {
            Connect-VIServer -Server $VCenter -Credential $cred
        }
        catch {
            Write-Warning "[$Scriptname] - Erreur de connexion au VCenter fin du script"
            Break
        }
        
        
        #region <Validation des variable>
        Write-verbose "[$Scriptname] - Vérification de la disponibilité de l'adresse IP $ip ..."
        $Ping = New-Object System.Net.Networkinformation.ping
        $Status = ($Ping.Send("$IP", 1)).Status
        if ($Status -eq "Success") {
            Write-Warning "$IP is in use!"
            Break
        }
        
        Write-verbose "[$Scriptname] - Vérification de la disponibilité du nom de la VM $VMName..."
        if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
            Write-Warning "$VMName is in use!"
            Break                    
        }

        if ($AllowConnection) {
            $AddToCollection = $true
        }
        #endregion

    }
    
    process {

        #region <Définition des parametres>
        $datastore = (Get-Datastore | Sort-Object -Property FreeSpaceGB -Descending | Select-Object -First 1).name
        Write-verbose "[$Scriptname] - Le datastore $Datastore va etre utilise..."
        
        Write-verbose "[$Scriptname] - Creation du fichier de custom..."
        if (Get-OSCustomizationSpec -Name temp1 -ErrorAction SilentlyContinue) {
            Remove-OSCustomizationSpec -OSCustomizationSpec temp1 -Confirm:$false
        }
        $OSCusSpec = Get-OSCustomizationSpec -Name 'Deploy_RDSGIP_V2' | New-OSCustomizationSpec -Name 'temp1' -Type NonPersistent
        
        Write-verbose "[$Scriptname] - Ajout de la configuration Ip dans le fichier de custom..."
        Get-OSCustomizationSpec $OSCusSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $IP -SubnetMask '255.255.255.0' -DefaultGateway '10.3.50.254' -Dns '10.1.50.10', '10.1.50.11'

        $VMTemplate = Get-Template -Name 'RDSGIPV2'
        Write-verbose "[$Scriptname] - Utilisation du template $VMtemplate..."
        
        $VMHost = Get-Cluster | Get-VMHost | Get-Random
        Write-verbose "[$Scriptname] - Le serveur hote $VMHost va etre utilise..."

        Write-verbose "[$Scriptname] - Declaration credential du local administrateur..."
        $VMLocalUser = "$VMNAME\Administrateur"
        $VMLocalPWord = ConvertTo-SecureString -String $LocalPWord -AsPlainText -Force
        $VMLocalCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VMLocalUser, $VMLocalPWord
 
        #enregion
 
        #region <Creation de la VM>
        write-verbose "[$Scriptname] - Creation du compte $VMName dans l'AD..."
        New-ADComputer -Name $VMName -SamAccountName $VMName -Path "OU=BUREAU-GIP2,OU=Serveurs RDS,OU=GIP,OU=PHS,DC=netintra,DC=local" -Server SRV-AD101 -Credential $cred
        write-verbose "[$Scriptname] - Ajout du server $VMName dans le groupe AD pour le MSA..."
        Start-Sleep -Second 30
        Add-ADGroupMember -Identity ServeursRDS -Members $VMName$

        Write-verbose "[$Scriptname] - Creation de la VM..."
        New-VM -Name $VMNAME -Template $VMTemplate -OSCustomizationSpec $OSCusSpec -VMHost $VMHost -Datastore $datastore
        Write-verbose "[$Scriptname] - Demarrage de la VM..."
        Start-VM -VM $VMName

        Write-Verbose -Message "Verifying that Customization for VM $VMName  has started ..."
        while ($True) {
            $DCvmEvents = Get-VIEvent -Entity $VMName
            $DCstartedEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationStartedEvent" }
 
            if ($DCstartedEvent) {
                break	
            }
 
            else {
                Start-Sleep -Seconds 5
            }
        }
 
        Write-Verbose -Message "Customization of VM $VMName has started. Checking for Completed Status......."
        while ($True) {
            $DCvmEvents = Get-VIEvent -Entity $VMName
            $DCSucceededEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationSucceeded" }
            $DCFailureEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationFailed" }
 
            if ($DCFailureEvent) {
                Write-Warning -Message "Customization of VM $VMName failed"
                return $False	
            }
 
            if ($DCSucceededEvent) {
                break
            }
            Start-Sleep -Seconds 5
        }
        Write-Verbose -Message "Customization of VM $VMName Completed Successfully!"

        Wait-Tools -VM $VMName -TimeoutSeconds 300
        #endregion

        #region <tache de post installation>

<#         write-verbose "[$Scriptname] - Activation de Windows..."
        $ActivateOSScript = 'cscript //B "%windir%\system32\slmgr.vbs" -ato >> c:\temp\result.log'
        #$ActivateOSScript ='slmgr.vbs -ato'
        Invoke-VMScript -ScriptText $ActivateOSScript -VM $VMName -GuestCredential $cred -ScriptType Bat #>

        write-verbose "[$Scriptname] - Ajout des taches planifiees..."
        $ScheduledTaskScript = 'Import-module ActiveDirectory
        Install-ADServiceAccount -Identity msaRDSService

        $action = New-ScheduledTaskAction  "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\RestartComputer.ps1"
        $trigger = New-ScheduledTaskTrigger -At 23:00 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask RebootRDSDaily -Action $action -Trigger $trigger -Principal $principal -TaskPath \Maintenance -Force

        $action = New-ScheduledTaskAction  "C:\Scripts\RemoveLogNsClient.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask RemoveLogNsclient –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force        
 
        $action = New-ScheduledTaskAction  "C:\Tools\Defrag_DB_WindowsSearch.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:15 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask "Defragmentation Base de donnée Windows Search" –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force

        $action = New-ScheduledTaskAction  "C:\Tools\MAJ_PREM.bat"
        $trigger = New-ScheduledTaskTrigger -At 23:30 -Daily
        $principal = New-ScheduledTaskPrincipal -UserID NETINTRA\msaRDSService$ -LogonType Password
        Register-ScheduledTask "MAJ_PREM" –Action $action –Trigger $trigger –Principal $principal -TaskPath \Maintenance -Force

        Get-ScheduledTask -TaskName "MAJ_PREM" | Start-ScheduledTask'
        Invoke-VMScript -ScriptText $ScheduledTaskScript -VM $VMName -GuestCredential $cred

        write-verbose "[$Scriptname] - Installation de l'antivirus Trend..."
        $InstallAVScript = '\\srv-av02\ofcscan\AutoPcc.exe'
        Invoke-VMScript -ScriptText $InstallAVScript -VM $VMName -GuestCredential $cred -ScriptType Bat

        write-verbose "[$Scriptname] - Lancement d'un premier invventaire GLPI..."
        $LaunchInventoryScript = '"C:\Program Files\FusionInventory-Agent\fusioninventory-agent.bat"'
        Invoke-VMScript -ScriptText $LaunchInventoryScript -VM $VMName -GuestCredential $cred -ScriptType Bat

        if ($AddToCollection) {
            write-verbose "[$Scriptname] - Ajout du serveur a la collection BUREAU-GIPV2..."
            $AddToCollectionScript = 'Import-Module RemoteDesktop
            Add-RDServer -Server ' + $VMName + '.netintra.local -Role RDS-RD-SERVER -ConnectionBroker srv-rdsmgmt01.netintra.local
            Add-RDSessionHost -SessionHost ' + $VMName + '.netintra.local -ConnectionBroker srv-rdsmgmt01.netintra.local -CollectionName "BUREAU GIPV2"
            Set-RDSessionHost -SessionHost ' + $VMName + '.netintra.local -NewConnectionAllowed No -ConnectionBroker srv-rdsmgmt01.netintra.local'
            Invoke-VMScript -ScriptText $AddToCollectionScript -VM $VMName -GuestCredential $cred
        }

        if($AllowConnection) {
            $AllowConnectionscript = 'Import-Module RemoteDesktop
            Set-RDSessionHost -SessionHost ' + $VMName + '.netintra.local -NewConnectionAllowed Yes -ConnectionBroker srv-rdsmgmt01.netintra.local'
            Invoke-VMScript -ScriptText $AllowConnectionscript -VM $VMName -GuestCredential $cred
        }
        #endregion
    }
    
    end {
        Remove-OSCustomizationSpec -OSCustomizationSpec temp1 -Confirm:$false
        Disconnect-VIServer -Confirm:$false
    }
}

New-GipRDSV2 -VMName SRV-RDS22 -IP 10.3.50.24 -VCenter srv-vcgip -LocalPWord Passw0rd -AddToCollection -Verbose

