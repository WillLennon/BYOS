import urllib
import tarfile
import json
import Utils.Constants as Constants
import os
import platform
import shutil
import Utils.HandlerUtil as Util

def enable_pipelines_agent(config):
  try:

    handler_utility.add_handler_sub_status(Util.HandlerSubStatus('DownloadPipelinesAgent'))
    agentFolder = config["AgentFolder"]

    # download the agent tar file
    downloadUrl = config["AgentDownloadUrl"]
    agentFile = os.path.join(agentFolder, os.path.basename(downloadUrl))
    urllib.urlretrieve(downloadUrl, agentFile)

    # download the enable script
    downloadUrl = config["EnableScriptDownloadUrl"]
    enableFile = os.path.join(agentFolder, os.path.basename(downloadUrl))
    urllib.urlretrieve(downloadUrl, enableFile)

  except Exception as e:
    set_error_status_and_error_exit(e, RMExtensionStatus.rm_extension_status['DownloadPipelinesAgentError']['operationName'], getattr(e,'message'))

  try:
    # run the enable script
    handler_utility.add_handler_sub_status(Util.HandlerSubStatus('EnablePipelinesAgent'))
    enableParameters = config["EnableScriptParameters"]
    enableProcess = subprocess.Popen(['/bin/bash', '-c', enableFile, enableParameters])

    # wait for the script to complete
    installProcess.communicate()

  except Exception as e:
    set_error_status_and_error_exit(e, RMExtensionStatus.rm_extension_status['EnablePipelinesAgentError']['operationName'], getattr(e,'message'))

  handler_utility.add_handler_sub_status(Util.HandlerSubStatus('EnablePipelinesAgentSuccess'))
  handler_utility.set_handler_status(Util.HandlerStatus('Enabled'))
  handler_utility.log('Pipelines Agent is enabled.')

