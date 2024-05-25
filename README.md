# Azure Sync Settings

This script retrieves environment variables from an Azure App Service and adds them to your local .NET secrets. If the environment variable value is a reference to an Azure KeyVault secret, the script retrieves the actual secret value from Azure KeyVault.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/download/)
- [.NET Core SDK](https://dotnet.microsoft.com/download)

## Installation

1. Clone this repository and navigate to the directory containing `azure-sync.sh` and `install.sh`.

    ```bash
    git clone https://github.com/mhdbouk/azure-sync
    cd azure-sync
    ```

2. Run the installation script.

    ```bash
    chmod +x ./install.sh && ./install.sh
    ```

   This will copy `azure-sync.sh` to `/usr/local/bin` and make it executable.

## Usage

1. Run the script within your .NET application, passing your Azure App Service name and resource group as arguments.
    ```bash
    azure-sync <appname> <app_resource_group>
    ```

   Replace `<appname>` with the name of your Azure App Service and `<app_resource_group>` with the name of the resource group your App Service is in.

2. The script will retrieve all environment variables from the specified Azure App Service, including any Azure KeyVault secrets, and add them to your local .NET secrets.

## Notes

- You must be logged in to the Azure CLI with an account that has access to the specified Azure App Service and any referenced Azure KeyVaults.
- The script replaces double underscores (`__`) in environment variable names with colons (`:`) to match the .NET Core configuration key format.
