# New-AzSigImageVersion

This script allows you to create a new Shared Image Version by using az cli commands

## Usage

```

./New-AzSIGImageVersion.ps1 -subscriptionId <SubscriptionId> -tenantId <TenantId> -SigResourceGroupName <SharedImageGalleryRGName> -VmResourceGroupName <VMResourceGroupName> -vmName <VmName> -sigName <SigName> -imageDefinition <ImageDefinitionName> -imageVersion <ImageVersion>

```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

.NOTES

    I'm not responsble for any damage in your environment, please validade the script before running in production scenarios.
