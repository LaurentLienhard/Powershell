function Convert-Docx2Pdf {
    
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)][string]$FileNamePattern = ".*de bail.*(0\d{9})",
    [Parameter(Mandatory = $False)][string]$pageLength = 1,
    [Parameter(Mandatory = $true)][string]$InputFile ,
    [Parameter(Mandatory = $False)][string]$outputPath = $env:temp + "\Outputdir\"
)
    
BEGIN {
if (Test-Path $outputPath) {
    Remove-Item -Path $outputPath -Recurse -Force -Confirm:$false
}
New-Item -Path $outputPath -ItemType Directory -Force -Confirm:$false
}

PROCESS {
$word = New-Object -ComObject word.application

$word.Visible = $False



$doc = $word.Documents.Open($inputFile)

$pages = $doc.ComputeStatistics([Microsoft.Office.Interop.Word.WdStatistic]::wdStatisticPages)



$rngPage = $doc.Range()



for ($i = 1; $i -le $pages; $i += $pageLength)
{

    [Void]$word.Selection.GoTo([Microsoft.Office.Interop.Word.WdGoToItem]::wdGoToPage,

        [Microsoft.Office.Interop.Word.WdGoToDirection]::wdGoToAbsolute,

        $i #Starting Page

    )

    $rngPage.Start = $word.Selection.Start



    [Void]$word.Selection.GoTo([Microsoft.Office.Interop.Word.WdGoToItem]::wdGoToPage,

        [Microsoft.Office.Interop.Word.WdGoToDirection]::wdGoToAbsolute,

        $i + $pageLength #Next page Number

    )

    $rngPage.End = $word.Selection.Start



    $marginTop = $word.Selection.PageSetup.TopMargin

    $marginBottom = $word.Selection.PageSetup.BottomMargin

    $marginLeft = $word.Selection.PageSetup.LeftMargin

    $marginRight = $word.Selection.PageSetup.RightMargin


    $rngPage.Copy()

    $newDoc = $word.Documents.Add()


    $word.Selection.PageSetup.TopMargin = $marginTop 

    $word.Selection.PageSetup.BottomMargin = $marginBottom

    $word.Selection.PageSetup.LeftMargin = $marginLeft

    $word.Selection.PageSetup.RightMargin = $marginRight



    $word.Selection.Paste() # Now we have our new page on a new doc

    $word.Selection.EndKey(6, 0) #Move to the end of the file

    $word.Selection.TypeBackspace() #Seems to grab an extra section/page break

    $word.Selection.Delete() #Now we have our doc down to size



    #Get Name

    $regex = [Regex]::Match($rngPage.Text, $fileNamePattern)

    if ($regex.Success)
    {

        $id = $regex.Groups[1].Value

    }

    else
    {

        $id = "patternNotFound" + $i 

    }



    #$path = $outputPath + $id + ".docx"
    $path = $outputPath + $id + ".pdf"

    $newDoc.saveas([ref] $path, 17) 

    $newDoc.close([ref]$False) 
}
}

END {
[gc]::collect() 
[gc]::WaitForPendingFinalizers()
}
}
