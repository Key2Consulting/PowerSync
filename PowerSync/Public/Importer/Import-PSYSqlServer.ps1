function Import-PSYSqlServer {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ImportQuery,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $AutoIndex,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $AutoCreate,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $UsePolyBase
    )

    try {
        # Initialize target connection
        $conn = Get-PSYConnection -Name $Connection
        $providerName = [Enum]::GetName([PSYDbConnectionProvider], $conn.Provider)
        $targetSchemaTable = @(ConvertTo-TargetSchemaTable -SourceProvider $InputObject.Provider -TargetProvider $conn.Provider -SchemaTable $InputObject.DataReader.GetSchemaTable())
        $reader = $InputObject.DataReader

        # If AutoCreate, read the schema of the input stream and use that information to create a target table.
        if ($AutoCreate) {
            # If the table exists and the overwrite flag isn't set, it's an error condition.
            $exists = Invoke-PSYStoredCommand -Connection $Connection -Name "$providerName.CheckIfTableExists" -Parameters @{Table = $Table}
            if ($exists.TableExists) {
                if (-not $Overwrite) {
                    throw "Target table '$Table' already exists, and Overwrite not set. Aborting import operation."
                }
                else {
                    # Otherwise, if it's set, drop the target table.
                    Invoke-PSYStoredCommand -Connection $Connection -Name "$providerName.DropTable" -Parameters @{Table = $Table}
                    Write-PSYVerboseLog -Message "Dropped existing table [$Connection]:$Table."
                }
            }

            # Create the target table now
            Invoke-PSYStoredCommand -Connection $Connection -Name "$providerName.AutoCreate" -Parameters @{Table = $Table; SchemaTable = $targetSchemaTable}
            Write-PSYVerboseLog -Message "Created table [$Connection]:$Table."
        }

        # Determine if we require type conversion. If we don't, we use the original data reader, which is faster by about 20%. If we
        # do, we instantiate our TypeConversionDataReader class and wrap the original data reader to provide the necessary conversion.
        foreach ($col in $targetSchemaTable) {
            if ($col['TransportDataTypeName'] -isnot [System.DBNull]) {
                $reader = New-Object PowerSync.TypeConversionDataReader($InputObject.DataReader, $targetSchemaTable[0].Table)
                break
            }
        }

        # If we're not using PolyBase, use SqlBulkCopy to import the data, the fastest option aside from BCP and PolyBase.
        if (-not $UsePolyBase) {
            $blk = New-Object Data.SqlClient.SqlBulkCopy($conn.ConnectionString)
            $blk.DestinationTableName = "$Table"
            $blk.BulkCopyTimeout = (Get-PSYVariable 'PSYDefaultCommandTimeout')
            $blk.BatchSize = (Get-PSYVariable -Name 'PSYDefaultCommandTimeout' -DefaultValue 10000)
            $blk.WriteToServer($reader)
        }
        else {
            # TODO: HOW WILL THIS WORK? POLYBASE REALLY HANDLES THE EXPORT AND IMPORT SIDES OF THE DATA MOVEMENT. IF OUR FILE EXPORTER IS ALREADY
            # EXPORTING, WE WOULD NEED TO CANCEL OR IGNORE IT. WE COULD USE THE CONTEXTUAL INFORMATION (I.E. FILE NAME) FROM THE EXPORTER TO 
            # THEN EXPORT USING POLYBASE.
        }

        # If AutoIndex is set, execute AutoIndex script
        if ($AutoIndex) {
            Invoke-PSYStoredCommand -Connection $Connection -Name "$providerName.AutoIndex" -Parameters @{Table = $Table}
            Write-PSYVerboseLog -Message "Autocreated index for [$Connection]:$Table."
        }
        #if ($this.GetConfigSetting("AutoIndex", $true) -eq $true) {
            #[void] $this.RunScript("AutoIndexScript", $false, $additionalConfig)
        #}
        
        Write-PSYInformationLog -Message "Imported $providerName data to [$Connection]:$Table."
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Import-PSYSqlServer."
    }
}