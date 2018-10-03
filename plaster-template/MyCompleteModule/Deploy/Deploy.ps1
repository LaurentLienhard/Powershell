$source = ""
$destination_dev =""
$ModuleName = "<%= $PLASTER_PARAM_ModuleName %>"
$source  = $DevPath + '\' + $ModuleName 
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

