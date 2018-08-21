class FileRepository : Repository {
    # Locking
    [string] $LockPath              # file used to acquire an exclusive lock to the file repository
    [int] $LockTimeout = 5000       # number of milliseconds to keep trying to acquire exclusive lock to the file repository
    [hashtable] $TableList          # a list of lists, simulating in-memory tables of a database

    FileRepository () {
        # These lists simulate in-memory tables of a database
        $this.TableList.ActivityLog = New-Object System.Collections.ArrayList
        $this.TableList.ExceptionLog = New-Object System.Collections.ArrayList
        $this.TableList.InformationLog = New-Object System.Collections.ArrayList
        $this.TableList.State = New-Object System.Collections.ArrayList
        $this.TableList.Connection = New-Object System.Collections.ArrayList
        $this.TableList.Registry = New-Object System.Collections.ArrayList
    }

    [void] SaveRepository() {
        throw "The file repository SaveRepository method should be overridden by derived classes."
    }

    [void] LoadRepository() {
        throw "The file repository LoadRepository method should be overridden by derived classes."
    }

    [System.Collections.ArrayList] GetEntityTable([type] $EntityType) {
        # Retrieve the table for this entity
        $table = $this.TableList[$EntityType.GetType().Name]
        if (-not $table) {
            throw "GetEntityTable encountered unknown type $($EntityType.Name)."
        }
        return $table
    }

    [string] GetEntityKey([type] $EntityType) {
        # Entities generally use ID as their key, with few exceptions
        $keyField = 'ID'
        if ($EntityType -eq [State]) {
            $keyField = "Name"
        }        
        return $keyField
    }

    [object] GetEntity([type] $EntityType, [object] $EntityID) {
        $table = $this.GetEntityTable($EntityType)
        return $table.Where({$_."$($this.GetEntityTable($EntityType))" -eq $EntityID})[0]
    }

    [void] SaveEntity([object] $Entity) {
        $table = $this.GetEntityTable($Entity.GetType())
        $key = $this.GetEntityKey($Entity.GetType())
        $existing = $this.GetEntity($Entity.GetType(), $info[1])

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
        try {
            # Grab an exclusive lock
            $mutex = New-Object System.Threading.Mutex($false, "ae831404-511f-4577-ba63-56a21fd70425")
            $null = $mutex.WaitOne($this.LockTimeout)
            
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
            $mutex.ReleaseMutex()
        }
    }
}