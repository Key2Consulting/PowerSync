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
                $this.State.TableList.ActivityLog = [System.Collections.ArrayList] $data.ActivityLog
                $this.State.TableList.ErrorLog = [System.Collections.ArrayList] $data.ErrorLog
                $this.State.TableList.MessageLog = [System.Collections.ArrayList] $data.MessageLog
                $this.State.TableList.VariableLog = [System.Collections.ArrayList] $data.VariableLog
                $this.State.TableList.QueryLog = [System.Collections.ArrayList] $data.QueryLog
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
                ActivityLog = $this.State.TableList.ActivityLog
                ErrorLog = $this.State.TableList.ErrorLog
                MessageLog = $this.State.TableList.MessageLog
                VariableLog = $this.State.TableList.VariableLog
                QueryLog = $this.State.TableList.QueryLog
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $this.State.Path -Force
        }
        catch {
            throw "Json SaveRepository failed. $($_.Exception.Message)"
        }
    }
}