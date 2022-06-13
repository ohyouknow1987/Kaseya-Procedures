﻿<#
.Synopsis
   Disables Microsoft Store.
.DESCRIPTION
   Disables Microsoft Store. Used by the Disable Microsoft Store Agent Procedure 
.EXAMPLE
   .\Disable-WindowsStore.ps1
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

#region function Set-RegParam
function Set-RegParam {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [string] $RegPath,
        [parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=1)]
        [AllowEmptyString()]
        [string] $RegValue,
        [parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=2)]
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string] $ValueType = 'DWord',
        [parameter(Mandatory=$false)]
        [Switch] $UpdateExisting
    )
    
    begin {
        [string] $RegKey = Split-Path -Path Registry::$RegPath -Parent
        [string] $RegProperty = Split-Path -Path Registry::$RegPath -Leaf
    }
    process {
            #Create key
            if( -not (Test-Path -Path $RegKey) ) {
                try {
                    New-Item -Path $RegKey -Force -Verbose -ErrorAction Stop
                } catch {
                    "<$RegKey> Key not created" | Write-Error
                }
                #Create property
                try {
                    New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                } catch {
                    "<$RegKey> property <$RegProperty>  not created" | Write-Error
                }
            } else
            {
                $Poperty = try {
                    Get-ItemProperty -Path Registry::$RegPath -ErrorAction Stop | Select-Object -ExpandProperty $Value -ErrorAction Stop
                    } catch { $null}
                if ($null -eq $Poperty ) {
                     #Create property
                    try {
                        New-ItemProperty -Path $RegKey -Name $RegProperty -PropertyType $ValueType -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch {
                        "<$RegKey> property <$RegProperty>  not created" | Write-Error
                    }
                }
                #Assign value to the property
                if( $UpdateExisting ) {
                    try {
                        Set-ItemProperty -Path $RegKey -Name $RegProperty -Value $RegValue -Force -Verbose -ErrorAction Stop
                    } catch {
                        "<$RegKey> property <$RegProperty> not set" | Write-Error
                    }
                }
            }
    }
}
#endregion function Set-RegParam

[string[]] $RegPaths = @('SOFTWARE\Policies\Microsoft\WindowsStore\RemoveWindowsStore', 'SOFTWARE\Policies\Microsoft\WindowsStore\DisableStoreApps')

#region set machine settings
foreach ($ChildPath in $RegPaths) {
    $RegPath = Join-Path -Path "HKEY_LOCAL_MACHINE" -ChildPath $ChildPath
    Set-RegParam -RegPath $RegPath -RegValue 1
}
#endregion set machine settings

#region Change Users' Hives
[string] $SIDPattern = '^S-1-5-21-(\d+-?){4}$'
[string] $RegKeyUserProfiles = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'
[array] $ProfileList = Get-ItemProperty -Path Registry::$RegKeyUserProfiles | `
                    Select-Object  @{name="SID";expression={$_.PSChildName}},
                    @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
                    @{name="UserName";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}} | `
                    Where-Object {$_.SID -match $SIDPattern}
# Loop through each profile on the machine
Foreach ($Profile in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    reg load "HKU\$($Profile.SID)" "$($Profile.UserHive)"
    #####################################################################
    # Modifying a user`s hive of the registry
    "{0} {1}" -f "`tUser:", $($Profile.UserName) | Write-Verbose
    
    foreach ($ChildPath in $RegPaths) {
        $RegPath = Join-Path -Path "HKU\$($Profile.SID)" -ChildPath $ChildPath
        Set-RegParam -RegPath $RegPath -RegValue 1
    }

    #####################################################################
    [gc]::Collect()
    $ErrorActionPreferenceSaved = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    reg unload "HKU\$($Profile.SID)" | Out-Null
    $ErrorActionPreference = $ErrorActionPreferenceSaved
}
#endregion Change Users' Hives

#region Remove Appx
Get-AppXPackage *WindowsStore* -AllUsers | Remove-AppxPackage
#endregion Remove Appx