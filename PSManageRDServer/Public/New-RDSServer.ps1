function New-RDSServer {
    <#
.SYNOPSIS
    .
.DESCRIPTION
    This script allows you to modify the attributes of an RDS server. 
    Add the server to a collection, remove the server from a collection ....

.PARAMETER Server
    This parameter defines the name of the RDS server that will be created

.PARAMETER IP
    This parameter defines the the IP address of the server to be created.

.PARAMETER VCenter
    This parameter defines the name of the Virtual Center server.

.PARAMETER CustomFile
    This parameter defines the name of the customization file to use.

.PARAMETER TemplateFile
    This parameter defines the name of the template to use.

.EXAMPLE
    C:\PS> New-RDSServer -Server SERVER -IP 10.1.1.1 -VCenter SRV-VCenter -TemplateFile MyTemplate -CustomFile MyCustom
    
    This command will create a server "SERVER" with the IP address "10.1.1.1" based on the template "MyTemplate" and customized by the file "MyCustom"

.NOTES
    Author: LIENHARD Laurent
    Date  : February 28, 2018  
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Server,
        [Parameter(Mandatory = $true)][string]$IP,
        [Parameter(Mandatory = $true)][string]$VCenter,
        [Parameter(Mandatory = $true)][string]$CustomFile,
        [Parameter(Mandatory = $true)][string]$TemplateFile
    )
    
    begin {
        Clear-Host

        $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand
        write-verbose "[$Scriptname] - BEGIN PROCESS" 

        if ($AddToCollection -and (!($Collection) -or !($ConnectionBroker))) {
            Write-Warning "AddToCollection must be associated with a collection name and a Connection Broker"
            break
        }

        Import-Module ActiveDirectory -Verbose:$false
        Import-Module -Name VMware.VimAutomation.Core -Verbose:$false
        $cred = Get-Credential -Message "Admin VI Account"
        try {
            Connect-VIServer -Server $VCenter -Credential $cred
        }
        catch {
            Write-Warning "[$Scriptname] - Error connecting to VCenter end of script"
            Break
        }
        
        
        #region <Validation des variable>
        Write-verbose "[$Scriptname] - Checking the availability of the IP address : $ip ..."
        $Ping = New-Object System.Net.Networkinformation.ping
        $Status = ($Ping.Send("$IP", 1)).Status
        if ($Status -eq "Success") {
            Write-Warning "$IP is in use!"
            Break
        }
        
        Write-verbose "[$Scriptname] - Verifying the availability of the VM name : $Server..."
        if (Get-VM -Name $Server -ErrorAction SilentlyContinue) {
            Write-Warning "$Server is in use!"
            Break                    
        }
        #endregion

    }
    
    process {
        #region <Définition des parametres>
        $datastore = (Get-Datastore | Sort-Object -Property FreeSpaceGB -Descending | Select-Object -First 1).name
        Write-verbose "[$Scriptname] - The datastore $Datastore will be used..."

        Write-verbose "[$Scriptname] - Creation of the temporary custom file..."
        if (Get-OSCustomizationSpec -Name temp1 -ErrorAction SilentlyContinue) {
            Remove-OSCustomizationSpec -OSCustomizationSpec temp1 -Confirm:$false
        }
        $OSCusSpec = Get-OSCustomizationSpec -Name $CustomFile | New-OSCustomizationSpec -Name 'temp1' -Type NonPersistent
        
        Write-verbose "[$Scriptname] - Adding the Ip configuration to the temporary custom file..."
        Get-OSCustomizationSpec $OSCusSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $IP -SubnetMask '255.255.255.0' -DefaultGateway '10.3.50.254' -Dns '10.1.50.10', '10.1.50.11'

        $VMTemplate = Get-Template -Name $TemplateFile
        Write-verbose "[$Scriptname] - Using the template $VMtemplate..."
        
        $VMHost = Get-Cluster | Get-VMHost | Get-Random
        Write-verbose "[$Scriptname] - The host server $VMHost will be used..."
        #enregion

        #region <Creation de la VM>
        write-verbose "[$Scriptname] - Creating the $Server account in the AD..."
        New-ADComputer -Name $Server -SamAccountName $Server -Path "OU=BUREAU-GIP2,OU=Serveurs RDS,OU=GIP,OU=PHS,DC=netintra,DC=local" -Server SRV-AD101 -Credential $cred
        write-verbose "[$Scriptname] - Adding the $Server server in the AD group for the MSA..."
        Start-Sleep -Second 30
        Add-ADGroupMember -Identity ServeursRDS -Members $Server$
        
        Write-verbose "[$Scriptname] - Creation of the VM..."
        New-VM -Name $Server -Template $VMTemplate -OSCustomizationSpec $OSCusSpec -VMHost $VMHost -Datastore $datastore
        Write-verbose "[$Scriptname] - Starting the VM..."
        Start-VM -VM $Server
        
        Write-Verbose -Message "Verifying that Customization for VM $Server  has started ..."
        while ($True) {
            $DCvmEvents = Get-VIEvent -Entity $Server
            $DCstartedEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationStartedEvent" }
         
            if ($DCstartedEvent) {
                break	
            }
         
            else {
                Start-Sleep -Seconds 5
            }
        }
         
        Write-Verbose -Message "Customization of VM $Server has started. Checking for Completed Status......."
        while ($True) {
            $DCvmEvents = Get-VIEvent -Entity $Server
            $DCSucceededEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationSucceeded" }
            $DCFailureEvent = $DCvmEvents | Where-Object { $_.GetType().Name -eq "CustomizationFailed" }
         
            if ($DCFailureEvent) {
                Write-Warning -Message "Customization of VM $Server failed"
                return $False	
            }
         
            if ($DCSucceededEvent) {
                break
            }
            Start-Sleep -Seconds 5
        }
        Write-Verbose -Message "Customization of VM $Server Completed Successfully!"
        
        Wait-Tools -VM $Server -TimeoutSeconds 300
        #endregion
    }
    
    end {
    }
}