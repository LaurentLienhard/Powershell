#Author: Matt Bungard / bungard at g-mail d com

#

#Pull bits from various sources, if you've been exluded let me know and I'll cite accordingly

#http://stackoverflow.com/questions/26737239/powershell-add-a-new-document-to-exisitng-word-file-with-page-number-of-2



## -- Settings --

$fileNamePattern = ".*de bail.*(0\d{9})"

$pageLength = 1



$inputFile = "C:\temp\18070230.doc"

$outputPath = "c:\temp\outputDir\" #End the path with a slash



## -- End Settings

$word = New-Object -ComObject word.application

$word.Visible = $False



$doc = $word.Documents.Open($inputFile)

$pages = $doc.ComputeStatistics([Microsoft.Office.Interop.Word.WdStatistic]::wdStatisticPages)



$rngPage = $doc.Range()



for($i=1;$i -le $pages; $i+=$pageLength)

{

    [Void]$word.Selection.GoTo([Microsoft.Office.Interop.Word.WdGoToItem]::wdGoToPage,

                         [Microsoft.Office.Interop.Word.WdGoToDirection]::wdGoToAbsolute,

                         $i #Starting Page

                         )

        $rngPage.Start = $word.Selection.Start



    [Void]$word.Selection.GoTo([Microsoft.Office.Interop.Word.WdGoToItem]::wdGoToPage,

                         [Microsoft.Office.Interop.Word.WdGoToDirection]::wdGoToAbsolute,

                         $i+$pageLength #Next page Number

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

    $word.Selection.EndKey(6,0) #Move to the end of the file

    $word.Selection.TypeBackspace() #Seems to grab an extra section/page break

    $word.Selection.Delete() #Now we have our doc down to size



    #Get Name

    $regex = [Regex]::Match($rngPage.Text, $fileNamePattern)

    if($regex.Success)

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

[gc]::collect() 
[gc]::WaitForPendingFinalizers()