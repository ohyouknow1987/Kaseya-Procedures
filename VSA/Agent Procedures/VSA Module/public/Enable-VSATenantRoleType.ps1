﻿function Enable-VSATenantRoleType {
    <#
    .Synopsis
       Activates selected roletypes for a specified tenant
    .DESCRIPTION
       Activates selected roletypes for a specified tenant
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantId
        Specifies a tenant partition.
    .PARAMETER TenantName
        Specifies a tenant partition.
    .PARAMETER RoleTypes
        Array of role types by name to be activated.
    .PARAMETER RoleTypeIds
        Array of role types by Id to be activated.
    .EXAMPLE
       Enable-VSATenantRoleType -TenantName 'YourTenant' -RoleTypes 'SB Admin', 'KDP Admin'
    .EXAMPLE
       Enable-VSATenantRoleType -TenantId 1001 -ModuleIds 105, 106
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/roletypes/{0}',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ValidateSet('VSA Admin', 'End User', 'Basic Machine', 'Service Desk Admin', 'Service Desk Technician', 'SB Admin', 'KDP Admin', 'KDM Admin')]
        [string[]] $RoleTypes,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateSet(4, 6, 8, 100, 101, 105, 116, 117)]
        [int[]] $RoleTypeIds
    )
    DynamicParam {

        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
        [hashtable] $AuxParameters = @{}
        if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

        [array] $script:Tenants = try {Get-VSATenants @AuxParameters -ErrorAction Stop | Select-Object Id, Ref } catch { Write-Error $_ }

        $ParameterName = 'TenantName' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ByName'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Tenants | Select-Object -ExpandProperty Ref # | ForEach-Object {Write-Output "'$_'"}
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        $ParameterName = 'TenantId' 
        $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.ParameterSetName = 'ById'
        $AttributesCollection.Add($ParameterAttribute)
        [string[]] $ValidateSet = $script:Tenants | Select-Object -ExpandProperty Id
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
        $AttributesCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributesCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }# DynamicParam
    Begin {
        if ( [string]::IsNullOrEmpty($TenantId)  ) {
            $TenantId = $script:Tenants | Where-Object { $_.Ref -eq $PSBoundParameters.TenantName } | Select-Object -ExpandProperty Id
            $TenantName = $PSBoundParameters.TenantName
        }
        if ( [string]::IsNullOrEmpty($TenantName)  ) {
            $TenantName = $script:Tenants | Where-Object { $_.Id -eq $PSBoundParameters.TenantId } | Select-Object -ExpandProperty Ref
            $TenantId = $PSBoundParameters.TenantId
        }
        if ( 0 -eq $RoleTypeIds.Count) {
                [hashtable] $HTRoleTypes = @{
                'VSA Admin'					= 4
                'End User'					= 6
                'Basic Machine'				= 8
                'Service Desk Admin'		= 100
                'Service Desk Technician'	= 101
                'SB Admin'					= 105
                'KDP Admin'					= 116
                'KDM Admin'					= 117
            }
    
            $Body = ConvertTo-Json $HTRoleTypes[$RoleTypes]
        } else {
            $Body = ConvertTo-Json $RoleTypeIds
        }
    }# Begin
    Process {
        $URISuffix = $URISuffix -f $TenantId

        $Body | Out-String | Write-Debug

        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method    = 'PUT'
            Body      = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        $Params | Out-String | Write-Debug

        return Update-VSAItems @Params
    }#Process
}

Export-ModuleMember -Function Enable-VSATenantRoleType