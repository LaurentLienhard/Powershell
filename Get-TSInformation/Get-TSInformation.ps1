#region <Get-TSInformation>
<#
.SYNOPSIS
Retrieve information about TS properties

.DESCRIPTION
Retrieve information about TS properties of AD accounts

.EXAMPLE
Get-TSInformation

.NOTES
General notes
#>
Function Get-TSInformation {
    #Start Function Get-TSInformation
    [CmdletBinding()]
    [OutputType([Array])]
    param (
    )

    Begin {
        Write-Verbose ('[{0:O}] Starting {1}' -f (get-date), $myinvocation.mycommand)
        Write-Verbose ('[{0:O}] Creating an empty array' -f (get-date))
        $Result = @()

    }

    Process {
        $ADUsers = Get-ADUser -Filter { Enabled -eq $true } -Properties *
        foreach ($UserObject in $ADUsers) {
            If (!($Null -eq $UserObject.userParameters)) {
                $ADSIObject = [adsi]"LDAP://$($UserObject.DistinguishedName)"
                $Value = [PSCustomObject]@{}

                $Value | Add-Member -MemberType NoteProperty -Name "Name" -Value $UserObject.SamAccountName
                $Value | Add-Member -MemberType NoteProperty -Name "TerminalServicesallowLogon" -Value ($ADSIObject.PSBase.invokeget("allowLogon"))
                $Value | Add-Member -MemberType NoteProperty -Name "TerminalServicesHomeDirectory" -Value ($ADSIObject.PSBase.invokeget("TerminalServicesHomeDirectory"))
                $Value | Add-Member -MemberType NoteProperty -Name "TerminalServicesHomeDrive" -Value ($ADSIObject.PSBase.invokeget("TerminalServicesHomeDrive"))
                $Value | Add-Member -MemberType NoteProperty -Name "TerminalServicesProfilePath" -Value ($ADSIObject.PSBase.invokeget("TerminalServicesProfilePath"))
                $result += $Value
            }

        }
    }

    End {
        Write-Verbose ('[{0:O}] Ending {1}' -f (get-date), $myinvocation.mycommand)
        Return $Result
    }
}	 #End Function Get-TSInformation
#endregion <Get-TSInformation>


Get-TSInformation