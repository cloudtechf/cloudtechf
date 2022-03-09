# Create-AzVmssImage

This script allows you to create an image from a VMSS Instance

## Usage

```
You need to assign value in the variables bellow

Azure Login Parameters

$tenantId = ""
$subscriptionId = ""

Instance Parameters

$vmssName = "" #VMSSName
$resourceGroupName = "" #VMSS ResourceGroup
$snapshotName = "" #Name of the Snapshot
$instanceId =  #Instance that you want to take a snapshot

Azure Compute gallery Parameters

$galleryName = "" #Azure Compute Gallery Name
$galleryImageDefinition = "" #Image Definition Name
$imageVersion = "" #Version Id, Example -> 20.30.40

https://techf.cloud/index.php/2022/03/09/creating-an-image-from-a-vmss-instance/

```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

.NOTES

    I'm not responsble for any damage in your environment, please validade the script before running in production scenarios.
