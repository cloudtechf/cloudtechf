<#
.SYNOPSIS
    Enable-AzAcceleratedNetworkingMultipleVMs is a sample script that can help Azure Administrators to enable Accelerated Networking in multiple VM's in the same Resource Group
.DESCRIPTION
    This script will helps to enable the Accelerated Networking in multilple VM's under the same Resource Group, it will verify if the feature is enabled and if the VM does supports.
.PARAMETER SubscriptionId
    You need to inform the subscriptionId, in case your tenant has more than one subscription.
.PARAMETER TenantId
    You need to inform the tenantId, in case your user has access to more than one Tenant.
.PARAMETER ResourceGroupName    
    Resource Group where you store your VM's
.Example 
    .\Enable-AzAcceleratedNicMultipleVMs.ps1 -subscriptionId <SubscriptionId> -tenantId <TenantId> -resourceGroupName <ResourceGroupName>
.NOTES
    Version: 1
    Date: 01/24/2022
#>

param(
    [Parameter(Mandatory=$True)]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$True)]
    [string]$tenantId,
    
    [Parameter(Mandatory=$True)]
    [string]$resourceGroupName
)

if($null -eq $subscriptionId -or $null -eq $tenantId -or $null -eq $resourceGroupName){
    Write-Error "Please, Execute the Script again"
}else{
    #Connecting on Azure Tenant ...
    Write-Host "Login into the Azure Account" -ForegroundColor Blue
    $null = az login --tenant $tenantId --verbose

    #Selecting Subscription
    Write-Host "Selecting the Subscription..." -ForegroundColor Blue
    az account set --subscription $subscriptionId --verbose
}
#Variables Section
$enableAcceleratedNic = $True #The Value Should be True or False
#Getting list of VM's under the RG
$azureVM = az vm list -g $resourceGroupName | ConvertFrom-Json
foreach($vm in $azureVM){
    #Getting VM details
    $vmSetting = az vm show -n $vm.name -g $resourceGroupName | ConvertFrom-Json
    Write-Host "=================="-ForegroundColor Green
    Write-Host "Working on VM:"$vm.Name
    #Enabling Accelerated networking
    Write-Output "Checking the Accelerated Networking...."
    #Getting Network Adapter properties
    $nicState = az network nic show --name $vmSetting.networkProfile.networkInterfaces.Id.Split('/')[8] --resource-group $resourceGroupName | ConvertFrom-Json
    #Checking VM Number of cores
    [string]$vmSize = "'" + $vmSetting.hardwareProfile.vmSize + "'"
    $vmNumberOfCores = az vm list-sizes -l $vmSetting.location --query "[?contains(name, $vmSize)]" | ConvertFrom-Json
    #Checking if VM is part of an availability set
    if($null -eq $vmSetting.availabilitySet.id){
        Write-Host " This vm is not part of an availability set"
        Write-Host "Moving forward with the deployment..."
    }else{
        Write-Warning -Message "This VM is part of an availability set and due this, the deployment may fail. If you get an error, please check the Microsoft Documentation" 
    }
    Write-Host ""
    Write-Host ""
    # This condition checks if the Accelerated network is already enabled, if it is, the script will ignore the VM and got to the next
    if($nicState.enableAcceleratedNetworking -eq $false -and $vmNumberOfCores.NumberOfCores -ge 4){
        Write-Host "Accelerated networking is not enabled..."
        Write-Host "Enabling..."
        Write-Host ""
        # Deallocate the VM
        Write-Host "Checking if the VM is deallocated" -ForegroundColor Gray
        $status = az vm get-instance-view --name $vm.name --resource-group $resourceGroupName --query instanceView.statuses[1] -o json | ConvertFrom-Json
        Start-Sleep -Seconds 5
        Write-Host ""
        if($status.displayStatus -eq "VM deallocated"){
            Write-Host "VM already deallocated" -ForegroundColor Green
        }else{
            Write-Host "The VM" $vm.name "is running and will be deallocated" -ForegroundColor Red
            az vm deallocate --name $vm.name --resource-group $resourceGroupName
        }
        Write-Host ""
        #enabling ...
        Write-Host ""
        Write-Host "Enabling Accelerated Networking..."
        $null = az network nic update --name $vmSetting.networkProfile.networkInterfaces.Id.Split('/')[8] --resource-group $resourceGroupName --accelerated-networking $enableAcceleratedNic
        $nicState2 = az network nic show --name $vmSetting.networkProfile.networkInterfaces.Id.Split('/')[8] --resource-group $resourceGroupName | ConvertFrom-Json
        if($nicState2.enableAcceleratedNetworking -ne $true) {
            Write-Host "Error -> Accelerated Network was not enabled on" $vm.name -ForegroundColor Red
        }else{
            Write-Host "Success -> Accelerated Network was enabled on"  $vm.name -ForegroundColor Green
        }
        #Starting VM
        Write-Host ""
        Write-Output "Starting VM..."
        Write-Host ""
        az vm start --name $vm.name --resource-group $resourceGroupName --no-wait
        Write-Warning -Message "VM will be started in the backgroud, please check VM state over the Azure Portal"
        Write-Host "Preparing next VM.." -ForegroundColor Yellow
        Write-Host "================" -ForegroundColor Green

    }else{
        Write-Host ""
        Write-Host "Accelerated nic is enabled or cannot be enabled on VM:" $vm.name -ForegroundColor Red
        Write-Host "Going to the Next VM..."
        Write-Host "===============" -ForegroundColor Green
    }

}