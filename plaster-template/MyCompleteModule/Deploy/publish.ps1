$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"

New-PSDrive -Name Z -PSProvider FileSystem -Root "\\srv-file01\sources$\Modules" -Credential $CredAdmin

if ("PHSRepository" -notin ((Get-PSRepository).name) ) {
    Register-PSRepository -Name PHSRepository -SourceLocation "\\srv-file01\sources$\Modules" -InstallationPolicy Trusted -Verbose
}

<# if ("DEVREPO" -notin ((Get-PSRepository).name) ) {
    Register-PSRepository -Name DEVREPO -SourceLocation "C:\Users\laure\OneDrive - PoleHabitatStrasbourg\05-Dev\Repository" -ScriptSourceLocation "C:\Users\laure\OneDrive - PoleHabitatStrasbourg\05-Dev\Repository" -InstallationPolicy Trusted -Verbose
} #>


Publish-Module -Name $ModuleName -Repository PHSRepository -Verbose

Remove-PSDrive -Name Z -Force -Confirm:$false