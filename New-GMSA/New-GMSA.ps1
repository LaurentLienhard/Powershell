Function New-GMSA {
    <#
.SYNOPSIS
    Creation d'un groupe de service managé
.DESCRIPTION
    Creation d'un groupe de service managé
.EXAMPLE
    New-GMSA -gMSAName gMSA-OraService -gMSAHostNames "SRV-XXX1"
.EXAMPLE
    New-GMSA -gMSAName gMSA-OraService -gMSAHostNames "SRV-XXX1,SRV-XXX2"
#>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)][string]$gMSAName,
        [Parameter(Mandatory = $true)][string[]]$gMSAHostNames
    )
    begin {
        # Define this variable a the beginning ans use in write-verbose '[$Scriptname] - '
        $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand
        
        write-verbose "[$Scriptname] - BEGIN PROCESS" 
        
        write-verbose "[$Scriptname] - Test de la présence des outils RSAT AD..."
        if (!(Get-WindowsFeature -Name "RSAT-AD-PowerShell").Installed) {
            Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeManagementTools
        }

        write-verbose "[$Scriptname] - Import du module ActiveDirectory..."
        Import-module ActiveDirectory
    }
    process {
        write-verbose "[$Scriptname] - Create the KDS Root Key..."
        Add-KDSRootKey -EffectiveTime (Get-Date).AddHours(-10)

        
        $gMSAHostsGroupName = "$($gMSAName)_HostsGroup"
        if (!(Get-ADGroup -Identity $gMSAHostsGroupName)) {
            write-verbose "[$Scriptname] - Creation du groupe AD pour les serveurs..."
            $gMSAHostsGroup = New-ADGroup -Name $gMSAHostsGroupName -GroupScope Global -PassThru -Path "OU=Serveurs,OU=Groupes,OU=GIP,OU=PHS,DC=netintra,DC=local"
        }
        else {
            write-verbose "[$Scriptname] - Le groupe AD pour les serveurs existe deja..."
            $gMSAHostsGroup = Get-ADGroup -Identity $gMSAHostsGroupName
        }
        
        write-verbose "[$Scriptname] - Ajout des serveurs dans le groupe $($gMSAHostsGroupName) ..."
        $gMSAHostNames | ForEach-Object { Get-ADComputer -Identity $_ } -ErrorAction Continue | ForEach-Object { Add-ADGroupMember -Identity $gMSAHostsGroupName -Members $_ } -ErrorAction Continue

        
        
        if (!(Get-ADServiceAccount -Identity $gMSAName)) {
            write-verbose "[$Scriptname] - Create and Configure the gMSA..."
            [string]$gMSAFQDN = $gMSAHostsGroupName + ".netintra.local"
            New-ADServiceAccount -Name $gMSAName -DNSHostName $gMSAFQDN -PrincipalsAllowedToRetrieveManagedPassword $gMSAHostsGroup
        }
        else {
            Write-Warning "Le compte $($gMSAName) existe deja aucune action n'est effectue"
        }
    }
}