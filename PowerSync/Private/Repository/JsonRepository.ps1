class JsonRepository : FileRepository {

    # The initial construction of the Repository
    JsonRepository ([string] $Path, [int] $LockTimeout, [hashtable] $State) : base($LockTimeout, $State) {
        $this.State.Path = $Path
    }

    # The rehydration of the Repository via the factory
    JsonRepository ([hashtable] $State) : base($State) {
    }

    [void] LoadRepository([string] $EntityType) {
        # Attempt to initialize from the existing log and configuration files. Limit to a single entity type, if specified.
        $path = $this.State.Path.TrimEnd('\')
        if ($EntityType -eq 'All') {
            $this.State.TableList.Variable =  [System.Collections.ArrayList] (Get-Content -Path "$path\PSYVariable.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.Connection = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYConnection.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.Activity = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYActivity.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.ErrorLog = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYErrorLog.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.MessageLog = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYMessageLog.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.VariableLog = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYVariableLog.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
            $this.State.TableList.QueryLog = [System.Collections.ArrayList] (Get-Content -Path "$path\PSYQueryLog.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
        }
        else {
            $this.State.TableList[$EntityType] =  [System.Collections.ArrayList] (Get-Content -Path "$path\PSY$EntityType.json" -ErrorAction SilentlyContinue | ConvertFrom-Json)
        }
    }

    [void] SaveRepository([string] $EntityType) {

        # Write the JSON files. Limit to a single entity type, if specified.
        $path = $this.State.Path.TrimEnd('\')
        if ($EntityType -eq 'All') {
            ConvertTo-Json -InputObject $this.State.TableList.Variable -Depth 5 | Set-Content -Path "$path\PSYVariable.json"
            ConvertTo-Json -InputObject $this.State.TableList.Connection -Depth 5 | Set-Content -Path "$path\PSYConnection.json"
            ConvertTo-Json -InputObject $this.State.TableList.Activity -Depth 5 | Set-Content -Path "$path\PSYActivity.json"
            ConvertTo-Json -InputObject $this.State.TableList.ErrorLog -Depth 5 | Set-Content -Path "$path\PSYErrorLog.json"
            ConvertTo-Json -InputObject $this.State.TableList.MessageLog -Depth 5 | Set-Content -Path "$path\PSYMessageLog.json"
            ConvertTo-Json -InputObject $this.State.TableList.VariableLog -Depth 5 | Set-Content -Path "$path\PSYVariableLog.json"
            ConvertTo-Json -InputObject $this.State.TableList.QueryLog -Depth 5 | Set-Content -Path "$path\PSYQueryLog.json"
        }
        else {
            $json = ConvertTo-Json -InputObject $this.State.TableList[$EntityType] -Depth 5
            
            if ($json.Length -eq 0) {
                throw "Unexpected Error: $EntityType produced empty Json string during save."
            }
            Set-Content -Path "$path\PSY$EntityType.json" -Value $json

            if ([System.IO.File]::ReadAllText("$path\PSY$EntityType.json").Length -eq 0) {
                throw "Unexpected Error: PSY$EntityType.json is empty during save."
            }    
        }
    }
}