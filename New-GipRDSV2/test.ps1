Import-Module PSManageRDServer
Import-Module VMware.VimAutomation.Core

function Test-PassageSessionVI {
    [CmdletBinding()]
    param (
     
    )
    
    begin {
    }
    
    process {
        $SessionID2 = Connect-VIServer -Server $global:DefaultVIServer -Session $global:DefaultVIServer.SessionId -Force
    }
    
    end {
    }
}

$session = Connect-VIServer -Server srv-vcgip -Credential (Get-Credential) -Force
Test-PassageSessionVI
Disconnect-VIServer -Server srv-vcgip
  