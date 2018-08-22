class JsonRepository : FileRepository {
    [string] $LogPath
    [string] $ConfigurationPath

    JsonRepository ([string] $LogPath, [string] $ConfigurationPath) {
        $this.LogPath = $LogPath
        $this.ConfigurationPath = $ConfigurationPath
    }

    [void] LoadRepository() {
        # Attempt to initialize from the existing log and configuration files. If it fails, it will be recreated on save.
        try {
            $log = Get-Content -Path $this.LogPath -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($log) {
                $this.TableList.ActivityLog = [System.Collections.ArrayList] $log.ActivityLog
                $this.TableList.ExceptionLog = [System.Collections.ArrayList] $log.ExceptionLog
                $this.TableList.InformationLog = [System.Collections.ArrayList] $log.InformationLog
                $this.TableList.VariableLog = [System.Collections.ArrayList] $log.VariableLog
            }

            $config = Get-Content -Path $this.ConfigurationPath -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($config) {
                $this.TableList.State = [System.Collections.ArrayList] $config.State
                $this.TableList.Connection = [System.Collections.ArrayList] $config.Connection
                $this.TableList.Registry = [System.Collections.ArrayList] $config.Registry
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
                ActivityLog = $this.TableList.ActivityLog
                ExceptionLog = $this.TableList.ExceptionLog
                InformationLog = $this.TableList.InformationLog
                VariableLog = $this.TableList.VariableLog
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $this.LogPath

            @{
                State = $this.TableList.State
                Connection = $this.TableList.Connection
                Registry = $this.TableList.Registry
            } | ConvertTo-Json -Depth 5 | Set-Content -Path $this.ConfigurationPath
        }
        catch {
            throw "Json SaveRepository failed. $($_.Exception.Message)"
        }
    }  
}