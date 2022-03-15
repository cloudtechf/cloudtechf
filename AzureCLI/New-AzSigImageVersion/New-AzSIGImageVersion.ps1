<#
.SYNOPSIS
    New-AzSigImageVersion will add a new image version for an image definition.
.DESCRIPTION
    This script allows you to create a new image version on shared image gallery and, after the process succeed it will delete the VM and dependencies.
.PARAMETER SubscriptionId
    Subscription where the VM and Shared Image Gallery is.
.PARAMETER TenantId
    Tenant Id.
.PARAMETER VmResourceGroupName
    Resource Group where the VM is.
.PARAMETER SigResourceGroupName
    Resource Group where the Azure Compute Gallery is.
.PARAMETER vmName
    Name of the VM that you want to create an image version.
.PARAMETER sigName
    Azure Compute Gallery Name.
.PARAMETER imageDefinition 
    Image Definition name.
.PARAMETER imageVersion
    Image version, Example 20.30.141
.Example 
    ./New-AzSigImageVersion -subscriptionId <subscriptionId> -tenantId <tenantId> -VmResourceGroupName <VmResourceGroupName> -SigVmVmResourceGroupName <SigVmVmResourceGroupName> -vmName <VmName> -sigName <SigName> -imageDefinition <imageDefinition> -imageVersion <imageVersion>
.NOTES
    Version: 1
    Date: 01/24/2022
#>

#Parameters Section

param(
    [Parameter(Mandatory=$True)]
    [string]$subscriptionId,
    
    [Parameter(Mandatory=$True)]
    [string]$tenantId,
    
    [Parameter(Mandatory=$True)]
    [string]$vmResourceGroupName,

    [Parameter(Mandatory=$True)]
    [string]$SigResourceGroupName,

    [Parameter(Mandatory=$True)]
    [string]$vmName,

    [Parameter(Mandatory=$True)]
    [string]$sigName,

    [Parameter(Mandatory=$True)]
    [string]$imageDefinition,

    [Parameter(Mandatory=$True)]
    [string]$imageVersion
)

Write-Host "#############################################################################" -ForegroundColor Gray
#Login on the azure CLI
Write-Host "Login on Azure Tenant" -ForegroundColor Green
$null = az login --tenant $tenantId
#Select the Subscription
Write-Host "Selecting the Azure Subscription -> $subscriptionId" -ForegroundColor Green
az account set --subscription $subscriptionId
Write-Host "#############################################################################" -ForegroundColor Gray

Write-Host "#############################################################################" -ForegroundColor Gray
Write-Warning -Message "This script does not SYSPREP or do the deprovisining of the WAAGENT. Please, make sure that you followed those steps before running it"
Write-Warning -Message "Once the image is published in the gallery, the VM will be deleted (VM Container, Disk and network adapter)"
Write-Output "Do you want to proceed? (y/n)"
Write-Host "#############################################################################" -ForegroundColor Gray
$option = Read-Host
if ($option -eq "n"){
    Write-Error -Message "Closing the Script"
    exit
}else{
    Write-Host "Moving forward with the image deployment..." -ForegroundColor Green
}
Write-Host "#############################################################################" -ForegroundColor Gray
# Vm Properties
Write-Host " Getting the VM properties" -ForegroundColor Green
$vmDetails = az vm show -g $vmResourceGroupName -n $vmName -o json | ConvertFrom-json

# Deallocate the VM
Write-Host "Checking if the VM is deallocated" -ForegroundColor Gray
$powerStatus = az vm get-instance-view --resource-group $vmResourceGroupName --name $vmDetails.name --query instanceView.statuses[1] -o json | ConvertFrom-Json
if ($powerStatus.displayStatus -eq "VM deallocated"){
    Write-Host "The VM $vmName already deallocated" -ForegroundColor Green
}else{
    Write-Host "The VM $vmName is running and will be deallocated" -ForegroundColor Red
    az vm deallocate -g $vmResourceGroupName -n $vmName
}
Write-Host "#############################################################################" -ForegroundColor Gray
# Generalize the VM on Azure
Write-Host "Starting the Generalize process" -ForegroundColor Gray
az vm generalize -g $VmResourceGroupName -n $vmName

#Exclude old images from the latest
Write-Host "Excluding previous version from the latest"
$allImages = az sig image-version list --resource-group $SigResourceGroupName --gallery-name $sigName --gallery-image-definition $imageDefinition -o json | ConvertFrom-Json
foreach ($image in $allImages){
    $oldVersion = $image.name

    if ($image.publishingProfile.excludeFromLatest -eq "True"){
        Write-Host "Version $oldVersion excluded from latest" -ForegroundColor Green
    }else{
        Write-Host "Setting the $oldVersion as exclude from latest..." -ForegroundColor Green
        az sig image-version update -g $SigResourceGroupName --gallery-name $sigName --gallery-image-definition $imageDefinition --gallery-image-version $oldVersion --set publishingProfile.excludeFromLatest=true --no-wait
    }
}

Write-Output "#############################################################################"

# Publish de new Image Version
Write-Host "Publishing the new Image Version" -ForegroundColor Green
Write-Warning "The process can take over 30 Minutes! Once it succeed, the VM and dependencies will be deleted"

az sig image-version create -g $SigResourceGroupName --gallery-name $sigName --gallery-image-definition $imageDefinition --gallery-image-version $imageVersion --managed-image $vmDetails.id 

Write-Host "Getting the New Image Status..." -ForegroundColor Gray
$imageDetails = az sig image-version show --gallery-name $sigName --resource-group $SigResourceGroupName --gallery-image-definition $imageDefinition --gallery-image-version $imageVersion | ConvertFrom-Json 
if ($imageDetails.provisioningState -eq "Succeeded"){
    Write-Host "Process finished with Success!!!" -ForegroundColor Green    
    Write-Host "The VM and dependencies will be deleted" -ForegroundColor Gray
    # Delete VM
    Write-Host "Deleting VM..." -ForegroundColor Gray
    az vm delete -n $vmName -g $VmResourceGroupName --yes 

    # Delete O.S Disk
    Write-Host "Deleting O.S Disk..." -ForegroundColor Gray
    az disk delete -n $vmDetails.storageProfile.osDisk.name -g $VmResourceGroupName --yes
    
    # Delete VM Nic
    Write-Host "Deleting Nic..." -ForegroundColor Gray
    az network nic delete -n $vmDetails.networkProfile.networkInterfaces.id.Split('/')[8] -g $VmResourceGroupName
    Write-Host "Resources deleted with success" -ForegroundColor Green
}else{
    Write-Error -Message "Something goes Wrong, check the image Gallery" 
}
Write-Output "#############################################################################"