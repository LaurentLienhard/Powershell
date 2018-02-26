Import-Module -Name VMware.VimAutomation.Core 
$cred = Get-Credential -Message "Compte Admin VI"
Connect-VIServer -Server srv-vcgip -Credential $cred

#Variable
$VM_NAME = "SRV-RDS22" 
$IP = "10.3.50.24"

#Constante
$datastore = (Get-Datastore | Sort-Object -Property FreeSpaceGB -Descending | Select-Object -First 1).name
$OSCusSpec = Get-OSCustomizationSpec -Name 'Custom_RDSGIP_V1' | New-OSCustomizationSpec -Name 'temp1' -Type NonPersistent
$VMTemplate = Get-Template -Name 'Template_RDSGIP_V3'
$VMHost = Get-Cluster | Get-VMHost | Get-Random

Get-OSCustomizationSpec $OSCusSpec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $IP -SubnetMask '255.255.255.0' -DefaultGateway '10.3.50.254' -Dns '10.1.50.10'

New-VM -Name $VM_NAME -Template $VMTemplate -OSCustomizationSpec $OSCusSpec -VMHost $VMHost -Datastore $datastore


Start-VM -VM $VM_Name


# We first verify that the guest customization has finished on on the new DC VM by using the below loops to look for the relevant events within vCenter. 
 
Write-Verbose -Message "Verifying that Customization for VM $VM_Name  has started ..." -Verbose
	while($True)
	{
		$DCvmEvents = Get-VIEvent -Entity $VM_Name
		$DCstartedEvent = $DCvmEvents | Where { $_.GetType().Name -eq "CustomizationStartedEvent" }
 
		if ($DCstartedEvent)
		{
			break	
		}
 
		else 	
		{
			Start-Sleep -Seconds 5
		}
	}
 
Write-Verbose -Message "Customization of VM $VM_Name has started. Checking for Completed Status......." -Verbose
	while($True)
	{
		$DCvmEvents = Get-VIEvent -Entity $VM_Name 
		$DCSucceededEvent = $DCvmEvents | Where { $_.GetType().Name -eq "CustomizationSucceeded" }
        $DCFailureEvent = $DCvmEvents | Where { $_.GetType().Name -eq "CustomizationFailed" }
 
		if ($DCFailureEvent)
		{
			Write-Warning -Message "Customization of VM $VM_Name failed" -Verbose
            return $False	
		}
 
		if ($DCSucceededEvent) 	
		{
            break
		}
        Start-Sleep -Seconds 5
	}
Write-Verbose -Message "Customization of VM $VM_Name Completed Successfully!" -Verbose