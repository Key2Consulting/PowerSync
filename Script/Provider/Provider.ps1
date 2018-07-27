# Represents the abstract base class for the Provider interface
class Provider {
    [string] $Namespace
    [hashtable] $Configuration
    [string] $ConnectionString
    [hashtable] $ConnectionStringParts
    [object] $Connection

    Provider ([string] $Namespace, [hashtable] $Configuration) {
        $this.Namespace = $Namespace
        $this.Configuration = $Configuration
        $sb = New-Object System.Data.Common.DbConnectionStringBuilder
        $this.ConnectionString = $Configuration."${Namespace}ConnectionString"
        $sb.set_ConnectionString($this.ConnectionString)
        $this.ConnectionStringParts = $sb
    }

    # Loads a TSQL script from disk, applies any SQLCMD variables passed in, and returns the compiled script.
    [string] CompileScript([string]$ScriptName) {
        # The script variable could either be a file path or an actual script, so attempt
        # to load the script from disk first to figure it out.
        $scriptPath = $this.Configuration["$($this.Namespace)$ScriptName"]
        $vars = $this.Configuration
        try {
            $script = [IO.File]::ReadAllText($scriptPath)
        }
        catch {
            $script = $scriptPath       # must be an actual script
        }

        # This regular expression is used to identify :setvar commands in the TSQL script, and uses capturing 
        # groups to separate the variable name from the value.
        $regex = ':setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9 .]*)"?'
        # Find the next match, remove the :setvar line from the script, but also replace
        # any reference to it with the actual value. This eliminates any SQLCMD syntax from
        # the script prior to execution.
        do {
            $match = [regex]::Match($script, $regex)
            if ($match.Success) {
                $script = $script.Remove($match.Index, $match.Length)
                $name = $match.Groups[1]
                $value = $match.Groups[2]
                if ($vars."$name") {
                    $value = $vars."$name"
                }
                $script = $script.Replace('$(' + $name + ')', $value)
            }
        } while ($match.Success)
        # if ($script.Length -eq 0) {
        #     throw "Script $scriptPath was specified, but does not contain any TSQL logic."
        # }
        return $script
    }

    [object] GetConfigSetting([string] $Setting, [object] $DefaultValue) {
        if ($this.Configuration.ContainsKey($Setting)) {
            return $this.Configuration[$Setting]
        }
        else {
            return $DefaultValue
        }
    }
}