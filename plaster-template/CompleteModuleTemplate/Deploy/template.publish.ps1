if ("PHSRepository" -notin ((Get-PSRepository).name) ) {
    Register-PSRepository -Name PHSRepository -SourceLocation "\\srv-file01\sources$\Modules" -InstallationPolicy Trusted -Verbose
}

Publish-Module -Name $($PLASTER_PARAM_ModuleName) -Repository PHSRepository -Verbose