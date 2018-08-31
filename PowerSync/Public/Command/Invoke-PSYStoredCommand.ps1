function Invoke-PSYStoredCommand {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [hashtable] $Parameters
    )

    $c = $null
    try {
        $cmdText = New-PSYStoredCommand -Name $Name -Parameters $Parameters
        $connDef = Get-PSYConnection -Name $Connection
        $providerName = [Enum]::GetName([PSYDbConnectionProvider], $connDef.Provider)
        $c = New-FactoryObject -Connection -TypeName $providerName

        $c.ConnectionString = $connDef.ConnectionString
        $c.Open()
        $cmd = $c.CreateCommand()
        $cmd.CommandText = $cmdText
        $cmd.CommandTimeout = (Get-PSYRegistry 'PSYDefaultCommandTimeout')
        $r = $cmd.ExecuteReader()
        
        # Copy results into arraylist of hashtables
        $results = New-Object System.Collections.ArrayList
        if ($r.HasRows) {
            while ($r.Read()) {
                $result = [ordered] @{}
                for ($i=0;$i -lt $r.FieldCount; $i++) {
                    $col = $r.GetName($i)
                    $result."$col" = $r[$i]
                }
                [void] $results.Add($result)
            }
        }
        if ($results.Count -gt 0) {
            return $results
        }
    }
    catch {
        if ($c) {
            if ($c.State -eq "Open") {
                $c.Close()
            }
            $c.Dispose()
        }
        Write-PSYExceptionLog -ErrorRecord $_ -Message 'Error in Invoke-PSYStoredCommand'
    }
}