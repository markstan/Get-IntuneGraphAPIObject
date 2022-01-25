# Get-IntuneGraphAPIObject

 Get-IntuneGraphAPIObject.ps1 is a testing tool for quick access to the Intune Graph API.  The script performs an HTTP GET operation on the ojbect parameter passed to it. This is helpful for developing more complex scripts when you need to validate the syntax of a particular object or to investigate object attributes.

 

Accepts URI components in the following formats:

```powershell
     /deviceManagement/managedDevices
     deviceManagement/managedDevices
     https://graph.microsoft.com/beta/deviceManagement/managedDevices
     'deviceManagement/managedDevices?$select=deviceName, model'
      deviceManagement/managedDevices/11111111-2222-3333-4444-555555555555
      deviceManagement/managedDevices('11111111-2222-3333-4444-555555555555')
```

## Parameters

* GraphObjectPath - the object path.  See [Working with Intune in Microsoft Graph](https://docs.microsoft.com/en-us/graph/api/resources/intune-graph-overview?view=graph-rest-beta) for a complete list of supported Intune Graph API objects.
* graphApiVersion - the Graph API version you wish to use. Optional.  Accepted values are "beta" and "v1.0".

## Examples

```powershell
.\Get-IntuneGraphAPIObject.ps1  -GraphObjectPath "/deviceManagement/managedDevices"

.\Get-IntuneGraphAPIObject.ps1 -GraphObjectPath "/users"

.\Get-IntuneGraphAPIObject.ps1  -GraphObjectPath "https://graph.microsoft.com/beta/deviceManagement/managedDevices"

.\Get-IntuneGraphAPIObject.ps1 -GraphObjectPath 'deviceManagement/managedDevices?$select=deviceName, model'

.\Get-IntuneGraphAPIObject.ps1  -GraphObjectPath "deviceManagement/managedDevices" -graphApiVersion "v1.0"

.\Get-IntuneGraphAPIObject.ps1  -GraphObjectPath deviceManagement/windowsAutopilotDeploymentProfiles

.\Get-IntuneGraphAPIObject.ps1-GraphObjectPath 'deviceManagement/windowsAutopilotDeploymentProfiles?$select=id'

.\Get-IntuneGraphAPIObject.ps1 -GraphObjectPath "https://graph.microsoft.com/beta/deviceManagement/managedDevices/11111111-2222-3333-4444-555555555555"
```

## Helpful hints

### Dealing with special characters

Remember to escape special characters in your path using standard PowerShell syntax. When in doubt, pass filter parameters enclosed in single quotes to avoid variable expansion.

Good: 

```PowerShell 
.\Get-IntuneGraphAPIObject.ps1  -GraphObjectPath 'deviceManagement/windowsAutopilotDeploymentProfiles?$select=id'
```

Bad: 
```PowerShell 
.\Get-IntuneGraphAPIObject.ps1 -GraphObjectPath "deviceManagement/windowsAutopilotDeploymentProfiles?$select=id"
```

The 'Bad' example will return an unfiltered list of objects since the **$select** parameter will be interpretted as a null string (i.e. the URI passed is actually "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles?=id").

The easiest way to determine the URI passed is to investigate the command output.  The first line will show the URL as it is presented to Graph.

![Example output](https://github.com/markstan/Get-IntuneGraphAPIObject/blob/main/Resources/example.png)

### Execution policy

If you run this command on a device where you have not configured your PowerShell execution policy from the default settings, you will receive an error message similar to this:

```none
File C:\temp\Microsoft.PowerShell_profile.ps1 cannot be loaded because running scripts is disabled on this system. 
For more information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
```

To get past this error, run either set the executionpolicy to 'RemoteSigned' (i.e. run 'Set-ExecutionPolicy RemoteSigned' from an elevated PowerShell window) or else run the script like this:

```powershell
powershell.exe -executionpolicy RemoteSigned -File .\Get-IntuneGraphAPIObject.ps1 -GraphObjectPath 'deviceManagement/windowsAutopilotDeploymentProfiles?$select=id
```
 
### Download the script

I will add this to the PowerShell Gallery in the near future.  In the meantime, you can download the script by running this command:

```powershell
wget "https://aka.ms/IGAO" -OutFile .\Get-IntuneGraphAPIObject.ps1 
```
