Steps to create an Azure Virtual Machine Scale Set (VMSS) for use with Azure DevOps Elastic Agent Pools

1. Install the Azure CLI. Instructions are here:
   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

2. Download this powershell script and input json file.  Place them in the same directory.
   https://raw.githubusercontent.com/WillLennon/BYOS/master/vmss/CLI/CreateScaleSet.ps1
   https://raw.githubusercontent.com/WillLennon/BYOS/master/vmss/CLI/CreateScaleSet.Parameters.json

3. Edit the CreateScaleSet.Parameters.json file with your desired inputs.
   
4. Login to your Azure subscription via this AZ CLI command and follow the pop-up instructions
   az login

5. Run CreateScaleSet.ps1 to create your scaleset.

6. Navigate to your Azure DevOps account and click Add Pool to begin creating your Elastic Pool.
   https://dev.azure.com/<your account>/<your project>/_settings/agentqueues
