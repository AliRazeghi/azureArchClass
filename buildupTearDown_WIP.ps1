



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

if ($doesLBExist){write-host "LB $($LBName) exists. Removing." -ForegroundColor Green; Remove-AzLoadBalancer -Name PacktLoadBalancer -ResourceGroupName PacktLoadBalancer -force}


##Configure backend pool
$LBBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "PacktLBBackendPool" 
$LBBackendPool

##Load Balancer Probe
$LoadBalancerProbe = New-AzLoadBalancerProbeConfig -Name $($LBProbeName) -Protocol $($LBProbebProtocol) -Port $LBProbePort -RequestPath $($LBProbePath) -IntervalInSeconds $($LBProbeInterval)  -ProbeCount $($LBProbeCount) 


##Load Balancer Rules
$LBRules = New-AzLoadBalancerRuleConfig -Name PacktLoadBalancerRule -BackendAddressPool PacktLBBackendPool -BackendPort 80 -FrontendIpConfiguration LoadBalancerFrontEnd -FrontendPort 80 -IdleTimeoutInMinutes 4 -Probe PacktHealthProbbe -Protocol TCP





    $Subnet = Get-AzVirtualNetwork -Name "PacktLBVnet" -ResourceGroupName "PacktLoadBalancer" | Get-AzVirtualNetworkSubnetConfig -Name "PacktLBBackendSubnet"
    $slb = Get-AzLoadBalancer -Name "PacktLoadBalancer" -ResourceGroupName "PacktLoadBalancer"
    $slb | Add-AzLoadBalancerFrontendIpConfig -Name "NewFrontend" -Subnet $Subnet -PrivateIpAddress '172.16.0.7'
    $slb | set-azloadbalancer  ##Wont set otherwise.






## Actual work.
$doesLBExist = Get-AzLoadBalancer -Name $($LBName) -ResourceGroupName $($LBRG) -ErrorAction SilentlyContinue  #| select-object {$_.Name} | out-null   ##Will have to look into why this requires a select-object. 
if ($doesLBExist){write-host "LB $($LBName) exists." -ForegroundColor Green}
else {write-host "creating LB $($LBName)" -ForegroundColor Yellow; New-AzLoadBalancer -ResourceGroupName $($LBRG) -Name $($LBName) -Location $($LBLocation) -Sku "Basic"} #  | out-null}
#Remove-AzLoadBalancer -ResourceGroupName $LBRG -Name $LBName -force -verbose




$slb3 = Get-AzLoadBalancer -Name $($LBName) -ResourceGroupName $($LBRG)
$slb3 | Add-AzLoadBalancerProbeConfig -Name $($LBProbeName) -Protocol $($LBProbebProtocol) -Port $LBProbePort -RequestPath $($LBProbePath) -IntervalInSeconds $($LBProbeInterval)  -ProbeCount $($LBProbeCount) | Set-AzLoadBalancer




 $slb = Get-AzLoadBalancer -Name "PacktLoadBalancer" -ResourceGroupName "PacktLoadBalancer"
 $slb | Add-AzLoadBalancerRuleConfig -Name PacktLoadBalancerRule -BackendAddressPool PacktLBBackendPool -BackendPort 80 -FrontendIpConfiguration LoadBalancerFrontEnd -FrontendPort 80 -IdleTimeoutInMinutes 4 -Probe PacktHealthProbbe -Protocol TCP | Set-AzLoadBalancer


#Set-AzLoadBalancerFrontendIpConfig -LoadBalancer 'PacktLoadBalancer' -Name 'PacktLoadBalancerConfig' -Subnet PacktLBBackendSubnet -PrivateIpAddress 172.16.0.7
#$frontend = New-AzLoadBalancerFrontendIpConfig -Name "MyFrontEnd" -PublicIpAddress $publicip
    




    $LBBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "PacktLBBackendPool" 
    Add-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer 'PacktLoadBalancer' -Name 'PacktLBBackendPool' 


    Get-AzLoadBalancer -Name "PacktLoadBalancer" -ResourceGroupName "PacktLoadBalancer" | Add-AzLoadBalancerBackendAddressPoolConfig -Name "PacktLBBackendPool" | Set-AzLoadBalancer