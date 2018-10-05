$Public = @(Get-ChildItem -Path $PSScriptRoot\Sources\Public\*.ps1  -ErrorAction SilentlyContinue) 
$Private = @(Get-ChildItem -Path $PSScriptRoot\Sources\Private\*.ps1 -ErrorAction SilentlyContinue) 
 
#Dot source the files 
Foreach ($import in @($Public + $Private)) { 
    TRY { 
        . $import.fullname 
    } 
    CATCH { 
        Write-Error -Message "Failed to import function $($import.fullname): $_" 
    } 
} 
 
# Export all the functions 
Export-ModuleMember -Function $Public.Basename -Alias *