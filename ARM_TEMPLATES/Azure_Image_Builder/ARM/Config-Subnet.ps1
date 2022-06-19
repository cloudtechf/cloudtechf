az network nsg rule create `
		--resource-group <NSG ResourceGroup> `
        --nsg-name <NSG NAME>  `
        -n AzureImageBuilderNsgRule `
        --priority 400 `
        --source-address-prefixes AzureLoadBalancer `
        --destination-address-prefixes VirtualNetwork `
        --destination-port-ranges 60000-60001 --direction inbound `
        --access Allow --protocol Tcp `
        --description "Allow Image Builder Private Link Access to Proxy VM"
    
    
az network vnet subnet update `
		--name <SubnetForAiB> `
		--resource-group <VNETResourceGroup> `
		--vnet-name VNET-EastUS `
		--disable-private-link-service-network-policies true