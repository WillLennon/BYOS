Steps to create an Azure Virtual Machine Scale Set (VMSS) for use with Azure DevOps Elastic Agent Pools

1. Install the Azure CLI. Instructions are here:
   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

2. Open Powershell and login to Azure:
   az login
   
3. Set your subscription:
   az account show
   az account set --subscription <Subscription Name or Id>

4. Create your Azure Virtual Machine ScaleSet by following the guidance in      
   https://github.com/WillLennon/BYOS/blob/master/vmss/CLI/CreateScalesetWithCustomImage.txt

5. Navigate to your Azure DevOps account and click Add Pool to begin creating your Elastic Pool.
   https://dev.azure.com/<your account>/<your project>/_settings/agentqueues
