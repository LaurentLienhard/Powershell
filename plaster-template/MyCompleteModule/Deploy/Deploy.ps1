$source = ""
$destination_dev =""
$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"
$source  = $env:OneDrive + '\Documents\01-DEV\VSTS\' + $ModuleName 
$destination_dev = $env:OneDrive + '\Documents\WindowsPowerShell\Modules\' + $ModuleName


Deploy ExampleDeployment {

    By FileSystem Scripts {

        FromSource $source
        To $destination_dev
        Tagged Dev
        WithOptions @{
            Mirror = $true
        }
    }
}
