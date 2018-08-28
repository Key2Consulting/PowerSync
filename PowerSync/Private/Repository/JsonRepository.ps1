class JsonRepository : FileRepository {

    # The initial construction of the Repository
    JsonRepository ([string] $Path, [int] $LockTimeout, [hashtable] $State) : base($LockTimeout, $State) {
        $this.State.Path = $Path
    }

    # The rehydration of the Repository via the factory
    JsonRepository ([hashtable] $State) : base($State) {
    }

    [void] LoadRepository() {
        # Attempt to initialize from the existing log and configuration files. If it fails, it will be recreated on save.
        try {
            $data = Get-Content -Path $this.State.Path -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($data) {
                $this.State.TableList.Variable = [System.Collections.ArrayList] $data.Variable
                $this.State.TableList.Connection = [System.Collections.ArrayList] $data.Connection
                $this.State.TableList.Registry = [System.Collections.ArrayList] $data.Registry
                $this.State.TableList.ActivityLog = [System.Collections.ArrayList] $data.ActivityLog
                $this.State.TableList.ExceptionLog = [System.Collections.ArrayList] $data.ExceptionLog
                $this.State.TableList.InformationLog = [System.Collections.ArrayList] $data.InformationLog
                $this.State.TableList.VariableLog = [System.Collections.ArrayList] $data.VariableLog
            }
        }
        catch {
            throw "Json LoadRepository failed. $($_.Exception.Message)"
        }
    }

    [void] SaveRepository() {
        try {
            # Since you can't really update just part of a JSON file, we rewrite the entire thing.
            @{
                Variable = $this.State.TableList.Variable
                Connection = $this.State.TableList.Connection
                Registry = $this.State.TableList.Registry
                ActivityLog = $this.State.TableList.ActivityLog
                ExceptionLog = $this.State.TableList.ExceptionLog
                InformationLog = $this.State.TableList.InformationLog
                VariableLog = $this.State.TableList.VariableLog
            } | Convert-Date | ConvertTo-Json -Depth 5 | Set-Content -Path $this.State.Path
        }
        catch {
            throw "Json SaveRepository failed. $($_.Exception.Message)"
        }
    }
}

function Convert-Date {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject
    )

    begin {
    }

    process {
        $x = $InputObject
        $InputObject
    }
    end {

    }
}