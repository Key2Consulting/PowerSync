class FileRepository : Repository {
    [int] $maxLockAttempts = 20
    [int] $lockWaitDuration = 500

    # The initial construction of the FileRepository
    FileRepository ([int] $LockTimeout, [hashtable] $State) : base([hashtable] $State) {
        $this.State.LockTimeout = $LockTimeout      # number of milliseconds to keep trying to acquire exclusive lock to the file repository
        $this.State.TableList = @{                  # a list of lists, simulating in-memory tables of a database
            Activity = New-Object System.Collections.ArrayList
            ErrorLog = New-Object System.Collections.ArrayList
            MessageLog = New-Object System.Collections.ArrayList
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
        $this.CriticalSection({
            # Assign the new entity a surrogate key
            if (-not $Entity.ID) {
                $Entity.ID = New-Guid
            }
            # Add the entity to our table
            $table = $this.GetEntityTable($EntityType)
            [void] $table.Add($Entity)
        })
    }
    
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        return $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $e = $table.Where({$_.ID -eq $EntityID})
            if ($e) {
                # In case the Json contains non-native types, convert to native
                $entityHash = ConvertTo-PSYCompatibleType $e
                return $entityHash
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
        })
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        $this.CriticalSection({
            $table = $this.GetEntityTable($EntityType)
            $match = $table.Where({$_.ID -eq $EntityID})
            if ($match.Count -eq 0) {
                throw "Unable to find $EntityType with ID $EntityID."
            }
            $table.Remove($match[0])
        })
    }

    [object] FindEntity([string] $EntityType, [string] $EntityField, [object] $EntityFieldValue, [bool] $Wildcards) {
        $entities = $this.CriticalSection({
            $entityList = New-Object System.Collections.ArrayList
            $table = $this.GetEntityTable($EntityType)
            if ($Wildcards) {
                $eQuery = $table.Where({$_."$EntityField" -like $EntityFieldValue})
            }
            else {
                $eQuery = $table.Where({$_."$EntityField" -eq $EntityFieldValue})
            }
            if ($eQuery) {
                foreach ($entity in $eQuery) {
                    # In case the Json contains non-native types, convert to native
                    $entityNative = ConvertTo-PSYCompatibleType $entity
                    $temp = $entityList.Add($entityNative)
                }
            }
            return $entityList
        })
        # CriticalSection uses Invoke-Command which is subject to PowerShell unboxing rules, converting empty arrays to 
        # null and converting arrays with a single item to just that item. Ensure an array is always returned.
        if (-not $entities) {
            $entities = @()     # null case
        }
        return @($entities)     # single item case
    }

    [object] SearchLogs([string] $Search, [bool] $Wildcards) {
        # Search all logs in the repository and return any that match
        $entities = $this.CriticalSection({
            $logs = [System.Collections.ArrayList]::new()
            if (-not $Type -or $Type -eq 'Debug' -or $Type -eq 'Information' -or $Type -eq 'Verbose') {
                $logs.AddRange($this.FindEntity('MessageLog', 'Message', $Search, $true))
                $logs.AddRange($this.FindEntity('MessageLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Error') {
                $logs.AddRange($this.FindEntity('ErrorLog', 'Message', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'Exception', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'StackTrace', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Variable') {
                $logs.AddRange($this.FindEntity('VariableLog', 'VariableName', $Search, $true))
                $logs.AddRange($this.FindEntity('VariableLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Query') {
                $logs.AddRange($this.FindEntity('QueryLog', 'Query', $Search, $true))
                $logs.AddRange($this.FindEntity('QueryLog', 'ActivityID', $Search, $false))
            }
            
            # If the caller wants to filter on log type, apply that here in addition to above since some logs use
            # shared storage.
            if ($Type) {
                $typeFiltered = $logs | Where-Object {$_.Type -eq $Type}
            }
            else {
                $typeFiltered = $logs
            }

            # If the caller wants to filter on a date range, use the CreatedDateTime field which should
            # exist for every log type.
            $dateFiltered = $typeFiltered | Where-Object {
                ((ConvertFrom-PSYCompatibleType -InputObject $_.CreatedDateTime -Type 'datetime') -ge $StartDate -or -not $StartDate) `
                -and ((ConvertFrom-PSYCompatibleType -InputObject $_.CreatedDateTime -Type 'datetime') -le $EndDate -or -not $EndDate)
            }
            
            # Some log entries can be found multiple times, so remove the duplicates.
            $uniqueLogs = New-Object System.Collections.ArrayList
            foreach ($log in $dateFiltered) {
                $existing = $uniqueLogs | Where-Object { $_.ID -eq $log.ID }
                if (-not $existing) {
                    [void] $uniqueLogs.Add($log)
                }
            }
            
            return $uniqueLogs
        })
        # CriticalSection uses Invoke-Command which is subject to PowerShell unboxing rules, converting empty arrays to 
        # null and converting arrays with a single item to just that item. Ensure an array is always returned.
        if (-not $entities) {
            $entities = @()     # null case
        }
        return @($entities)     # single item case
    }

    [object] DequeueActivity([string] $Queue) {
        return $this.CriticalSection({
            # Get the next activity off the queue (FIFO)
            $q = $this.State.TableList.Activity
            for ($i = 0; $i -lt $q.Count; $i++) {
                $activity = $q[$i]
                # If this activity is on our queue, and isn't being processed by someone else, dequeue and return it.
                if ($activity.Queue -eq $Queue -and $activity.Status -eq 'Started') {
                    $activity.Status = 'Dequeued'
                    $this.UpdateEntity('Activity', $activity)
                    return $activity
                }
            }
            return $null
        })
    }

    # Synchronously executes a scriptblock as an atomic unit, blocking any other process attempting a critical
    # section. The file repository doesn't read/write specific parts of the file like a database does. However,
    # it must still deal with concurrency when multiple threads are invoking the repo simultaneously. Instead,
    # the repo will read and write the entire file for every operation. It's slower, but ensures consistency.
    # A database repository should be used in process intensive scenarios.
    [object] CriticalSection([scriptblock] $ScriptBlock) {
        try {
            # Grab an exclusive lock using a Mutex, which works across process spaces.
            #
            
            # Define the lock name as either the repository file name (if we have it) or a static identifier. Using 
            # file name is safer than the entire path, since the path reference could be different (i.e. relative paths).
            if ($this.State.Path) {
                $LockName = Split-Path -Path $this.State.Path -Leaf
            }
            else {
                $LockName = "GlobalFileRepositoryLock"
            }
            $mutex = New-Object System.Threading.Mutex($false, "Global\PSY-$LockName")
            $acquired = $mutex.WaitOne($this.State.LockTimeout)
            if (-not $acquired) {
                throw "Unable to acquire lock in FileRepository after waiting $($this.State.LockTimeout) milliseconds."
            }
            Write-Debug "Acquired mutex Global\PSY-$LockName"       # can't use Write-PSYDebugLog since it writes to the repo and acquires a lock

            # The critical section should handle concurrency within our process, but we're still getting runtime errors regarding
            # the file already being open. This could be VS Code, or perhaps the Set/Get-Content isn't disposing quick enough. In
            # any case, we attempt to read or write the file maxLockAttempts times before giving up.
            
            # Reload the repository in case another process made changes
            for ($attempts = 0; $attempts -lt $this.maxLockAttempts; $attempts++) {
                try {
                    $this.LoadRepository()
                    break
                }
                catch [System.IO.IOException] {
                    Write-Debug "Load repository locked out for '$($this.State.ClassType)', attempt $attempts of $($this.maxLockAttempts)"
                    Start-Sleep -Milliseconds $this.lockWaitDuration
                }
                if ($attempts -ge $this.maxLockAttempts - 1) {
                    # Unsuccessful, even after the retries.
                    throw "Failed to acquire file lock for '$($this.maxLockAttempts)' in '$($this.State.ClassType)'."
                }
            }

            # Execute the file repository command
            $r = Invoke-Command -ScriptBlock $ScriptBlock
            
            # Save the repository back to disk
            for ($attempts = 0; $attempts -lt $this.maxLockAttempts; $attempts++) {
                try {
                    $this.SaveRepository()
                    break
                }
                catch [System.IO.IOException] {
                    Write-Debug "Save repository locked out for '$($this.State.ClassType)', attempt $attempts of $($this.maxLockAttempts)"
                    Start-Sleep -Milliseconds $this.lockWaitDuration
                }
                if ($attempts -ge $this.maxLockAttempts - 1) {
                    # Unsuccessful, even after the retries.
                    throw "Failed to acquire file lock for '$($this.maxLockAttempts)' in '$($this.State.ClassType)'."
                }
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