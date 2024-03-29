<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

Get-IntuneGraphAPIObject.ps1

This script allows you to test Graph API objects in the "https://graph.microsoft.com/beta" namespace, specifying
only the path to the object.

Example:
Query /deviceManagement/ManagedDevices

Get-IntuneGraphAPIGObject.ps1 -GraphObjectPath


#>

####################################################
Param 
(
    [Alias("obj","Object","Name","O")]
    [Parameter(Mandatory=$true)]
       [string]$GraphObjectPath,

    [ValidateSet("beta","v1.0", ignorecase = $true)]
    [Parameter()]
    [string]$graphApiVersion = "beta"
)
function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $User
    )
    
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    
    $tenant = $userUpn.Host
    
    Write-Host "Checking for AzureAD module..."
    
        $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
        if ($null -eq $AadModule) {
    
            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
        }
    
        if ($null -eq $AadModule) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
        if($AadModule.count -gt 1){
    
            $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
    
            $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }
    
                # Checking if there are multiple versions of the same module found
    
                if($AadModule.count -gt 1){
    
                $aadModule = $AadModule | Select-Object -Unique
    
                }
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
        else {
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"
    
    $authority = "https://login.microsoftonline.com/$Tenant"
    
        try {
    
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    
        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result
    
            # If the accesstoken is valid then create the authentication header
    
            if($authResult.AccessToken){
    
            # Creating header for Authorization token
    
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }
    
            return $authHeader
    
            }
    
            else {
    
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
    
            }
    
        }
    
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    
        }
    
    }
    
    ####################################################
    
    Function Get-REST_URI(){
    
    <#
    .SYNOPSIS
    This function is used to get Intune Managed Devices from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Intune Managed Device
    .EXAMPLE
    Get-ManagedDevices
    Returns all managed devices but excludes EAS devices registered within the Intune Service
    .EXAMPLE
    Get-ManagedDevices -IncludeEAS
    Returns all managed devices including EAS devices registered within the Intune Service
    .NOTES
    NAME: Get-ManagedDevices
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter (Mandatory = $true)]
        [string]$ObjectName
    )
    
    # Defining Variables
    $graphApiVersion = "beta"
    $Resource = "$ObjectName"
    
    try {
    
         
        
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            # URI like https://graph.microsoft.com/beta/deviceManagement/managedDevices/11111111-2222-3333-4444-555555555555
            $GUIDRegex =  ".*[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$"
            # URI like https://graph.microsoft.com/beta/deviceManagement/managedDevices('11111111-2222-3333-4444-555555555555')
            $QuotedParameterRegex = ".*\(\'.*\'\).*"
     
            if ( ($uri -match $QuotedParameterRegex  ) -or ($uri -match $GUIDRegex) ) {
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
            }
            else {
                 (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            }
        
        }
    
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    }
    
    function Get-ValidatedObjectPath {
        param ($objectPath)

        [string]$ValidatedObjectPath = ""

        # For easy copy/pasting from references and F12.  Remove https://graph.microsoft.com
        if ($objectPath -match "graph.microsoft.com") {
            $ValidatedObjectPath = $objectPath -replace "^https:\/\/graph.microsoft.com\/(beta|v1.0)\/", ""
        }
        # Remove leading forwardslash
        elseif($objectPath -match "^\/"){
            $ValidatedObjectPath = $objectPath -replace "^\/", ""
        }
        else {
            $ValidatedObjectPath = $objectPath
        }
        $ValidatedObjectPath = $ValidatedObjectPath.Trim()

        $ValidatedObjectPath
    }
    ####################################################
 
     
    #region Authentication
    
    write-host
    
    # Checking if authToken exists before running authentication
    if($global:authToken){
    
        # Setting DateTime to Universal time to work in all timezones
        $DateTime = (Get-Date).ToUniversalTime()
    
        # If the authToken exists checking when it expires
        $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
    
            if($TokenExpires -le 0){
    
            write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
            write-host
    
                # Defining User Principal Name if not present
    
                if($null -eq $User -or $User -eq ""){
    
                $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                Write-Host
    
                }
    
            $global:authToken = Get-AuthToken -User $User
    
            }
    }
    
    # Authentication doesn't exist, calling Get-AuthToken function
    
    else {
    
        if($null -eq $User -or $User -eq ""){
    
        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host
    
        }
    
    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User
    
    }
    
    #endregion
    
    ####################################################
    $objects = @()
    $validatedPath = Get-ValidatedObjectPath -objectPath $GraphObjectPath

    Write-Output "Querying Graph for object `"https://graph.microsoft.com/$graphApiVersion/$validatedPath`"."

    $objects = Get-REST_URI -ObjectName $validatedPath

    if ($objects.GetType() -eq "PSCustomObject") {        
        Write-Output "1 object returned from Graph API"
        $objects
    }
    else {
         Write-Output "$($objects.count) objects returned from Graph API"


         foreach ($object in $objects){
            Write-Output $object
            Write-Output ""
        }
    }
