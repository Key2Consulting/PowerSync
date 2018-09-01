class MSSQLManifestProvider : ManifestProvider {
    [string] $Path

    MSSQLManifestProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    # Reads the manifest from SQL Server
    [System.Collections.ArrayList] FetchManifest() {
        try {
            # Leverage the RunScript functionality to help fetch the data
            $r = $this.RunScript("ReadManifestScript", $false, $null)
            # Build an array of hashtables (i.e. the manifest) from the results
            $manifest = New-Object System.Collections.ArrayList
            while ($r.Read()) {
                $item = [ordered] @{}
                $manifest.Add($item)
                for ($i=0;$i -lt $r.FieldCount; $i++) {
                    $item."$($r.GetName($i))" = $r[$i]
                }
            }
            return $manifest
        }
        catch {
            $this.HandleException($_.exception)
            return $null
        }
    }

    # Writes a single manifest item back to SQL Server
    [void] CommitManifestItem([hashtable]$ManifestItem) {
        try {
            [void] $this.RunScript("WriteManifestScript", $false, $ManifestItem)
        }
        catch {
            $this.HandleException($_.exception)
        }
    }

    # Executes a compiled script against the configured data source
    [object] ExecScript([string] $CompiledScript) {
        try {
            # Execute Query
            $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
            $this.Connection.Open()
            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $CompiledScript
            $cmd.CommandTimeout = $this.GetConfigSetting("Timeout", 60)
            $r = $cmd.ExecuteReader()
            return $r
        }
        catch {
            $this.HandleException($_.exception)
        }
        return $null
    }

    # Clean up any open connections
    [void] Close() {
        if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
            $this.Connection.Close()
        }
    }
}