$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"

if (!(Test-Connection -ComputerName SRV-FILE01 -ErrorAction SilentlyContinue) -or ($CredAdmin -eq $null)) {
    Write-Verbose "Impossible de publier le module : Chemin ou mot de passe inconnu..."
}
else {
    Write-Verbose "ping OK : Publication du module..."
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\srv-file01\sources$\Modules" -Credential $CredAdmin

    if ("PHSRepository" -notin ((Get-PSRepository).name) ) {
        Register-PSRepository -Name PHSRepository -SourceLocation "\\srv-file01\sources$\Modules" -InstallationPolicy Trusted -Verbose
    }


    Publish-Module -Name $ModuleName -Repository PHSRepository -Verbose

    Remove-PSDrive -Name Z -Force -Confirm:$false

}

