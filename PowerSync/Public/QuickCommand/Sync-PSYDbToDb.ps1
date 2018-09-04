function Sync-PSYDbToDb {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [PSYDbConnectionProvider] $SourceProvider,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $SourceCS,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [PSYDbConnectionProvider] $TargetProvider,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $TargetCS,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string[]] $SourceTable,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string[]] $TargetTable,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Create,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Index,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Compress,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Throttle = 3
    )

    try {
        # If we're not already connected, use a local JSON repository
        if (-not $PSYSession.Initialized) {
            Remove-PSYJsonRepository -Path 'Repository.json'            # remove if already exists
            New-PSYJsonRepository -Path 'Repository.json'
            Connect-PSYJsonRepository -Path 'Repository.json'
        }

        # Register source and target connections
        Set-PSYConnection -Name 'Source' -Provider $SourceProvider -ConnectionString $SourceCS
        Set-PSYConnection -Name 'Target' -Provider $TargetProvider -ConnectionString $TargetCS

        # Define the work we need to perform
        $workItems = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $SourceTable.Count; $i++) {
            [void] $workItems.Add(@{
                SourceProvider = $SourceProvider
                TargetProvider = $TargetProvider
                SourceTable = $SourceTable[$i]
                TargetTable = if ($TargetTable) {$TargetTable[$i]} else {$SourceTable[$i]}      # if target table name omitted, default to source table name
                AutoCreate = $AutoCreate
                AutoIndex = $AutoIndex
                Overwrite = $Overwrite
            })
        }
        
        # Process the work items
        $workItems | Start-PSYForEachActivity -Name "Synchronizing $($workItems.Count) Table(s) from '$SourceCS' to '$TargetCS'" -ScriptBlock {

            $sourceProviderName = [Enum]::GetName([PSYDbConnectionProvider], $workItems.SourceProvider)
            $targetProviderName = [Enum]::GetName([PSYDbConnectionProvider], $workItems.TargetProvider)

            # TODO: REFACTOR WITH NEW IMPORT
            # Always use Create, Consistent
            # Overwrite only useful when we support incrementals.

            # Export Data (depending on source provider)
            if ($Input.SourceProvider -eq [PSYDbConnectionProvider]::SqlServer) {
                $exportedData = Export-PSYSqlServer -Connection 'Source' -Table $Input.SourceTable
            }
            elseif ($Input.SourceProvider -eq [PSYDbConnectionProvider]::OleDb) {
                $exportedData = Export-PSYOleDbServer -Connection 'Source' -Table $Input.SourceTable
            }

            # Import Data (depending on target provider)
            if ($Input.TargetProvider -eq [PSYDbConnectionProvider]::SqlServer) {
                $exportedData | Import-PSYSqlServer -Connection 'Source' -Table $fqTableName -Overwrite:$Input.Overwrite -AutoIndex:$Input.AutoIndex -AutoCreate:$Input.AutoCreate
            }
            elseif ($Input.SourceProvider -eq [PSYDbConnectionProvider]::OleDb) {
                $exportedData | Import-PSYOleDbServer -Connection 'Source' -Table $Input.TargetTable
            }

            # If 
        }
    }
    catch {
        Write-PSYErrorLog $_ "Error in Sync-PSYDbToDb."
    }
}