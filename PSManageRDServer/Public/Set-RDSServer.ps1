function Set-RDSServer {
    <#
.SYNOPSIS
    .
.DESCRIPTION
    This script allows you to modify the attributes of an RDS server. 
    Add the server to a collection, remove the server from a collection ....

.PARAMETER Server
    This parameter defines the name of the RDS server that will be processed.

.PARAMETER AddToCollection
    This parameter is set if the server will be added to a collection.

.PARAMETER RemoveFromCollection
    This parameter is set if the server will be removed from a collection.

.PARAMETER Collection
    This parameter defines the name of the collection from which the server will be added or deleted.

.PARAMETER ConnectionBroker
    This parameter defines the name of the collection management server.

.PARAMETER Cred
    This parameter defines the credentials for connecting to the virtual center server.

.PARAMETER VCenter
    This parameter defines the name of the Virtual Center server.

.EXAMPLE
    C:\PS> Set-RDSServer -Server SERVER -AddTocollection -Collection TEST -ConnectionBroker BROKER
    
    This command will add the server rds "SERVER" in the collection "TEST"

    C:\PS> Set-RDSServer -Server SERVER -RemoveFromcollection -Collection TEST -ConnectionBroker BROKER

    This command will remove the server rds "SERVER" from the collection "TEST"

.NOTES
    Author: LIENHARD Laurent
    Date  : February 28, 2018  
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$Server,
        [Parameter(Mandatory = $false)][switch]$AddToCollection,
        [Parameter(Mandatory = $false)][switch]$RemoveFromCollection,
        [Parameter(Mandatory = $false)][string]$Collection,
        [Parameter(Mandatory = $true)][string]$ConnectionBroker,
        [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]
        [Parameter(Mandatory = $true)]$Cred = [System.Management.Automation.PSCredential]::Empty,
        [Parameter(Mandatory = $true)][string]$VCenter
    )
    
    begin {
        Clear-Host

        $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand
        write-verbose "[$Scriptname] - BEGIN PROCESS" 

        if ($AddToCollection -and $RemoveFromCollection) {
            Write-Warning "Impossible to put the 2 choices. Please choose AddToCollection or RemovefromCollection"
            Break
        }

        if (($AddToCollection -or $RemoveFromCollection) -and !($Collection) ) {
            Write-Warning "AddToCollection or RemovefromCollection must be associated with a collection name"
            break
        }

        Import-Module -Name VMware.VimAutomation.Core -Verbose:$false
    }
    
    process {

        try {
            Connect-VIServer -Server $VCenter -Credential $cred -Debug:$false
        }
        catch {
            Write-Warning "[$Scriptname] - Erreur de connexion au VCenter fin du script"
            Break
        }

        $serverFull = $Server + '.' + $env:USERDNSDOMAIN
        $ConnectionBrokerFull = $ConnectionBroker + '.' + $env:USERDNSDOMAIN

        if ($AddToCollection) {
            write-verbose "[$Scriptname] - Adding the $Server server in the $Collection collection..."
            $AddToCollectionScript = 'Import-Module RemoteDesktop
            Add-RDServer -Server ' + $serverFull + ' -Role RDS-RD-SERVER -ConnectionBroker '+$ConnectionBrokerFull+'
            Add-RDSessionHost -SessionHost ' + $serverFull + ' -ConnectionBroker '+$ConnectionBrokerFull+' -CollectionName "'+$Collection+'"
            Set-RDSessionHost -SessionHost ' + $serverFull + ' -NewConnectionAllowed No -ConnectionBroker '+$ConnectionBrokerFull
            Write-Debug "[$Scriptname] - $AddToCollectionScript"
            Invoke-VMScript -ScriptText $AddToCollectionScript -VM $Server -GuestCredential $cred
        }

        if ($RemoveFromCollection) {
            write-verbose "[$Scriptname] - removing the $Server server from the $Collection collection..."
            $RemoveFromCollectionScript = 'Import-Module RemoteDesktop
            Remove-RDSessionHost -SessionHost '+$serverFull+' -ConnectionBroker '+$ConnectionBrokerFull+' -Force
            Remove-RDServer -Server '+$serverFull+' -Role RDS-RD-SERVER -ConnectionBroker '+$ConnectionBrokerFull+' -Force'
            Write-Debug "[$Scriptname] - $RemoveFromCollectionScript"
            Invoke-VMScript -ScriptText $RemoveFromCollectionScript -VM $Server -GuestCredential $cred
        }

    }
    
    end {
        Disconnect-VIServer -Server $VCenter -Confirm:$false -Debug:$false
    }
}