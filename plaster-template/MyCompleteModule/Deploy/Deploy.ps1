$source = ""
$destination_dev =""
$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"
$source  = 'C:\Users\Laurent.Lienhard\OneDrive - PoleHabitatStrasbourg\01-Devs\Powershell\' + $ModuleName 
$destination_dev = 'C:\Users\Laurent.Lienhard\OneDrive - PoleHabitatStrasbourg\WindowsPowerShell\Modules\' + $ModuleName


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

