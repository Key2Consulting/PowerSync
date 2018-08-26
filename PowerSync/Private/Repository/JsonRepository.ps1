class JsonRepository : FileRepository {
    [string] $Path

    JsonRepository ([string] $Path) {
        $this.Path = $Path
    }

    # Loads from a previously serialized data
    JsonRepository ([object] $SerializedData) {
        $this.Path = $SerializedData.Path
    }

    [void] LoadRepository() {
        # Attempt to initialize from the existing log and configuration files. If it fails, it will be recreated on save.
        try {
            $data = Get-Content -Path $this.Path -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($data) {
                $this.TableList.State = [System.Collections.ArrayList] $data.State
                $this.TableList.Connection = [System.Collections.ArrayList] $data.Connection
                $this.TableList.Registry = [System.Collections.ArrayList] $data.Registry
                $this.TableList.ActivityLog = [System.Collections.ArrayList] $data.ActivityLog
                $this.TableList.ExceptionLog = [System.Collections.ArrayList] $data.ExceptionLog
                $this.TableList.InformationLog = [System.Collections.ArrayList] $data.InformationLog
                $this.TableList.VariableLog = [System.Collections.ArrayList] $data.VariableLog
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
                State = $this.TableList.State
                Connection = $this.TableList.Connection
                Registry = $this.TableList.Registry
                ActivityLog = $this.TableList.ActivityLog
                ExceptionLog = $this.TableList.ExceptionLog
                InformationLog = $this.TableList.InformationLog
                VariableLog = $this.TableList.VariableLog
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $this.Path
        }
        catch {
            throw "Json SaveRepository failed. $($_.Exception.Message)"
        }
    }

    [hashtable] Serialize() {
        return @{
            TypeName = $this.GetType().Name
            Path = $this.Path
        }
    }
}