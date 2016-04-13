# We'll use a couple of variable here, fill these with your own values
$subscriptionId =  '' # Your SubscriptionId
$storageAccountName = '' # Storage account name where your custom image is and where your VM vhd will go
$sourceImageUri = '' # custom VM image blob uri, ex: 'https://vmcapturetest.blob.core.windows.net/system/Microsoft.Compute/Images/mytemplates/template-osDisk.187d9455-535b-48b4-b10d-8370ec9bad42.vhd'
# end of custom variables


# Authenticate against Azure and cache subscription data
Login-AzureRmAccount

# Switch subscription
Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Get the storage account
$storageAccount = Get-AzureRmStorageAccount | ? StorageAccountName -EQ $storageAccountName

if(-not $storageAccount) {  
    throw "Unable to find storage account '$storageAccountName'. Cannot continue."
}

# Enable verbose output and stop on error
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

# some reserved script variables
$resourceGroupName = $storageAccount.ResourceGroupName
$location = $storageAccount.Location

$adminUsername = 'VmAdministrator'
$adminPassword = '123!SomeUnSecurePassword!098'

$vmSuffix = Get-Random -Minimum 10000 -Maximum 99999
$vmName = 'VM{0}' -f $vmSuffix
$vmSize = 'Standard_D3'
$nicName = 'VM{0}-NIC' -f $vmSuffix
$ipName = 'VM{0}-IP' -f $vmSuffix
$domName = 'vm-from-customimage-powershell-{0}' -f $vmSuffix
$vnetName = $vmName


# Create the VNET
#Write-Verbose 'Creating Virtual Network'  
#$vnetDef = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix '10.0.0.0/16'
#Write-Verbose 'Adding subnet to Virtual Network'  
#$vnet = $vnetDef | Add-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet-1' -AddressPrefix '10.0.0.0/24' | Set-AzureRmVirtualNetwork

## Create the NIC
#Write-Verbose 'Creating Public IP'  
#$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Dynamic
#Write-Verbose 'Creating NIC'  
$nic = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $vnet.Subnets[0].Id 

# Specify the VM name and size
Write-Verbose 'Creating VM Config'  
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize 

# Specify local administrator account, and then add the NIC
$cred = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force) # you could use Get-Credential instead to get prompted
# NOTE: if you are deploying a Linux machine, replace the -Windows switch with a -Linux switch.
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk
$diskName = 'osdisk'
$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $diskName
# NOTE: if you are deploying a Linux machine, replace the -Windows switch with a -Linux switch.
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $sourceImageUri -Linux

Write-Verbose 'Creating VM...'  
$result = New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

if($result.Status -eq 'Succeeded') {  
    $result
    Write-Verbose ('VM named ''{0}'' is now ready, you can connect using username: {1} and password: {2}' -f $vmName, $adminUsername, $adminPassword)
} else {
    Write-Error 'Virtual machine was not created successfully.'
}
