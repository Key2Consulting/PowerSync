try {
    Connect-PSYOleDbRepository -ConnectionString ""
    Connect-PSYJsonRepository -LogPath "Log.json" -ConfigurationPath "Configuration.json"
    Connect-PSYCsvRepository -LogPath "Log.csv" -ConfigScalarPath "Scalar.csv" -ConfigManifestPath "Manifest.csv" -ConfigConnectionPath "Connections.csv"

    New-Connection -Name "FileSource" -ConnectionString "Foo;Server=$(Get-PSYConfig 'FileSourceServer')"
    Get-Connection -Name "Target"

    Start-PSYFlowActivity -ScriptBlock {
        Export-PSYSqlDatFiles -FilePathMin "\\sourcefiles\\$($ConsolidateFiles.LastLoadedDate)\\*.dat" -FilePathMax "\\sourcefiles\\$($ConsolidateFiles.NextLoadedDate)\\*.dat" `
            | Import-PSYTextFiles -Format "CSV" Header $true ObjectListQuery "\\targetfiles\\$(Get-Date)\\*.csv" -MaxRowsPerFile 1000000
    }

    Start-PSYFlowActivity -ScriptBlock {
        Export-PSYOleDb -ExtractScript "SELECT * FROM dbo.Foo" -Timeout = 3600 `
            | Import-PSYSqlServer -Schema "Load" -Table "Foo" -AutoCreate $true
    }

    Start-PSYActivity -Name "Sync Data From Server A to B" -ScriptBlock {
        Start-PSYFlowActivity -Name "Process each manifest item" -Throttle 5 -Enumerate "MyManifestName" -ContinueOnError -ScriptBlock {
            Export-PSYOleDb -Name $that.Table -ExtractScript "SELECT * FROM dbo.$($that.Table) WHERE DT > $($that.LastDT)" -Timeout = 3600 `
                | Import-PSYSqlServer -Schema "Load" -Table "$($that.Table)" -AutoCreate $true
            Invoke-PSYCommand -Connection "Target" -Command "INLINE SQL" -Parameters $that -Writeback
        }
        Invoke-PSYCommand -Connection "Target" -Script "Publish.sql" -Parameters $that
    }

    $q = New-PSYCompiledScript -ScriptPath "Foo.sql" -Parameters @{}
}
catch {
    Write-PSYException $_
}