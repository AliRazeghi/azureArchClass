﻿

######### Docuemntation #######################################################################
write-host "
########################################################################################################################
########################################################################################################################
########################################################################################################################
This process will begin recreating the back office for you.  It will go through:
-Creating a RG if needed
-Vnet If needed
-AGs
-Machines
-Make sure machines are joined to domain

Green reply = Good
Dark Red Reply = Bad
########################################################################################################################
########################################################################################################################
########################################################################################################################
" -ForegroundColor Cyan  







################################# Network Variables ##########################################
$vnetRGName = 'PacktLoadBalancer'
$vnetLoc = 'EastUS'
$vnetRGLoc = $vnetLoc  ## Company Policy: All VNets must be in the same location as the RG.
$vnetName = 'PacktLBVnet'
$vnetAddressPrefix = '172.16.0.0/16'
$subnetName = 'PacktLBBackendSubnet'

##################################### VM Variables #########################################
$VMRG = $vnetRGName ##Company policy dictates all machines be in the RG as their NIC
$VM1Name = 'PacktLBVM1'
$VM2Name = 'PacktLBVM2'
$VMLocation = 'EastUS'
#$VMPassword = 'Assword1234!'
#$VMcredential = New-Object System.Management.Automation.PSCredential ('oitadmin', $VMPassword)


################################### Availability Set Variables ###############################
$ASName = 'PacktLBAvailabilitySet'
$ASRGName = $vnetRGName #company policy requires AGs to be on the same VNet as the NIC
$ASLoc = $vnetLoc




#### Verify RG exists and create if not #####
$doesvnetRGExist = get-azresourcegroup | Where-Object {$_.ResourceGroupName -eq $($vnetRGName)}
write-verbose "doesvnetRGExist Variable Value: $($doesvnetRGExist)"
if ($doesvnetRGExist) {write-host "RG: $($doesvnetRGExist.ResourceGroupName) exists. Not creating RG $($DoesVNetRGExist.ResourceGroupName). Reusing Old one." -ForegroundColor Green} 
else {
write-host "creataing RG: $($vnetRGName) in $($vnetLoc)" -ForegroundColor Green
New-AzResourceGroup -Name $($vnetRGName) -Location $($vnetLoc)
}





#### Verify VNet exists and create if not #####
$doesNetworkExist = get-azvirtualnetwork | Where-Object {$_.Name -eq $($VnetName)} | select-object {$_.Name}
write-verbose "DoesNetworkExist Variable Value: $($doesNetworkExist)"
if ($doesNetworkExist) {write-host "VNet $($VnetName) exists. Not creating vnet. Reusing Old one." -ForegroundColor Green} 
else {
write-host "creating new Virtual Network $($vnetName)" -ForegroundColor Yellow
$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $($vnetRGName) `
  -Location $($vnetLoc) `
  -Name $($vnetName) `
  -AddressPrefix $($vnetAddressPrefix)
}



### Verify if subnet exists if not create. If so, tie to VM ###

## Does subnet exist on the vnet?
$doesSubnetExist = get-azvirtualnetwork -Name $($vnetName) | Get-AzVirtualNetworkSubnetConfig 
if ($doesSubnetExist) {write-host "subnet exists" -ForegroundColor Green}
else {
write-host "Subnet $($subnetName) does not exist.  Creating Subnet" -ForegroundColor Yellow
  $subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name $($subnetName) `
  -AddressPrefix 172.16.0.0/24 `
  -VirtualNetwork $virtualNetwork
  }

## Tying Subnet to PC ##
$subnetConfig | Set-AzVirtualNetwork | out-null


##Verify if Subnet was tied to the VNet
$doesSubnetExist = Get-AzVirtualNetwork -Name 'PacktLBVnet' -ResourceGroupName 'PacktLoadBalancer' | select-object {$_.Subnets.Name}
if ($doesSubnetExist) {write-host "Subnet tied to Vnet: $($vnetName)" -ForegroundColor Green}
else {write-host "subnet not found" -ForegroundColor DarkRed.}






############################ Availability Sets #######################################################


  $splat = @{
    Location = "$($vnetLoc)"
    Name = "$($ASName)"
    ResourceGroupName = "$($ASRGName)"
    Sku = "aligned"
    PlatformFaultDomainCount = 2
    PlatformUpdateDomainCount = 5
    }

## Does AG exist?
$doesAGExist = get-azavailabilityset -name 'PacktLBAvailabilitySet' | Select-Object {$_.Name}

if ($doesAGExist) {write-host "AS $($ASName) exists." -ForegroundColor Green}
else {write-host "Creating AS: $ASName" -ForegroundColor Yellow
New-AzAvailabilitySet @splat | out-null
}





########################################### VM CREATION ###############################################







## Does vm exist?
$doesVMExist = get-azvm -Name $($VM1Name) 
if ($doesVMExist) {write-host "VM Found named: $($VM1Name). Continuing" -foreground Green}
else
{
$Cred = get-credential
New-AzVm `
        -ResourceGroupName "$($VMRG)" `
        -Name "$($VM1Name)" `
        -Location "$($VMLocation)" `
        -VirtualNetworkName "$($vnetName)" `
        -SubnetName "$($subnetName)" `
        -SecurityGroupName "NSG" `
        -AvailabilitySetName "$($ASName)" `
        -Credential $cred 
}




## Does vm exist?
$doesVMExist = get-azvm -Name $($VM2Name) 
if ($doesVMExist) {write-host "VM Found named: $($VM2Name). Continuing" -foreground Green}
else
{
New-AzVm `
        -ResourceGroupName "$($VMRG)" `
        -Name "$($VM2Name)" `
        -Location "$($VMLocation)" `
        -VirtualNetworkName "$($vnetName)" `
        -SubnetName "$($subnetName)" `
        -SecurityGroupName "NSG" `
        -AvailabilitySetName "$($ASName)" `
        -Credential $cred 
}
