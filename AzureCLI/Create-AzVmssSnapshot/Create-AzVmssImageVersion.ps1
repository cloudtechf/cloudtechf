<#
.SYNOPSIS
    Create-AzVmssImage is a sample script that can help Azure Administrators to create images from a VMSS Instance
.DESCRIPTION
    This script will allow you to create an image version on Azure computegallery from a VMSS Instance
.PARAMETER SubscriptionId
    You need to inform the subscriptionId, in case your tenant has more than one subscription.
.PARAMETER TenantId
    You need to inform the tenantId, in case your user has access to more than one Tenant.
.PARAMETER ResourceGroupName    
    Resource Group where you store your VM's
.PARAMETER vmssName
    Name of the Virtual Machine Scale Sets
.PARAMETER snapshotName
    Name of the Snapshot that you'll create from the VMSS Instance.
.PARAMETER instanceId
    Id of the instance that you'll use as image reference.
.PARAMETER galleryName
    Azure Compute Gallery name
.PARAMETER galleryImageDefinition
    Image definition name
.PARAMETER imageVersion
    Value of the new image version, the value should be like the example 10.23.32
.NOTES
    Version: 1
    Date: 03/08/2022
#>

#Azure Login Parameters
$tenantId = ""
$subscriptionId = ""

#Instance Parameters
$vmssName = "" 
$resourceGroupName = "" 
$snapshotName = "" 
$instanceId =  

#Azure Compute gallery Parameters
$galleryName = "" 
$galleryImageDefinition = ""
$imageVersion = "" 

## END OF THE VARIABLE SECTION ##

#Login on Azure Account
$null = az login --tenant $tenantId
$null = az account set --subscription $subscriptionId

#Getting VMSS
Write-Host "Getting Instance details..."
$vmssConfig = az vmss show --name $vmssName --resource-group $resourceGroupName --instance-id $instanceId | ConvertFrom-Json
if($null -eq $vmssConfig){
    Write-Error -Message "Not able to find the instance $instanceId on $vmssName"
    exit 1
}else{
    Write-Host "Instance $instanceId does exist on VMSS $vmssName"
}

#Executing Sysprep
Write-Host ""
Write-Host ""

Write-Output "Executing the Sysprep Command"
Write-Warning -Message "The process can take up to 10 minutes, please wait until the command output"
#Command below will execute the sysprep.exe
$null = az vmss run-command invoke -g $resourceGroupName -n $vmssName --command-id RunPowerShellScript --instance-id $instanceId --scripts "c:\windows\system32\sysprep\sysprep.exe /generalize /shutdown /oobe"
Write-Warning -Message "Instance Generalized, you'll wont be able to use it anymore"
Write-Warning -Message "Instance will be deleted once the image is created"

Write-Host ""
Write-Host ""

#Creating Snapshot
Write-Output "Creating Instance Snapshot..."

$snapshotCreation = az snapshot create -g $resourceGroupName -n $snapshotName --source $vmssConfig.storageProfile.osDisk.managedDisk.id | ConvertFrom-Json
if($snapshotCreation.provisioningState -eq "Succeeded"){
    Write-Host "Snapshot provisioned with success" -ForegroundColor Green
}else {
    Write-Error "Error While provisioning Disk Snapshot"
    exit 1
}
Start-Sleep -Seconds 15

#Creating Managed Image
Write-Host "Creating a new Image Version based on the snapshot created"
$provisioningImage = az sig image-version create --resource-group $resourceGroupName --gallery-name $galleryName --gallery-image-definition $galleryImageDefinition --gallery-image-version $imageVersion --os-snapshot $snapshotCreation.id | ConvertFrom-Json

if($provisioningImage.provisioningState -eq "Succeeded"){
    Write-Host "New image version provisioned with success" -ForegroundColor Green
    #Deleting Instance After creating the Snapshot and Sysprep
    Write-Warning -Message "Deleting the Generalized Instance"
    $null = az vmss delete-instances --name $vmssName --resource-group $resourceGroupName --instance-id $instanceId --no-wait
    Write-Warning -Message "Deleting Snapshot"
    $null = az snapshot delete --ids $snapshotCreation.id
}else{
    Write-Error "Error While provisioning new image version"
}
