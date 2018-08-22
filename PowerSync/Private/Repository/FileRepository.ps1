class FileRepository : Repository {
    # Locking
    [string] $LockPath              # file used to acquire an exclusive lock to the file repository
    [int] $LockTimeout = 5000       # number of milliseconds to keep trying to acquire exclusive lock to the file repository
    [hashtable] $TableList = @{}    # a list of lists, simulating in-memory tables of a database

    FileRepository () {
        # These lists simulate in-memory tables of a database
        $this.TableList.ActivityLog = New-Object System.Collections.ArrayList
        $this.TableList.ExceptionLog = New-Object System.Collections.ArrayList
        $this.TableList.InformationLog = New-Object System.Collections.ArrayList
        $this.TableList.VariableLog = New-Object System.Collections.ArrayList
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
        $table = $this.TableList[$EntityType.Name]
        if ($table -eq $null) {
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

    [void] CreateEntity([object] $Entity) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($Entity.GetType())
            $table.Add($Entity)
        })
    }
    
    [object] ReadEntity([type] $EntityType, [object] $EntityID) {
        return $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $key = $this.GetEntityKey($EntityType)
            return $table.Where({$_."$key" -eq $EntityID})[0]
        })
    }

    [void] UpdateEntity([object] $Entity) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($Entity.GetType())
            $key = $this.GetEntityKey($Entity.GetType())
            $existing = $this.ReadEntity($Entity.GetType(), $key)
            
            # The updated entity is already passed into this method, but we want to keep it's position in the repository.
            $position = $table.IndexOf($existing)
            $table.Remove($e)
            if ($position -gt -1) {
                $table.Insert($position, $Entity)
            }
            else {
                $table.Add($Entity)
            }
        })
    }

    [void] DeleteEntity([type] $EntityType, [object] $EntityID) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $key = $this.GetEntityKey($EntityType)
            $table.Remove($table.Where({$key -eq $EntityID}))
        })
    }

    # Synchronously executes a scriptblock as an atomic unit, blocking any other process attempting a critical section.
    [object] CriticalSection([scriptblock] $ScriptBlock) {
        try {
            # The file repository doesn't read/write specific parts of the file like a database does. However, it
            # must still deal with concurrency when multiple threads are invoking the repo simultaneously. Instead,
            # the repo will read and write the entire file for every operation. It's slower, but ensures consistency.
            # A database repository should be used in process intensive scenarios.

            # Grab an exclusive lock
            $mutex = New-Object System.Threading.Mutex($false, "ae831404-511f-4577-ba63-56a21fd70425")
            $null = $mutex.WaitOne($this.LockTimeout)
            
            # Reload the repository in case another process made changes
            $this.LoadRepository()

            # Execute the scriptblock
            $r = Invoke-Command -ScriptBlock $ScriptBlock

            # Save the repository back to disk
            $this.SaveRepository()

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