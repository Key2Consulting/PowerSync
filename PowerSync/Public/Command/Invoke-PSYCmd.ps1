<#
.SYNOPSIS
Invokes a Stored Command.

.DESCRIPTION
Stored Commands are SQL files defined as part of a PowerSync project with the purpose of executing a TSQL command against a database connection. 

Stored Commands accept parameters using the SQLCMD Mode syntax of :setvar and $(VarName). All SQLCMD Mode syntax is removed prior to execution, so Stored Commands work against non-SQL Server databases. Any defined variable reference that's not explicitly passed in as a parameter gets replaced with the :setvar's value (i.e. a default).

If the Stored Command returns a resultset, it is converted into an ArrayList of hashtables and returned to the caller.

.PARAMETER Connection
The connection to execute the Stored Query against.

.PARAMETER Name
The name of the Stored Command used to find the SQL file. The extension can be omitted.

.PARAMETER Param
Hashtable of SQLCMD Mode parameters to pass into the script. If a hash field is an array list, it is converted into a SQL statement in the INSERT VALUES format i.e. ('A', B), ('C', D).

.EXAMPLE
Invoke-PSYCmd -Connection 'MyConnection' -Name "PublishMyDataSets" -Param @{ProcessingMode = 'Full'; AllowNulls = $true}

.NOTES
 - This function will recursively search for files matching the Name parameter within all folders defined by the PSYCmdPath variable. 
 - The following example sets the path: Set-PSYVariable -Name 'PSYCmdPath' -Value $PSScriptRoot
 - It's recommended to set the path to your root project folder so that any Stored Command is recursively found.
#>
function Invoke-PSYCmd {
    param
    (
        [Parameter(Mandatory = $false)]
        [string] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [hashtable] $Param
    )

    $conn = $null
    try {
        $cmdText = Resolve-PSYCmd -Name $Name -Param $Param
        $connDef = Get-PSYConnection -Name $Connection
        $providerName = [Enum]::GetName([PSYDbConnectionProvider], $connDef.Provider)
        $conn = New-FactoryObject -Connection -TypeName $providerName

        $conn.ConnectionString = $connDef.ConnectionString
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $cmdText
        $cmd.CommandTimeout = (Get-PSYVariable -Name 'PSYDefaultCommandTimeout')
        Write-PSYQueryLog -Name $Name -Connection $Connection -Query $cmdText -Param $Param
        $r = $cmd.ExecuteReader()
        
        # Copy results into arraylist of hashtables
        $results = [System.Collections.ArrayList]::new()
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
        if ($conn) {
            if ($conn.State -eq "Open") {
                $conn.Close()
            }
            $conn.Dispose()
        }
        Write-PSYErrorLog $_
    }
}