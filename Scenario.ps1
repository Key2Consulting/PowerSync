<#
Set-PSYDbConnection
Invoke-PSYDbCommand
Export-PSYDb
Export-PSYSqlDat
Import-PSYDb ???
Import-PSYSqlServer -UsePolyBase -AutoCreate
Import-PSYTextFile -Compress -Format CSV

Get-PSYRegistry
Set-PSYRegistry
 - Have system entries, like PSYStoredQueryPath, DefaultExportTimeout, DefaultImportTimeout, DefaultThrottle, etc

 #>
Connect-PSYOleDbRepository -ConnectionString 'SQL20;CDSPS'

Set-PSYConnection -Provider OleDb -ConnectionString $myConn1 -Name 'OPDW'

Export-PSYSqlDatFile -Path 'D:\DataFiles\2017\Oct\' -FileList

Start-PSYActivity -Name 'Import Explicit Tables to Cloud Hub' -ScriptBlock {

    # Get list of tables to copy
    $list = Get-PSYVariable -Name 'O to C Explicit'
    foreach ($item in $list.Children) {
        $extract = New-PSYQuery -Query "SELECT $($item.ExtractColumnList) FROM $($item.SourceTable) WHERE ModifiedDateTime >= '$($item.LastModifiedDateTime)'"
        Export-PSYOleDb -Connection 'OPDW' -ExtractQuery $extract | Import-PSYOleDb -Connection 'CPDW' -Table $item.TargetTable -AutoCreate -Overwrite
        $stage = New-PSYQuery -Template "Stage OtoC" -Parameters $item
        Invoke-PSYCommand -Connection "Target" -Query $stage
        $list.LastModifiedDateTime = Get-Date
        Set-PSYVariable -Variable $list
    }

    # Get list of tables to copy
    $list = Invoke-PSYCommand -Query "SELECT * FROM User.DataFeed WHERE Scenario = 'OtoC Explicit'"
    foreach ($item in $list) {
        $extract = New-PSYQuery -Query "SELECT $($item.ExtractColumnList) FROM $($item.SourceTable) WHERE ModifiedDateTime >= '$($item.LastModifiedDateTime)'"
        Export-PSYOleDb -Connection 'OPDW' -ExtractQuery $extract | Import-PSYOleDb -Connection 'CPDW' -Table $item.TargetTable -AutoCreate -Overwrite
        $stage = New-PSYQuery
        Invoke-PSYCommand -Connection "Target" -StoredQuery "Stage OtoC" -Parameters $item
        Invoke-PSYCommand -Connection "Target" -Query "UPDATE User.DataFeed SET LastModifiedDateTime = GETDATE() WHERE ID = $($item.ID)"
    }
}

Invoke-PSYCommand -Connection "Target" -Template 'Publish'