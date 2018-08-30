function Import-PSYSqlServer {
    param
    (
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
        $c = Get-PSYConnection -Name $Connection

        # If AutoCreate, read the schema of the input stream and use that information to create a target table.
        if ($AutoCreate) {
            # If the table exists and the overwrite flag isn't set, it's an error condition.
        }

        if (-not $UsePolyBase) {
            # Use SqlBulkCopy to import the data
            $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
            $blk.DestinationTableName = "$($this.Schema).$loadTableName"
            $blk.BulkCopyTimeout = $this.Timeout
            $blk.BatchSize = $this.GetConfigSetting("BatchSize", 10000)
            $blk.WriteToServer($DataReader)
        }
        else {
            # TODO: HOW WILL THIS WORK? POLYBASE REALLY HANDLES THE EXPORT AND IMPORT SIDES OF THE DATA MOVEMENT. IF OUR FILE EXPORTER IS ALREADY
            # EXPORTING, WE WOULD NEED TO CANCEL OR IGNORE IT. WE COULD USE THE CONTEXTUAL INFORMATION (I.E. FILE NAME) FROM THE EXPORTER TO 
            # THEN EXPORT USING POLYBASE.
        }

        # If AutoIndex is set, execute AutoIndex script
        if ($this.GetConfigSetting("AutoIndex", $true) -eq $true) {
            [void] $this.RunScript("AutoIndexScript", $false, $additionalConfig)
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Import-PSYSqlServer."
    }
}