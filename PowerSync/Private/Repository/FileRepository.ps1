class FileRepository : Repository {

    # The initial construction of the FileRepository
    FileRepository ([int] $LockTimeout, [hashtable] $State) : base([hashtable] $State) {
        $this.State.LockTimeout = $LockTimeout      # number of milliseconds to keep trying to acquire exclusive lock to the file repository
        $this.State.TableList = @{                  # a list of lists, simulating in-memory tables of a database
            ActivityLog = New-Object System.Collections.ArrayList
            ExceptionLog = New-Object System.Collections.ArrayList
            InformationLog = New-Object System.Collections.ArrayList
            VariableLog = New-Object System.Collections.ArrayList
            StateVar = New-Object System.Collections.ArrayList
            Connection = New-Object System.Collections.ArrayList
            Registry = New-Object System.Collections.ArrayList
        }
    }

    # The rehydration of the Repository via the factory
    FileRepository ([hashtable] $State) : base([hashtable] $State) {
    }

    [void] SaveRepository() {
        throw "The file repository SaveRepository method should be overridden by derived classes."
    }

    [void] LoadRepository() {
        throw "The file repository LoadRepository method should be overridden by derived classes."
    }

    [System.Collections.ArrayList] GetEntityTable([string] $EntityType) {
        # Retrieve the table for this entity
        $table = $this.State.TableList[$EntityType]
        if ($table -eq $null) {
            throw "GetEntityTable encountered unknown type $($EntityType)."
        }
        return $table
    }

    [string] GetEntityKey([string] $EntityType) {
        # Entities generally use ID as their key, with few exceptions
        $keyField = 'ID'
        if ($EntityType -eq 'StateVar') {
            $keyField = "Name"
        }        
        return $keyField
    }

    [void] CreateEntity([string] $EntityType, [object] $Entity) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $table.Add($Entity)
        })
    }
    
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        return $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $key = $this.GetEntityKey($EntityType)
            $e = $table.Where({$_."$key" -eq $EntityID})
            # If the repo returned a PSObject, convert to a hash table (our preferred type)
            if ($e) {
                if ($e[0] -is [psobject]) {
                    $hash = @{}
                    $e[0].PSObject.Properties | foreach { $hash[$_.Name] = $_.Value }
                    return $hash
                }
            }
            else {
                return $null
            }
            return $e[0]
        })
    }

    [void] UpdateEntity([string] $EntityType, [object] $Entity) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $key = $this.GetEntityKey($EntityType)
            $existing = $table.Where({$_."$key" -eq $Entity."$key"})[0]      # we can't use ReadEntity for this since it reloads the repo and we'll get a different entity instance
            
            # The updated entity is already passed into this method, but we want to keep it's position in the repository.
            $position = $table.IndexOf($existing)
            $table.Remove($existing)
            if ($position -gt -1) {
                $table.Insert($position, $Entity)
            }
            else {
                $table.Add($Entity)
            }
        })
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
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
            [void] $mutex.WaitOne($this.State.LockTimeout)
            
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