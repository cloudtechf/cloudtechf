$resourceGroup = ""
$subscriptionId = ""
$tenantId = ""
$identityName = "" #azure image builder Identity

#Login az tenant
$null = az login --tenant $tenantId

#Select subscription
$null = az account set --subscription $subscriptionId

# create user assigned identity for image builder to access the storage account where the script is located
az identity create -g $resourceGroup -n $identityName

# get identity id
$imgBuilderCliId = $(az identity show -g $resourceGroup -n $identityName --query clientId -o tsv)

# get the user identity URI, needed for the template
$imgBuilderId = "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identityName"

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# grant role definition to the user assigned identity
az role assignment create --assignee $imgBuilderId --role "$imageRoleDefName" #--scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup