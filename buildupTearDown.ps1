

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
Yellow reply = Good, but an action is needed and is being performed.
Dark Red Reply = Bad
########################################################################################################################
########################################################################################################################
########################################################################################################################
" -ForegroundColor Cyan  


## Changes: Added subnetaddressprefix variable. Basic clean up. 
########################################################################################






################################# Network Variables ##########################################
$vnetRGName = 'PacktLoadBalancer'
$vnetLoc = 'EastUS'
$vnetRGLoc = $vnetLoc  ## Company Policy: All VNets must be in the same location as the RG.
$vnetName = 'PacktLBVnet'
$vnetAddressPrefix = '172.16.0.0/16'
$subnetName = 'PacktLBBackendSubnet'
$subnetAddressPrefix = '172.16.0.0/24'
###### Load Balancers
$LBName = $vnetRGName
$LBLocation = $vnetLoc
$LBRG  = $vnetRGName
$LBVN = $vnetName
$LBSubnet = $subnetName
$PrivIPSpace = '172.16.0.1'
$LBfrontendIP = '172.16.0.7'
##Probes for LBs
$LBProbeName = 'PacktHealthProbe'
$LBProbePort = '80'
$LBProbePath =  '/.'
$LBProbebProtocol = 'HTTP'
$LBProbeInterval = '15'        ##Number of seconds between attempts
$LBProbeCount = '2'  ##How many times must it fail to be unhealthy?

##################################### VM Variables #########################################
$VMRG = $vnetRGName ##Company policy dictates all machines be in the RG as their NIC
$VM1Name = 'PacktLBVM1'
$VM2Name = 'PacktLBVM2'
$VM3Name = 'PacktLBVMTest'
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
New-AzResourceGroup -Name $($vnetRGName) -Location $($vnetLoc) | out-null
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
  -AddressPrefix $($subnetAddressPrefix ) `
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
write-host "vm: $($VM1Name) does not exist. Creating now." -ForegroundColor Yellow
#$Cred = get-credential          #UNCOMMENT!
New-AzVm `
        -ResourceGroupName "$($VMRG)" `
        -Name "$($VM1Name)" `
        -Location "$($VMLocation)" `
        -VirtualNetworkName "$($vnetName)" `
        -SubnetName "$($subnetName)" `
        -SecurityGroupName "NSG" `
        -AvailabilitySetName "$($ASName)" `
        -Credential $cred | out-null
}




## Does vm exist?
$doesVMExist = get-azvm -Name $($VM2Name) 
if ($doesVMExist) {write-host "VM Found named: $($VM2Name). Continuing" -foreground Green}
else
{
write-host "vm: $($VM2Name) does not exist. Creating now." -ForegroundColor Yellow
New-AzVm `
        -ResourceGroupName "$($VMRG)" `
        -Name "$($VM2Name)" `
        -Location "$($VMLocation)" `
        -VirtualNetworkName "$($vnetName)" `
        -SubnetName "$($subnetName)" `
        -SecurityGroupName "NSG" `
        -AvailabilitySetName "$($ASName)" `
        -Credential $cred | out-null
} 



## Does vm exist?
$doesVMExist = get-azvm -Name $($VM3Name) 
if ($doesVMExist) {write-host "VM Found named: $($VM3Name). Continuing" -foreground Green}
else
{
write-host "vm: $($VM3Name) does not exist. Creating now." -ForegroundColor Yellow
New-AzVm `
        -ResourceGroupName "$($VMRG)" `
        -Name "$($VM3Name)" `
        -Location "$($VMLocation)" `
        -VirtualNetworkName "$($vnetName)" `
        -SubnetName "$($subnetName)" `
        -SecurityGroupName "NSG" `
        -AvailabilitySetName "$($ASName)" `
        -Credential $cred | out-null
} 





### Load Balancers for VMs
### Load Balancers need their configurations done first, then tied to the LB, similar to networking in a VM.
<#
xx Load Balancer itself
Backend Pool
xx Health Checks
xx LB Rules

add ips to the backend pools or tie to a nic of our 2 machines.
#>

if ($doesLBExist){write-host "LB $($LBName) exists. Removing." -ForegroundColor Green; Remove-AzLoadBalancer -Name PacktLoadBalancer -ResourceGroupName PacktLoadBalancer -force}


##Configure backend pool
$LBBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "PacktLBBackendPool" 

##Load Balancer Probe
$LoadBalancerProbe = New-AzLoadBalancerProbeConfig -Name $($LBProbeName) -Protocol $($LBProbebProtocol) -Port $LBProbePort -RequestPath $($LBProbePath) -IntervalInSeconds $($LBProbeInterval)  -ProbeCount $($LBProbeCount) 


##Load Balancer Rules
$LBRules = New-AzLoadBalancerRuleConfig -Name PacktLoadBalancerRule -BackendAddressPool PacktLBBackendPool -BackendPort 80 -FrontendIpConfiguration LoadBalancerFrontEnd -FrontendPort 80 -IdleTimeoutInMinutes 4 -Probe PacktHealthProbbe -Protocol TCP





## Actual work.
$doesLBExist = Get-AzLoadBalancer -Name $($LBName) -ResourceGroupName $($LBRG) -ErrorAction SilentlyContinue  #| select-object {$_.Name} | out-null   ##Will have to look into why this requires a select-object. 
if ($doesLBExist){write-host "LB $($LBName) exists." -ForegroundColor Green}
else {write-host "creating LB $($LBName)" -ForegroundColor Yellow; New-AzLoadBalancer -ResourceGroupName $($LBRG) -Name $($LBName) -Location $($LBLocation) -Sku "Basic" -BackendAddressPool $LBBackendPool -Probe $LoadBalancerProbe -LoadBalancingRule $LBRules} #  | out-null}
#Remove-AzLoadBalancer -ResourceGroupName $LBRG -Name $LBName -force -verbose


    $Subnet = Get-AzVirtualNetwork -Name "PacktLBVnet" -ResourceGroupName "PacktLoadBalancer" | Get-AzVirtualNetworkSubnetConfig -Name "PacktLBBackendSubnet"
    $slb = Get-AzLoadBalancer -Name "PacktLoadBalancer" -ResourceGroupName "PacktLoadBalancer"
    $slb | Add-AzLoadBalancerFrontendIpConfig -Name "NewFrontend" -Subnet $Subnet -PrivateIpAddress '172.16.0.7'
    $slb | set-azloadbalancer  ##Wont set otherwise.




#Set-AzLoadBalancerFrontendIpConfig -LoadBalancer 'PacktLoadBalancer' -Name 'PacktLoadBalancerConfig' -Subnet PacktLBBackendSubnet -PrivateIpAddress 172.16.0.7
#$frontend = New-AzLoadBalancerFrontendIpConfig -Name "MyFrontEnd" -PublicIpAddress $publicip
    




