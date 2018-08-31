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
                }
            }

            # Create the target table now
            $targetSchemaTable = ConvertTo-TargetSchemaTable -SourceProvider $InputObject.Provider -TargetProvider $conn.Provider -SchemaTable $InputObject.DataReader.GetSchemaTable()
            Invoke-PSYStoredCommand -Connection $Connection -Name "$providerName.AutoCreate" -Parameters @{Table = $Table; SchemaTable = $targetSchemaTable}
        }

        if (-not $UsePolyBase) {
            # Use SqlBulkCopy to import the data
            $blk = New-Object Data.SqlClient.SqlBulkCopy($conn.ConnectionString)
            $blk.DestinationTableName = "$Table"
            $blk.BulkCopyTimeout = (Get-PSYRegistry 'PSYDefaultCommandTimeout')
            $blk.BatchSize = (Get-PSYRegistry 'PSYDefaultCommandTimeout' 10000)
            $blk.WriteToServer($InputObject.DataReader)
        }
        else {
            # TODO: HOW WILL THIS WORK? POLYBASE REALLY HANDLES THE EXPORT AND IMPORT SIDES OF THE DATA MOVEMENT. IF OUR FILE EXPORTER IS ALREADY
            # EXPORTING, WE WOULD NEED TO CANCEL OR IGNORE IT. WE COULD USE THE CONTEXTUAL INFORMATION (I.E. FILE NAME) FROM THE EXPORTER TO 
            # THEN EXPORT USING POLYBASE.
        }

        # If AutoIndex is set, execute AutoIndex script
        #if ($this.GetConfigSetting("AutoIndex", $true) -eq $true) {
            #[void] $this.RunScript("AutoIndexScript", $false, $additionalConfig)
        #}
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Import-PSYSqlServer."
    }
}