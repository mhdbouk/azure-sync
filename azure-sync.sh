#!/bin/bash

# Author: Mohamad Dbouk
# Website: https://mdbouk.com

# If the first argument is --help or no arguments are provided, then print the help message and exit
if [ "$1" == "--help" ] || [ $# -ne 2 ]; then
    printf "\e[32m"
    printf "  ___                       _____                   \n"
    printf " / _ \\                     /  ___|                  \n"
    printf "/ /_\\ \\_____   _ _ __ ___  \\ \`--. _   _ _ __   ___  \n"
    printf "|  _  |_  / | | | '__/ _ \\  \`--. \\ | | | '_ \\ / __| \n"
    printf "| | | |/ /| |_| | | |  __/ /\\__/ / |_| | | | | (__  \n"
    printf "\\_| |_/___|\\__,_|_|  \\___| \\____/ \\__, |_| |_|\\___| \n"
    printf "                                   __/ |            \n"
    printf "                                  |___/             \n"
    printf "\e[0m"
    printf "\e[34mAuthor: Mohamad Dbouk\n"
    printf "Website: https://mdbouk.com\n"
    printf "\n"
    printf "Usage: ./azure-sync.sh <appname> <app_resource_group>\e[0m\n"
    # exist with success when --help is provided
    if [ "$1" == "--help" ]; then
        exit 0
    else
        exit 1
    fi
fi

appname=$1
app_resource_group=$2
# Call Azure CLI to get all environment variables
env_variables=$(az webapp config appsettings list --name $appname --resource-group $app_resource_group --query "[].{name:name,value:value}" --output json)
# Check if Azure CLI command was successful
if [ $? -ne 0 ]; then
    printf "\e[31mFailed to retrieve environment variables from Azure.\e[0m\n"
    exit 1
fi
# Initialize the local dotnet secret if not already initialized
dotnet user-secrets init

# Loop through each environment variable and add it to local dotnet secret
for row in $(echo "${env_variables}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }
    name=$(_jq '.name')
    value=$(_jq '.value')
    is_keyvault_used=false

    # Check if the value starts with '@Microsoft.KeyVault'
    if [[ $value == @Microsoft.KeyVault* ]]; then # @Microsoft.KeyVault(SecretUri=https://<keyvault_name>.vault.azure.net/secrets/<secret_name>/<version>)
        # Get the actual value from Azure KeyVault
        is_keyvault_used=true
        value=$(get_keyvault_secret $value)
    fi

    # Replace '__' with ':' in the name, keep `_` single underscore as is
    name=$(echo $name | sed 's/__/:/g')

    # Add the environment variable to local dotnet secret
    result=$(dotnet user-secrets set "$name" "$value")
    if [ $? -ne 0 ]; then
        printf "\e[31mFailed to add secret: %s\e[0m\n" "$name"
        continue
    fi

    if [ "$is_keyvault_used" = true ]; then
        printf "Added secret from \e[33mKeyVault\e[0m: \e[32m%s\e[0m\n" "$name"
    else
        printf "Added secret: \e[32m%s\e[0m\n" "$name"
    fi
done
echo "Environment variables retrieved from Azure and added to local dotnet secret."

# function to retrieve the value of a secret from Azure KeyVault
get_keyvault_secret() {
    local keyVaultValue=$1
    local value

    local keyvault_name=$(echo $keyVaultValue | sed -n 's|.*SecretUri=https://\([^\.]*\).*|\1|p')
    local secret_name=$(echo $keyVaultValue | sed -n 's|.*vault.azure.net/secrets/\([^/)]*\).*|\1|p')
    local version=$(echo $keyVaultValue | sed -n 's|.*vault.azure.net/secrets/'$secret_name'/\([^)]*\).*|\1|p')

    # if version is not empty, then get the secret value with version
    if [ -z "$version" ]; then
        value=$(az keyvault secret show --name $secret_name --vault-name $keyvault_name --query "value" --output tsv)
    else
        value=$(az keyvault secret show --name $secret_name --vault-name $keyvault_name --version $version --query "value" --output tsv)
    fi
    echo $value
}