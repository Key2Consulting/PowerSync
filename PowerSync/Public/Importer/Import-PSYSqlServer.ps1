function Import-PSYSqlServer {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "Automatically creates the target table, if it doesn't exist, based on the exported data's schema.", Mandatory = $false)]
        [switch] $Create,
        [Parameter(HelpMessage = "Overwrites the target data, oppose to appending it. If Create is set, the entire table is recreated. Use this option if new columns may appear in source data.", Mandatory = $false)]
        [switch] $Overwrite,
        [Parameter(HelpMessage = "Automatically creates a clustered or nonclustered columnstore index. Used in conjunction with Create flag.", Mandatory = $false)]
        [switch] $Index,
        [Parameter(HelpMessage = "Adds compression to the target table. Used in conjunction with Create flag.", Mandatory = $false)]
        [switch] $Compress,
        [Parameter(HelpMessage = "Performs the append or overwrite in a transactionally consistent manner by first importing into a new table and then publishing from there within a transaction.", Mandatory = $false)]
        [switch] $Consistent,
        [Parameter(HelpMessage = "Timeout before aborting the import operation.", Mandatory = $false)]
        [int] $Timeout,
        [Parameter(HelpMessage = "Uses PolyBase to import the data instead of SqlBulkCopy.", Mandatory = $false)]
        [switch] $PolyBase
    )

    try {
        # Initialize target connection
        $conn = Get-PSYConnection -Name $Connection
        $providerName = [Enum]::GetName([PSYDbConnectionProvider], $conn.Provider)
        $targetSchemaTable = @(ConvertTo-TargetSchemaTable -SourceProvider $InputObject.Provider -TargetProvider $conn.Provider -SchemaTable $InputObject.DataReader.GetSchemaTable())
        $reader = $InputObject.DataReader

        # Information about the final table we're importing into.
        $finalTableCreated = $false
        $finalSchema = (Select-TablePart -Table $Table -Part 'Schema' -Clean)
        $finalTable = (Select-TablePart -Table $Table -Part 'Table' -Clean)
        $finalTableFQN = "[$finalSchema].[$finalTable]"
        
        # Information about the load table we're importing into (if we load first as part of consistent operation).
        $loadTableCreated = $false
        $loadSchema = $finalSchema
        $loadTable = "Import_$finalTable"                # load into a table prefixed with Import_
        $loadTableFQN = "[$loadSchema].[$loadTable]"

        # Determine if final table exists
        $finalExists = (Invoke-PSYCmd -Connection $Connection -Name "$providerName.CheckIfTableExists" -Param @{Table = $finalTableFQN}).TableExists

        # If Consistent, we must update data in a transactionally consistent manner. We can't just truncate and re-insert 
        # since that leaves the table in an inconsistent state. Even data appended to a table is queryable and inconsistent.
        # In this scenario, we use both the final and load tables.
        if ($Consistent) {
            # Create the target table based on the data reader's schema.
            Invoke-PSYCmd -Connection $Connection -Name "$providerName.DropTable" -Param @{Table = $loadTableFQN}      # drop load table if exists, occurs during failures
            Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoCreate" -Param @{Table = $loadTableFQN; SchemaTable = $targetSchemaTable}
            # Note: no need to create final table in this case. It either exists already, and we're reusing it. Or it 
            # doesn't exist, and we'll swap the load table as the final during publish.
            $loadTableCreated = $true
            Write-PSYVerboseLog -Message "Created table [$Connection]:$loadTableFQN."
        }
        else {
            # If Create, create the final table if doesn't exist. If not consistent, we need to rebuild now since there's no
            # publish step. Read the schema of the input stream and use that information to create a target table. In this scenario,
            # we only use the final table.
            if ($Create) {
                
                # If the table exists and we're overwriting it, drop it first.
                if ($finalExists -and $Overwrite) {
                    Invoke-PSYCmd -Connection $Connection -Name "$providerName.DropTable" -Param @{Table = $finalTableFQN}
                    Write-PSYVerboseLog -Message "Dropped existing table [$Connection]:$finalTableFQN."
                }
                # Create the target table based on the data reader's schema.
                if (-not $finalExists -or $Overwrite) {
                    Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoCreate" -Param @{Table = $finalTableFQN; SchemaTable = $targetSchemaTable}
                    $finalTableCreated = $true
                    Write-PSYVerboseLog -Message "Created table [$Connection]:$finalTableFQN."
                }
            }
        }

        # Determine if we require type conversion. If we don't, we use the original data reader, which is faster by roughly 20%. If we
        # do, we instantiate our TypeConversionDataReader class and wrap the original data reader to provide the necessary conversion.
        # NOTE: Type conversion is required by data types that require special conversion rules (e.g. Geography) during transport or persistence.
        foreach ($col in $targetSchemaTable) {
            if ($col['TransportDataTypeName'] -isnot [System.DBNull]) {
                $reader = New-Object PowerSync.TypeConversionDataReader($InputObject.DataReader, $targetSchemaTable[0].Table)
                break
            }
        }

        # If we're not using PolyBase, use SqlBulkCopy to import the data, the fastest option aside from BCP and PolyBase.
        if (-not $PolyBase) {
            $blk = New-Object Data.SqlClient.SqlBulkCopy($conn.ConnectionString)
            $blk.DestinationTableName = if ($Consistent) { $loadTableFQN } else { $finalTableFQN }
            $blk.BulkCopyTimeout = (Get-PSYVariable 'PSYDefaultCommandTimeout')
            $blk.BatchSize = (Get-PSYVariable -Name 'PSYDefaultCommandTimeout' -DefaultValue 10000)
            $blk.WriteToServer($reader)
        }
        else {
            # TODO: HOW WILL THIS WORK? POLYBASE REALLY HANDLES THE EXPORT AND IMPORT SIDES OF THE DATA MOVEMENT. IF OUR FILE EXPORTER IS ALREADY
            # EXPORTING, WE WOULD NEED TO CANCEL OR IGNORE IT. WE COULD USE THE CONTEXTUAL INFORMATION (I.E. FILE NAME) FROM THE EXPORTER TO
            # THEN EXPORT USING POLYBASE.
        }

        # Apply options applicable after the data has loaded
        if ($finalTableCreated) {
            # If Index is set and the final table was just created, execute AutoIndex script to create the index. Do this after the initial
            # load since inserting into a CCIX is more resource intensive. We need to create the index anytime a new final table is created.
            if ($Index) {
                Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoIndex" -Param @{Table = $finalTable; Schema = $finalSchema; IndexSuffix = $Table}
                Write-PSYVerboseLog -Message "Created index for [$Connection]:$finalTableFQN."
            }
            # Compression is a similar situation to Index.
            if ($Compress) {
                Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoCompress" -Param @{Table = $finalTable; Schema = $finalSchema}
                Write-PSYVerboseLog -Message "Added compression to [$Connection]:$finalTableFQN."
            }
        }
        if ($loadTableCreated -and -not $finalExists) {
            # If Index is set and the load table was just created, but not the final table, create the index. If the final table already
            # existed, the publish will insert the load data into it, which means there's no performance benefit for creating the CCIX. If
            # it doesn't exist, the publish script will swap the load table as the publish table, so in that case we need the CCIX on the load.
            if ($Index) {
                Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoIndex" -Param @{Table = $loadTable; Schema = $loadSchema; IndexSuffix = $Table}
                Write-PSYVerboseLog -Message "Created index for [$Connection]:$finalTableFQN."
            }
            # Compression is a similar situation to Index.
            if ($Compress) {
                Invoke-PSYCmd -Connection $Connection -Name "$providerName.AutoCompress" -Param @{Table = $loadTable; Schema = $loadSchema}
                Write-PSYVerboseLog -Message "Added compression to [$Connection]:$finalTableFQN."
            }
        }

        # If we're running consistent, still need to publish the table.
        if ($Consistent) {
            Invoke-PSYCmd -Connection $Connection -Name "$providerName.PublishTable" -Param @{
                FinalTable = $finalTable
                FinalSchema = $finalSchema
                LoadTable = $loadTable
                LoadSchema = $loadSchema
                Create = $Create
                Overwrite = $Overwrite
            }
        }

        Write-PSYInformationLog -Message "Imported $providerName data to [$Connection]:$Table."
    }
    catch {
        Write-PSYErrorLog $_ "Error in Import-PSYSqlServer."
    }
}