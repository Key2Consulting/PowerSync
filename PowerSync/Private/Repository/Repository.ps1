# The base repository handling all persistence within PowerSync. Although the base class is not usable by itself, it provides
# core functionality and a contract derived classes must adhere to. The derived classes provide the implementation for the
# specific platform.
#
# Note:
#   - Repository is not thread safe.
#   - Is designed to be instantiated, used, and discarded for every user operation (i.e. command).
#   - State is stored outside of the class to ensure proper marshaling of data for remote jobs.
#   - Assumes all entities have a surrogate identifier named 'ID'
#   - Due to the threading & state limitations, a strongly typed object model isn't used. Instead, every object is a hashtable (preferred over PSObjects for performance). https://powertoe.wordpress.com/2011/03/31/combining-objects-efficiently-use-a-hash-table-to-index-a-collection-of-objects/
#
class Repository {
    [hashtable] $State      # the only pointer we have to our state for this class and all derived classes

    Repository ([hashtable] $State) {
        $this.State = $State
        $this.State.LockTimeout = 30000                         # max time to hold the mutex (cross process synchronization) in milliseconds
        $this.State.ClassType = $this.GetType().FullName        # needed to support rehydration via New-FactoryObject
    }

    # CRUD operations. Note that deserializers like JSON convert into a PSObject, so we can't use strong typing. Instead, we
    # use a simple string representing the type (i.e. $EntityType).
    #

    # Creates an entity.
    [void] CreateEntity([string] $EntityType, [object] $Entity) {
        throw "Method should be overridden by derived classes."
    }
    
    # Reads (or gets) and entity by ID.
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        throw "Method should be overridden by derived classes."
    }
    
    # Updates an entity.
    [void] UpdateEntity([string] $EntityType, [object] $Entity) {
        throw "Method should be overridden by derived classes."
    }

    # Deletes an entity by ID.
    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        throw "Method should be overridden by derived classes."
    }

    # Finds an entity by an alternate key (i.e. Name) instead of ID. Can return multiple results.
    [object] FindEntity([string] $EntityType, [string] $EntityField, [object] $EntityFieldValue) {
        return $this.FindEntity($EntityType, $EntityField, $EntityFieldValue, $false)
    }
    
    [object] FindEntity([string] $EntityType, [string] $EntityField, [object] $EntityFieldValue, [bool] $Wildcards) {
        throw "Method should be overridden by derived classes."
    }
    
    # Special Purpose Operations (required for optimization, concurrency, or complexity).
    #
    
    # Search and returns logs containing a term.
    [object] SearchLogs([string[]] $SearchTerms, [bool] $Wildcards) {
        throw "Method should be overridden by derived classes."
    }

    # Removes an activity from a queue, blocking other concurrent processes which might be doing the same.
    [object] DequeueActivity([string] $Queue) {
        throw "Method should be overridden by derived classes."
    }

    # Common repository utility routines
    #
    
    # Synchronously executes a scriptblock as an atomic unit, blocking any other process attempting a critical section. This is used
    # to ensure concurrency when performing certain muli-step data storage operations requiring synchronization. Derived classes can
    # opt out of synchronizing across processes by overriding this method and removing the mutex.
    #
    # Global lock
    [object] CriticalSection([scriptblock] $ScriptBlock) {
        return $this.CriticalSection('f9f98a02-f7c2-47fd-aecc-090b9015a47d', $ScriptBlock)        # TODO: MAKE GLOBAL LOCK NAME SPECIFIC TO PHYSICAL REPOSITORY
    }

    # Specific lock
    [object] CriticalSection([string] $LockName, [scriptblock] $ScriptBlock) {
        return $this.CriticalSection($LockName, $ScriptBlock, $null, $null)
    }

    # Specific lock with Pre/Post processing
    [object] CriticalSection([string] $LockName, [scriptblock] $ScriptBlock, [scriptblock] $PreScriptBlock, [scriptblock] $PostScriptBlock) {
        try {
            # Grab an exclusive lock using a Mutex, which works across process spaces.
            $mutex = New-Object System.Threading.Mutex($false, "Global\$LockName")
            [void] $mutex.WaitOne($this.State.LockTimeout)
            Write-Debug "Acquired mutex Global\PSY-$LockName"       # can't use Write-PSYDebugLog since it writes to the repo and acquires a lock
            
            # Execute the scriptblock
            if ($PreScriptBlock) {
                Invoke-Command -ScriptBlock $PreScriptBlock
            }

            $r = Invoke-Command -ScriptBlock $ScriptBlock
            
            if ($PostScriptBlock) {
                Invoke-Command -ScriptBlock $PostScriptBlock
            }

            if ($r) {
                return $r
            }
            else {
                return $null
            }
        }
        catch {
            throw "CriticalSection of $($this.State.ClassType) failed. $($_.Exception.Message)"
        }
        finally {
            $mutex.ReleaseMutex()
            Write-Debug "Released mutex Global\PSY-$LockName"       # can't use Write-PSYDebugLog since it writes to the repo and acquires a lock
        }
    }
}