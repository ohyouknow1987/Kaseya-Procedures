﻿function Get-VSADocuments
{
    <#
    .Synopsis
       Returns array of documents.
    .DESCRIPTION
       Returns an array of documents from the Audit > Documents page.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Path
        Specifies path to a folder.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSADocuments 
    .EXAMPLE
       Get-VSADocuments -AgentId 10001 -Path 'FolderLevel1/FolderLevel2'
    .EXAMPLE
       Get-VSADocuments -AgentId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Custom Extension Folders and Files.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/documents/{0}/folder/{1}',

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [Parameter(Mandatory = $false)]
        [switch] $DownloadFile
    )
    if (-not [string]::IsNullOrEmpty($Path) ) {
        $Path = $Path -replace '\\', '/'
        #if ($Path -notmatch '^\/') { $Path = "/$Path"}
        #if ($Path -notmatch '\/$') { $Path = "$Path/"}
    }

    $URISuffix = $URISuffix -f $AgentId, $Path

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -in $(Get-VSAAgent @Params | Select-Object -ExpandProperty AgentID) ) {

        $Params.Add('URISuffix', $URISuffix)
        if($Filter)        {$Params.Add('Filter', $Filter)}
        if($Paging)        {$Params.Add('Paging', $Paging)}
        if($Sort)          {$Params.Add('Sort', $Sort)}

        $Params | Out-String | Write-Verbose
        $Params | Out-String | Write-Debug

        $result = Get-VSAItems @Params

    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    return $result
}
Export-ModuleMember -Function Get-VSADocuments