class FileRepository : Repository {

    # The initial construction of the FileRepository
    FileRepository ([int] $LockTimeout, [hashtable] $State) : base([hashtable] $State) {
        $this.State.LockTimeout = $LockTimeout      # number of milliseconds to keep trying to acquire exclusive lock to the file repository
        $this.State.TableList = @{                  # a list of lists, simulating in-memory tables of a database
            ActivityLog = New-Object System.Collections.ArrayList
            ErrorLog = New-Object System.Collections.ArrayList
            MsgLog = New-Object System.Collections.ArrayList
            VariableLog = New-Object System.Collections.ArrayList
            QueryLog = New-Object System.Collections.ArrayList
            Variable = New-Object System.Collections.ArrayList
            Connection = New-Object System.Collections.ArrayList
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

    [void] CreateEntity([string] $EntityType, [object] $Entity) {
        # Assign the new entity a surrogate key
        if (-not $Entity.ID) {
            $Entity.ID = New-Guid
        }
        # Add the entity to our table
        $table = $this.GetEntityTable($EntityType)
        [void] $table.Add($Entity)
    }
    
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        $table = $this.GetEntityTable($EntityType)
        $e = $table.Where({$_.ID -eq $EntityID})
        if ($e) {
            # In case the Json contains non-native types, convert to native
            $entityHash = ConvertTo-PSYNativeType $e
            return $entityHash
        }
        else {
            return $null
        }
        return $e[0]
    }

    [void] UpdateEntity([string] $EntityType, [object] $Entity) {
        $table = $this.GetEntityTable($EntityType)
        $existing = $table.Where({$_.ID -eq $Entity.ID})[0]      # we can't use ReadEntity for this since it reloads the repo and we'll get a different entity instance
        
        # The updated entity is already passed into this method, but we want to keep it's position in the repository.
        $position = $table.IndexOf($existing)
        $table.Remove($existing)
        if ($position -gt -1) {
            $table.Insert($position, $Entity)
        }
        else {
            $table.Add($Entity)
        }
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        $table = $this.GetEntityTable($EntityType)
        $match = $table.Where({$_.ID -eq $EntityID})
        if ($match.Count -eq 0) {
            throw "Unable to find $EntityType with ID $EntityID."
        }
        $table.Remove($match[0])
    }

    [object] FindEntity([string] $EntityType, [string] $SearchField, [object] $SearchValue, [bool] $Wildcards) {
        $entityList = New-Object System.Collections.ArrayList
        $table = $this.GetEntityTable($EntityType)
        if ($Wildcards) {
            $eQuery = $table.Where({$_."$SearchField" -like $SearchValue})
        }
        else {
            $eQuery = $table.Where({$_."$SearchField" -eq $SearchValue})
        }
        if ($eQuery) {
            foreach ($entity in $eQuery) {
                # In case the Json contains non-native types, convert to native
                $entityNative = ConvertTo-PSYNativeType $entity
                [void] $entityList.Add($entityNative)
            }
        }
        return $entityList
    }

    # Overrides base class behavior to require the complete reloading and resaving of the JSON repository after after operation.
    [object] CriticalSection([string] $LockName, [scriptblock] $ScriptBlock) {
        # The file repository doesn't read/write specific parts of the file like a database does. However, it
        # must still deal with concurrency when multiple threads are invoking the repo simultaneously. Instead,
        # the repo will read and write the entire file for every operation. It's slower, but ensures consistency.
        # A database repository should be used in process intensive scenarios.

        return ([Repository]$this).CriticalSection("ae831404-511f-4577-ba63-56a21fd70425", $ScriptBlock, {
            # Reload the repository in case another process made changes
            $this.LoadRepository()
        }, {
            # Save the repository back to disk
            $this.SaveRepository()
            })
    }
}