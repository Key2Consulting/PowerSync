<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Represents the abstract base class for the Provider interface and provides common functionality. Every PS component (Source, Target, Manifest, Log) must support:
 - Namespaces so that multiple providers with the same configuration property don't collide.
 - Connection information.
 - Scripting capability. The script language and supported keywords are provider specific. For instance, a Text provider may use REGEX, while a RDBMS uses TSQL.
#>
class Provider {
    [string] $Namespace                     # so that providers with same property names don't collide
    [hashtable] $Configuration              # the combined/merged configurations from both command-line and manifest
    [string] $ConnectionString              # extracted from the Configuration for convenience
    [hashtable] $ConnectionStringParts      # extracted from the ConnectionString for convenience
    [object] $Connection                    # any connection created by provider

    Provider ([string] $Namespace, [hashtable] $Configuration) {
        $this.Namespace = $Namespace
        $this.Configuration = $Configuration
        $sb = New-Object System.Data.Common.DbConnectionStringBuilder
        $this.ConnectionString = $Configuration."${Namespace}ConnectionString"
        $sb.set_ConnectionString($this.ConnectionString)
        $this.ConnectionStringParts = $sb
    }

    [object] RunScript([string] $ScriptName, [bool] $SupportWriteback, [hashtable] $AdditionalConfiguration) {
        # If caller has additional configuration to apply on top of provider configuration
        if ($AdditionalConfiguration) {
            $h = $this.Configuration + $AdditionalConfiguration
        }
        else {
            $h = $this.Configuration
        }
        
        # Compile and execute the script
        $compiledScript = $this.CompileScript($ScriptName, $h)
        if ($compiledScript -ne "") {
            $r = $this.ExecScript($compiledScript)
            # If writeback is supported, enumerate the response and apply it to the current configuration.
            if ($SupportWriteback) {
                $writeback = [ordered] @{}
                if ($r -is [System.Data.IDataReader]) {
                    # Copy results into hashtable (only single row supported)
                    $null = $r.Read()
                    for ($i=0;$i -lt $r.FieldCount; $i++) {
                        $col = $r.GetName($i)
                        $writeback."$col" = $r[$col]
                    }
                    $writeback.'RuntimeID' = $this.Configuration.RuntimeID
                }
                else {
                    throw "Unsupported writeback response type."    # we can easily support a few other universal types i.e. hashtables
                }
                return $writeback
            }
            else {
                return $r
            }
        }

        return $null
    }

    # Implemented by derived classes to execute a compiled script against the configured data source. Not intended to be called directly.
    [object] ExecScript([string] $CompiledScript) {
        throw "Not Implemented"
    }

    # Implemented by derived classes to cleanup after execution. Not intended to be called directly.
    [void] Close() {
    }
    
    # Loads a TSQL script from disk, applies any SQLCMD variables passed in, and returns the compiled script. The final script should have no
    # reference to SQLCMD syntax, meaning :setvars that aren't set by the configuration should still get replaced/substituted.
    [string] CompileScript([string]$ScriptName) {
        return $this.CompileScript($ScriptName, $null)
    }

    [string] CompileScript([string]$ScriptName, [hashtable] $Vars) {
        # The script variable could either be a file path or an actual script, so attempt
        # to load the script from disk first to figure it out.
        $scriptPath = $this.GetConfigSetting($ScriptName, $null)
        if ($scriptPath -eq $null) {
            return ""
        }
        try {
            $script = [IO.File]::ReadAllText($scriptPath)
        }
        catch {
            $script = $scriptPath       # must be an actual script
        }

        # This regular expression is used to identify :setvar commands in the TSQL script, and uses capturing 
        # groups to separate the variable name from the value.
        # Use non-PS quote for debugging REGEx:  :setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9_\[\](',) .]*)"?.*\r?\n?
        $regex = ':setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9_\[\]('',) .]*)"?.*\r?\n?'
        # Find the next match, remove the :setvar line from the script, but also replace
        # any reference to it with the actual value. This eliminates any SQLCMD syntax from
        # the script prior to execution.
        do {
            $match = [regex]::Match($script, $regex)
            if ($match.Success) {
                $script = $script.Remove($match.Index, $match.Length)
                $name = $match.Groups[1].Value
                $value = $match.Groups[2].Value
                if ($Vars.ContainsKey($name) -eq $true) {
                    $value = $Vars."$name"
                    # Manually convert bools to numeric (0 or 1) since they are native to database systems.
                    if ($value -is [bool] -and $value) {
                        $value = 1
                    }
                    elseif ($value -is [bool] -and $value -eq $false) {
                        $value = 0
                    }
                }
                $script = $script.Replace('$(' + $name + ')', $value)
            }
        } while ($match.Success)
        # if ($script.Length -eq 0) {
        #     throw "Script $scriptPath was specified, but does not contain any TSQL logic."
        # }
        return $script
    }

    # Sets the default script for cases where clients do not supply one. Typically, default
    # scripts are platform specific and defined within the concrete provider.
    [void] SetDefaultScript([string] $ScriptName, [string] $DefaultScript) {
        if ($this.Configuration.ContainsKey("$($this.Namespace)$ScriptName") -eq $false) {
            $path = Resolve-Path -Path "$PSScriptRoot\..\DefaultScript\$DefaultScript"
            $this.Configuration.Add("$($this.Namespace)$ScriptName", $path)
        }
    }

    # Returns a configuration property, or a default value if doesn't exist.
    [object] GetConfigSetting([string] $Setting, [object] $DefaultValue) {
        $key = "$($this.Namespace)$Setting"
        if ($this.Configuration.ContainsKey($key)) {
            return $this.Configuration[$key]
        }
        else {
            return $DefaultValue
        }
    }

    # Returns a unique identifier using a GUID
    [string] GetUniqueID() {
        return $this.GetUniqueID("", 100)
    }
    
    [string] GetUniqueID([string] $BaseToken, [int]$MaxLength) {
        $guid = (New-Guid).ToString().Replace("-", "")
    
        # If BaseToken is passed in, add the GUID to the end of the BaseToken
        if ($BaseToken) {
            $r = $BaseToken + "_" + $guid
        }
        else {
            $r = $guid
        }   

        # If MaxLength is passed in, limit the GUID to MaxLength characters
        if ($MaxLength -gt 0 -and $r.Length -gt $MaxLength){
            $r = $r.Substring(0, $MaxLength)
        }

        return $r
    }

    # Performs basic logging for a provider
    [void] HandleException($Exception) {
        # Identify where the exception originally occurred, then bubble the error up.
        $callerName = (Get-PSCallStack)[1].Command
        throw "Error in $callerName" + $Exception.ToString()
    }
}