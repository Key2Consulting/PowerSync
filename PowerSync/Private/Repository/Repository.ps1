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
    [object] SearchLogs([string] $Search, [bool] $Wildcards) {
        throw "Method should be overridden by derived classes."
    }

    # Removes an activity from a queue, blocking other concurrent processes which might be doing the same.
    [object] DequeueActivity([string] $Queue) {
        throw "Method should be overridden by derived classes."
    }

    # Common repository utility routines
    #
}