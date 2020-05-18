<#
$tenantId = 'ab00cbf8-bf43-4547-9b09-7bcd55a043b3'
$passwd = ConvertTo-SecureString 'Assword1234!@' -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential('alibaba@alirazgmail.onmicrosoft.com', $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId
#>

$sp = New-AzADServicePrincipal -DisplayName ServicePrincipalNamelol3

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)



Import-Module Az.Resources # Imports the PSADPasswordCredential object
$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password='Assword1234!'}
$sp = New-AzAdServicePrincipal -DisplayName ServicePrincipalNamelol2 -PasswordCredential $credentials
$sp

(Get-AzContext).Tenant.Id

Get-AzADServicePrincipal