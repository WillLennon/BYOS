Steps to create an Azure Virtual Machine Scale Set (VMSS) for use with Azure DevOps Elastic Agent Pools

1. Install the Azure CLI. Instructions are here:
   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

2. Login to your Azure subscription via this command and follow the pop-up instructions
   az login
  
3. Populate the CreateScaleSet.Parameters.json file with your desired inputs.

4. Run CreateScaleSet.ps1 to create your scaleset.

5. Navigate to your Azure DevOps account and click Add Pool to create your Elastic Pool.
   https://dev.azure.com/<your account>/<your project>/_settings/agentqueues
