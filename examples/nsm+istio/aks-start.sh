#!/bin/bash
readonly AZURE_RESOURCE_GROUP=nsm-ci
readonly AZURE_CLUSTER_NAME=$1

if [[ -z "$AZURE_CLUSTER_NAME"  ]]; then
    echo "Missed cluster name $AZURE_CLUSTER_NAME..."
    exit 1
fi

echo -n "Creating AKS cluster '$AZURE_CLUSTER_NAME'..."
az aks create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "$AZURE_CLUSTER_NAME" \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --enable-node-public-ip \
    --generate-ssh-keys \
    --debug && \
    echo "az aks create done" || exit 2
echo "Waiting for deploy to complete..."

az aks wait  \
	--name "$AZURE_CLUSTER_NAME" \
	--resource-group "$AZURE_RESOURCE_GROUP" \
	--created > /dev/null && \
echo "az aks wait done" || exit 3

NODE_RESOURCE_GROUP=$(az aks show -g "$AZURE_RESOURCE_GROUP" -n "$AZURE_CLUSTER_NAME" --query nodeResourceGroup -o tsv)
echo NODE_RESOURCE_GROUP="$NODE_RESOURCE_GROUP"
NSG_NAME=""
for i in {1..15}
do
    NSG_NAME=$(az network nsg list -o tsv --query "[? resourceGroup == '$NODE_RESOURCE_GROUP'].name")
    if [[ -n $NSG_NAME  ]]; then
        break
    fi
    NSG_NAME=$(az network nsg list -g "$NODE_RESOURCE_GROUP" --query "[].name" -o tsv)
    if [[ -n $NSG_NAME  ]]; then
        break
    fi
    sleep 10
    echo attempt "$i" has failed
done

if [[ -z $NSG_NAME  ]]; then
    echo "NSG is not found for resource group $NODE_RESOURCE_GROUP... AKS could be unstable (do destroy if LB will not work)"
    exit 0
fi

az network nsg rule create --name "allowall" \
    --nsg-name "$NSG_NAME" \
    --priority 100 \
    --resource-group "$NODE_RESOURCE_GROUP" \
    --access Allow \
    --description "Allow All Inbound Internet traffic" \
    --destination-address-prefixes '*' \
    --destination-port-ranges '*' \
    --direction Inbound \
    --protocol '*' \
    --source-address-prefixes Internet \
    --source-port-ranges '*' && \
echo "az network nsg rule create done" || exit 5
