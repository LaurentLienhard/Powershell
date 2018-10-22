$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Sources\Public\*.ps1  -ErrorAction SilentlyContinue | Select-object -Expand FullName) 
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Sources\Private\*.ps1 -ErrorAction SilentlyContinue | Select-Object -Expand FullName) 
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Sources\Class\*.ps1 -ErrorAction SilentlyContinue | Select-Object -Expand FullName) 
 
 #Dot source the files 
Foreach ($import in @($PublicFunctions + $PrivateFunctions + $Classes)) { 
    TRY { 
        . $import
    } 
    CATCH { 
        Write-Error -Message "Failed to import function $($import): $_" 
    } 
} 