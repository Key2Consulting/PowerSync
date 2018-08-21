class FileRepository : Repository {
    # Locking
    [string] $LockPath              # file used to acquire an exclusive lock to the file repository
    [int] $LockTimeout = 5000       # number of milliseconds to keep trying to acquire exclusive lock to the file repository
    # Logging
    [System.Collections.ArrayList] $ActivityLog
    [System.Collections.ArrayList] $ExceptionLog
    [System.Collections.ArrayList] $InformationLog
    [System.Collections.ArrayList] $VariableLog
    # Configuration
    [System.Collections.ArrayList] $State
    [System.Collections.ArrayList] $Connection
    [System.Collections.ArrayList] $Registry

    FileRepository () {
        $this.LockPath = "PSYRepoLock.txt"
        # These lists simulate in-memory tables of a database
        $this.ActivityLog = New-Object System.Collections.ArrayList
        $this.ExceptionLog = New-Object System.Collections.ArrayList
        $this.InformationLog = New-Object System.Collections.ArrayList
        $this.VariableLog = New-Object System.Collections.ArrayList
        $this.State = New-Object System.Collections.ArrayList
        $this.Connection = New-Object System.Collections.ArrayList
        $this.Registry = New-Object System.Collections.ArrayList
    }

    [void] SaveRepository() {
        throw "The file repository SaveRepository method should be overridden by derived classes."
    }

    [void] LoadRepository() {
        throw "The file repository LoadRepository method should be overridden by derived classes."
    }

    [object] GetEntity([type] $EntityType, [object] $EntityID) {
        # Load this entity based on its type and identifier
        if ($EntityType -eq [ActivityLog]) {
            return $this.ActivityLog.Where({$_.ID -eq $EntityID})[0]
        }
        elseif ($EntityType -eq [ExceptionLog]) {
            return $this.ExceptionLog.Where({$_.ID -eq $EntityID})[0]
        }
        elseif ($EntityType -eq [InformationLog]) {
            return $this.InformationLog.Where({$_.ID -eq $EntityID})[0]
        }
        elseif ($EntityType -eq [VariableLog]) {
            return $this.VariableLog.Where({$_.ID -eq $EntityID})[0]
        }
        elseif ($EntityType -eq [State]) {
            return $this.State.Where({$_.Name -eq $EntityID})[0]
        }
        return $null
    }

    [void] SaveEntity([object] $Entity) {
        # Save this item based on its type
        if ($Entity -is [ActivityLog]) {
            $this.ActivityLog.Add($Entity)
        }
        elseif ($Entity -is [ExceptionLog]) {
            $this.ExceptionLog.Add($Entity)
        }
        elseif ($Entity -is [InformationLog]) {
            $this.InformationLog.Add($Entity)
        }
        elseif ($Entity -is [VariableLog]) {
            $this.VariableLog.Add($Entity)
        }
        elseif ($Entity -is [State]) {
            $this.State.Add($Entity)
        }

        $this.SaveRepository()
    }
    
    [void] DeleteEntity([type] $EntityType, [object] $EntityID) {
        # Delete this entity based on its type and identifier
        if ($EntityType -eq [ActivityLog]) {
            $this.ActivityLog.Remove($this.ActivityLog.Where({$_.ID -eq $EntityID})[0])
        }
        elseif ($EntityType -eq [ExceptionLog]) {
            $this.ExceptionLog.Remove($this.ExceptionLog.Where({$_.ID -eq $EntityID})[0])
        }
        elseif ($EntityType -eq [InformationLog]) {
            $this.InformationLog.Remove($this.InformationLog.Where({$_.ID -eq $EntityID})[0])
        }
        elseif ($EntityType -eq [VariableLog]) {
            $this.VariableLog.Remove($this.VariableLog.Where({$_.ID -eq $EntityID})[0])
        }
        elseif ($EntityType -eq [State]) {
            $this.State.Remove($this.State.Where({$_.Name -eq $EntityID})[0])
        }
        $this.SaveRepository()
    }

    # Synchronously executes a scriptblock as an atomic unit, blocking any other process attempting a critical section.
    [object] CriticalSection([scriptblock] $ScriptBlock) {
        $file = $null
        try {
            # Acquire an exclusive lock to the repository using a separate file who's sole purpose is to control locking.  If
            # acquiring a lock fails, keep trying for a specified amount of time.
            foreach ($retries in 1..100) {
                try {
                    $file = [System.IO.File]::Open($this.LockPath, 'OpenOrCreate', 'ReadWrite', 'None')
                    break
                }
                catch {
                    # Couldn't acquire, so we sleep for a bit then try again.
                    Start-Sleep -Milliseconds (100 / $this.LockTimeout)
                }
            }

            # Lock acquired
            
            # Reload the repository in case another process made changes.
            $this.LoadRepository()

            # Execute the scriptblock (any call to Save should be included in the script).
            $r = Invoke-Command -ScriptBlock $ScriptBlock
            if ($r) {
                return $r
            }
            else {
                return $null
            }
        }
        catch {
            throw "CriticalSection of $($this.GetType()) failed. $($_.Exception.Message)"
        }
        finally {
            $file.Close()
            Remove-Item $this.LockPath
        }
    }
}