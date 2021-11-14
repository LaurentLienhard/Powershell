#region <New-PinCode>	
#TODO Update help section
Function New-PinCode	
{	 #Start Function New-PinCode
<#
.SYNOPSIS
Generate random pin code

.DESCRIPTION
generate unique random pin code between 2 values

.PARAMETER Number
Number of Pin code that you want

.PARAMETER Minimum
Minimum value for pin code

.PARAMETER Maximum
Maximum value for pin code

.EXAMPLE
New-PinCode -Minimum 1000 -Maximum 9999
9499

.EXAMPLE
New-PinCode -Minimum 1000 -Maximum 9999 -Number 5 
5295
6339
7082
5851
3194

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        [System.Int32]$Number = 1,
        [System.Int32]$Minimum,
        [System.Int32]$Maximum
    )

    Begin {
    Write-Verbose ('[{0:O}] Starting {1}' -f (get-date),$myinvocation.mycommand)
    $NumberOfGeneratePin = 1
    $Result = @()
    }

    Process {
        if ($Number -gt ($Maximum - $Minimum)) {
            Write-Error ('[{0:O}] Impossible to generate {1} unique PIN between {2} and {3}' -f (get-date),$Number,$Minimum,$Maximum)
        } else {
            while ($NumberOfGeneratePin -le $Number) {
                do {
                    $pin = '{0:D4}' -f (Get-Random -Maximum $Maximum -Minimum $Minimum )
                } while ($Pin -in $Result)
                $Result += $PIN
                $NumberOfGeneratePin += 1
            }
        }
    }
        
    End {
        Write-Verbose ('[{0:O}] Ending {1}' -f (get-date),$myinvocation.mycommand)
        return $Result
    }
}	 #End Function New-PinCode
#endregion <New-PinCode>
