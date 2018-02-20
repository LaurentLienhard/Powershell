<#
.SYNOPSIS
    .
.DESCRIPTION
    This script will query all domain controllers and return a list of 
    computers where the user has logged on to. This query is optimized
    and will run against event viewers of all Domain Controllers.

.PARAMETER User
    This parameter will define the user account which you want to run query
    against. Make sure the name is correct and enter the SAMACCOUNTNAME.

.PARAMETER Days
    This parameter defined the time threshold of query. If you enter 10,
    the list of logons will be created based on last 10 days.

.EXAMPLE
    C:\PS> Get-UserLastLogon -User m.tehrani
    
    This command will get list of computers where (m.tehrani) has logged on to
    in last 90 days.

    C:\PS> Get-UserLastLogon -User m.tehrani -Days 5

    This command will get list of computers where (m.tehrani) has logged on to
    in last 5 days.

.NOTES
    Author: Mahdi Tehrani
    Date  : March 18, 2017   
#>


clear-host
Import-Module activedirectory -ErrorAction stop

function Get-UserLastLogon {
    param (
     [Parameter(Mandatory = $true)]
     [string]$User,

     [Parameter(Mandatory = $false)]
     [array]$Server = @((Get-ADDomainController -Filter *).name) ,

     [Parameter(Mandatory = $false)]
     [array]$Days = 90

           )
begin{
    ## Variables ##
    [Array]$Table         = $null
    $DomainControllers    = $Server
    $AllDomainControllers = @((Get-ADDomainController -Filter *).name)
    [array]$ExclusionList = @($User,'krbtgt')
    $DCCount              = $DomainControllers.count
    $UPN                  = ((get-addomain).dnsroot).toupper()
    $DateFilter           = "-"+$days
    $DateThen             = (((Get-Date).AddDays($DateFilter)).ToString("yyyy-MM-dd"))+"T20:30:00.000Z"
    $DateNow              = (Get-Date -Format yyyy-MM-dd)+"T20:30:00.999Z"
    $ForestRoot           = ((Get-ADForest).rootdomain).toupper()
    $Counter              = 0

    [xml]$FilterXML = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4769)
	and TimeCreated[@SystemTime&gt;='$DateThen' 
	and @SystemTime&lt;='$DateNow']]] 
	and*[EventData[Data[@Name='TargetUserName'] and (Data='$User@$UPN')]]</Select>
  </Query>
</QueryList>
"@

}

process{   

try
{
$COND = Get-ADUser $User 
Foreach($DCName in $DomainControllers)
{
    $Events       = $null
    $CounterEvent = 1
    $Counter++
    $Domain       = (Get-ADDomain).dnsroot
    $UPNLength    = $Domain.length + 1 
    Write-Progress -Activity "Filtering logs on $DCName ($Counter/$DCCount)" -Status "Finding events for ($User) with ($days) days of timespan" -percentComplete ($Counter/$DCCount*100) -Id 1
    
    try
    {
        $Events     = Get-WinEvent -FilterXml $FilterXML -ComputerName $DCName -ErrorAction stop
        $CountEvent = $Events.count
    }
    
    catch
    {
        Write-Warning "$_ (Occured on $DCName)"
        continue
    }
    
    foreach($Event in $Events)
    {
            Write-Progress -Activity "Please Wait" -Status "Processing Events $CounterEvent\$CountEvent" -percentComplete (($CounterEvent/$CountEvent)*100) -Id 2 -ParentId 1
            $UserName   = $Event.Properties[0].Value
            $UserLength = $UserName.length
            $UserName   = $UserName.substring(0,$UserLength-$UPNLength)
            $Location   = $Event.Properties[2].Value 
            $Location   = $Location.trim("$")
            $Time       = ($Event.TimeCreated).ToString($G)
            $Domain     = $Event.Properties[1].Value
            $CounterEvent++
            
            if ($UserName -eq $User)
            { 
             
                $obj      = New-Object -TypeName PSObject -Property @{
                            "User"     =    $UserName
                            "Location" =    $Location
                            "Time"     =    $Time
                            "Domain"   =    $Domain 
                            "DC"       =    $DCName
                                                           }
                        $Table += $obj
            }
        
        }  
    Write-Progress -Activity "Please Wait" -Completed
}
}
catch
{
    Write-Host "User $user does not exist!" -ForegroundColor Yellow -BackgroundColor Red -ErrorAction stop
}
}

end{
$Table = $Table | Where-Object {($_.Location -notin $AllDomainControllers) -and ($_.Location -ne $ForestRoot) -and ($_.Location -notin $ExclusionList)} 
$Table | Sort Time | FT Time,User,Location,Domain,DC -AutoSize 
}
}