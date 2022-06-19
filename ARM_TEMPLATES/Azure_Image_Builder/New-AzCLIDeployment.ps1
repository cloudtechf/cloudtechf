$tenantId = ""
$subscriptionId = ""
$templateParametersFile = ''
$templateFile = ''
$resourceGroup = ""
$deploymentName = ""

##################################################

#Login on Azure Tenant
$null = az login --tenant $tenantId

#Select Azure Subscription
az account set --subscription $subscriptionId

#Starting Deployment
az deployment group create --resource-group $resourceGroup -n $deploymentName -f $templateFile -p $templateParametersFile --verbose