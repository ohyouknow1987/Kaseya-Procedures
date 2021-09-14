﻿function Update-VSAItems
{
<#
.Synopsis
   Updates VSA items using Get  REST API method
.DESCRIPTION
   Creates, modifies or deletes VSA objects. Returns if update was successful.
   Takes either persistent or non-persistent connection information.
.PARAMETER VSAConnection
    Specifies existing non-persistent VSAConnection.
.PARAMETER URISuffix
    Specifies URI suffix if it differs from the default.
.PARAMETER Method
    Specifies REST API Method.
.EXAMPLE
   Update-VSAItems
.EXAMPLE
   Update-VSAItems -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   True if method call was successful or False elsewhere.
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix,
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateSet("POST", "PUT", "DELETE", "PATCH")]
        [string] $Method,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$false,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()]
        [string] $Body
    )

    if ([VSAConnection]::IsPersistent)
    {
        $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $($VSAConnection.GetToken())"
        }
        else
        {
            throw "Connection status: $ConnectionStatus"
        }
    }

    $requestParameters = @{
        Uri = $CombinedURL
        Method = $Method
        AuthString = $UsersToken
    }

    if( $Body ) {
        $requestParameters.Add('Body', $Body)
    }

    $requestParameters | Out-String | Write-Verbose 

    #$result = Get-RequestData -URI $CombinedURL -AuthString $UsersToken
    $response = Get-RequestData @requestParameters
    Write-Verbose $response
    $result = $response  | Select-Object -ExpandProperty Result

    return $result
}
