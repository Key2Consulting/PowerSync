Start-PSYMainActivity -ConnectScriptBlock {
    Connect-PSYOleDbRepository -ConnectionString "" -EnvironmentPath "Environment.json"
    Connect-PSYSqlServerRepository -Server "" -Database "or default" -TrustedConnection -User "" -Password "" -AttachDbFile ""
    Connect-PSYJsonRepository -LogPath "Log.json" -ConfigurationPath "Configuration.json"
    Connect-PSYCsvRepository -LogPath "Log.csv" -ConfigPath "Config.csv" -ManifestPath "Manifest.csv" -ConnectionPath "Connection.csv"
} -ScriptBlock {

    New-PSYConnection -Name "FileSource" -ConnectionString "Foo;Server=$(Get-PSYConfig 'FileSourceServer')"
    Get-PSYConnection -Name "Target"

    Start-PSYActivity -ScriptBlock {
        $s = Get-PSYState 'MyControl' 'defaultvalue'

        $c = Get-PSYState 'MyControl'       # defaults to single
        $c = Get-PSYState 'MyControl' -List
        $c = Get-PSYState 'MyControl' -List 'MyCustomState'
        $c['Step'] = 1
        
        Export-PSYSqlDatFiles -FilePathMin "\\sourcefiles\\$($ConsolidateFiles.LastLoadedDate)\\*.dat" -FilePathMax "\\sourcefiles\\$($ConsolidateFiles.NextLoadedDate)\\*.dat" `
            | Import-PSYTextFiles -Format "CSV" Header $true ObjectListQuery "\\targetfiles\\$(Get-Date)\\*.csv" -MaxRowsPerFile 1000000
    }
    
    Start-PSYParallelActivity -ScriptBlock [{
        Export-PSYOleDb -ExtractScript "SELECT * FROM dbo.Foo1" -Timeout = 3600 `
            | Import-PSYSqlServer -Schema "Load" -Table "Foo1" -AutoCreate $true
    }, {
        Export-PSYOleDb -ExtractScript "SELECT * FROM dbo.Foo2" -Timeout = 3600 `
            | Import-PSYSqlServer -Schema "Load" -Table "Foo2" -AutoCreate $true
    }]

    Start-PSYActivity -Name "Sync Data From Server A to B" -ScriptBlock {
        
        Get-PSYState 'Feed' $m
        Start-PSYForEachActivity -ForEach 'FeedItem' -In 'Feed' -ScriptBlock {
        }

        Start-PSYForEachActivity -Enumerate $m -ScriptBlock {
            param ($that)
            $that.Field = 123
            Checkpoint-PSYState
            Checkpoint-PSYState $that
        }

        Start-PSYForEachActivity -Name "Process each manifest item" -Throttle 5 -Enumerate $m -ContinueOnError -ScriptBlock {
            param ($that)
            Export-PSYOleDb -Name $that.Table -Connection "Source" -ExtractScript "SELECT * FROM dbo.$($that.Table) WHERE DT > $($that.LastDT)" -Timeout = 3600 `
                | Import-PSYSqlServer -Connection "Target" -Schema "Load" -Table "$($that.Table)" -AutoCreate $true
            Invoke-PSYCommand -Connection "Target" -Command "INLINE SQL" -Parameters $that -Writeback
            Checkpoint-PSYState $m
        }
        Invoke-PSYCommand -Connection "Target" -Script "Publish.sql" -Parameters (Get-PSYManifest -"MyManifestName")      # always returns ArrayList of Hashtables (different than internal execquery)
    }

    $q = New-PSYCompiledScript -ScriptPath "Foo.sql" -Parameters @{}

    $r = Invoke-PSYCommand -Connection "Source" -Script "SELECT DynTables"
    Merge-PSYManifest -Name "MyDynamicTableList" -Manifest $r       # Merge upserts, New creates
}

<# 
KIT TABLES
Configuration.Connection
Configuration.Activity (ID, Name, Script, Server, LastExecutedDateTime, CustomProperties.json)
Configuration.Manifest (ID, Name)
Configuration.ManifestItem (ID, ManifestID, Name, SourceConnection, SourceObject, TargetConnection, TargetObject, CustomProperties.json)
Configuration.Entry
Log.Execution (is this just an activity?)
Log.Activity (ID, Name, Script, ...)
Log.Information
Log.Exception
Log.Variable (old and new)
Custom.* (used to host hooks PS calls so clients can add customizations)
Custom.ManifestScenarioA (view from Manifest, extracting columns, joining to runtime variables)
Custom.ManifestB

QUESTIONS
 - Should the RDBMS Repository use sprocs or scripts?  Should we create a VSDB project?
 - Term to describe single NameValue configuration?
 - Should we break out Manifest (the collection) from its contents (the items)?

 OTHER
  - CLI for log reporting (active executions, errors, activity within past 24 hours, etc)
  - Archive old entries (logging, config activities, etc).  Can base on usage.
 #>