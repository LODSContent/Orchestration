# Orchestration

This repo stores commonly used scripts that is shared with multiple projects. The purpose is to provide the latest version for all environments to consume.

## How to use

The Bootstrap scripts are exceuted to pull down and gain access to other scripts in this repo and any others.

### v1

**Bootstrap.ps1** -

- The _BootStrap.ps1_ script is intended to execute all other scripts within one session.
- The script contains an encoded Base64 function _Get-GitHubContents_.
- _Get-GitHubContents_ pulls down and invokes the _MasterBuildScript.ps1_.
- _MasterBuildScript.ps1_ uses the "$Bootstrap_Params" variable to pull down and execute scripts in order that are defined in the _Scripts.json_ file.

### v2

**Bootstrap_v2_Script1.ps1** -

- The _BootStrap_v2_Script1.ps1_ script is intended to execute in a "preinstallation environment".
- The script contains an encoded Base64 function _Get-DecompressedByteArray_.
- _Get-DecompressedByteArray_ decompresses the "$CoreFunctions_Base64" variable to add additional functions necessary for this session.
  - _Get-GitHubContents_
  - _Get-CompressedByteArray_
- Additional scripts can be accessed from other public/private repos.
- Scripts and functions are compressed and stored in global variables that can be shared with other sessions.

**Bootstrap_v2_Script2.ps1** -

- The _BootStrap_v2_Script2.ps1_ script is intended to execute in VM environment.
  - The VM does not need internet access if the script invoked is not requiring it.
- The script will need additional variables defined based on the invoked script's needs.
- The global variable containing the script(s) is decoded and decompressed to then be invoked.
- If the script is passing a "$Reboot" variable, an _if_ statement should be included.

## Script Usage

- Scripts are stored in folders categorized to their uses.
- Scripts should have meaningful explainations to their use.
- Scripts must define the requirements and test for them.
- Pull requests can be submitted to add/modify scripts to this repo.
- Private repos can be accessed with a Personal Access Token being passed as a parameter to the function _Get-GitHubContents_.
- Global functions are added to the script _Functions.ps1_.
