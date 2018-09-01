<#
.SYNOPSIS
Compiles a Stored Command.

.DESCRIPTION
Stored Commands are SQL files defined as part of a PowerSync project with the purpose of executing a TSQL command against a database connection. This function compiles a Stored Command with the given parameters and returns the script, but does not execute it. See Invoke-PSYCmd for more information.

Stored Commands accept parameters using the SQLCMD Mode syntax of :setvar and $(VarName). All SQLCMD Mode syntax is removed prior to execution, so Stored Commands work against non-SQL Server databases. Any defined variable reference that's not explicitly passed in as a parameter gets replaced with the :setvar's value (i.e. a default).

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
function Resolve-PSYCmd {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [hashtable] $Param
    )

    try {
        # Determine paths to search for stored commands
        $storedCommandPath = Get-PSYVariable 'PSYCmdPath'
        $searchPaths = New-Object System.Collections.ArrayList
        if ($storedCommandPath) {
            [void] $searchPaths.AddRange($storedCommandPath.Split(';'))
        }
        [void] $searchPaths.Add($PSYSession.Module + '\Asset\*.*')      # always add our current module location as a the final default
        
        # Find the stored command along the path in order they're entered
        $template = ""
        foreach ($path in $searchPaths) {
            $files = @(Get-ChildItem -Path $path -Recurse -Filter "$Name.*" -File)
            if ($files.Length -gt 0) {
                $template = [System.IO.File]::ReadAllText($files[0].FullName)
                break
            }
        }

        # TODO: SHOULD AUTOMATICALLY PASS CERTAIN CONTEXTUAL VARIABLES (E.G. ActivityID FOR LOGGING PURPOSES)

        # Compile the template using the given parameters. Compilation uses a SQLCMD Mode syntax of :setvar and $(MyVariable).
        #
        if (-not $Param) {     # if no parameters, perhaps the template is ready to go
            return $template
        }
        
        # This regular expression is used to identify :setvar commands in the TSQL script, and uses capturing 
        # groups to separate the variable name from the value.
        # Use non-PS quote for debugging REGEx:  :setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9_\[\](',) .]*)"?.*\r?\n?
        $regex = ':setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9_\[\]('',) .]*)"?.*\r?\n?'

        # Find the next match, remove the :setvar line from the script, but also replace
        # any reference to it with the actual value. This eliminates any SQLCMD syntax from
        # the script prior to execution.
        do {
            $match = [regex]::Match($template, $regex)
            if ($match.Success) {
                $template = $template.Remove($match.Index, $match.Length)
                $name = $match.Groups[1].Value
                $value = $match.Groups[2].Value
                # If we have a parameter with that name
                if ($Param.ContainsKey($name) -eq $true) {
                    $value = $Param."$name"
                    # Perform conversion of the parameter to account for specific scenarios.
                    if ($value -is [bool]) {
                        # Manually convert bools to numeric (0 or 1) since they are native to database systems.
                        $value = if ($value) {1} else {0}
                    }
                    elseif ($value -is [System.Collections.ArrayList] -or $value -is [array]) {
                        # Convert the array into SQL statement in the INSERT VALUES format i.e. ('Field', Field), ('Field', Field).
                        # Passing an array to a script is tricky, so we do this so it's easy to create a table for processing.
                        $sqlValues = ""
                        if ($value[0] -is [System.Data.DataRow]) {
                            foreach ($row in $value) {
                                $sqlValues += '('
                                foreach ($col in $row.Table.Columns) {
                                    $colVal = $row[$col.ColumnName]
                                    if ($colVal -is [string] -or $colVal -is [datetime]) {        # quote the value depending on the type
                                        $sqlValues += "'$colVal',"
                                    }
                                    elseif ($colVal -is [System.DBNull]) {
                                        $sqlValues += "NULL,"
                                    }
                                    else {
                                        $sqlValues += "$colVal,"
                                    }
                                }
                                $sqlValues = $sqlValues.TrimEnd(',') + '),'
                            }
                            $value = $sqlValues.TrimEnd(',')
                        }
                        else {
                            foreach ($row in $value) {
                                $sqlValues += '('
                                foreach ($col in $row.Values) {
                                    if ($col -is [string] -or $col -is [datetime]) {        # quote the value depending on the type
                                        $sqlValues += "'$col',"
                                    }
                                    elseif ($col -is [System.DBNull]) {
                                        $sqlValues += "NULL,"
                                    }
                                    else {
                                        $sqlValues += "$col,"
                                    }
                                }
                                $sqlValues = $sqlValues.TrimEnd(',') + '),'
                            }
                        }
                        $value = $sqlValues.TrimEnd(',')
                    }                
                }
                $template = $template.Replace('$(' + $name + ')', $value)
            }
        } while ($match.Success)

        return $template
    }
    catch {
        Write-PSYErrorLog $_
    }
}