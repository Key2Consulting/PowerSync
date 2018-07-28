# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class DataProvider : Provider {
    [int] $Timeout = 3 * 3600   # 3 hours
    [string] $TableName

    # Constructor - assumes derived class will create the Connection object in its constructor
    DataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.TableName = $this.GetConfigSetting("TableName", "")
    }

    [hashtable] Prepare() {
        throw "Not Implemented"
        return $null;
    }

    [System.Data.Common.DbDataReader] Extract() {
        throw "Not Implemented"
    }

    [hashtable] Load([System.Data.Common.DbDataReader] $DataReader) {
        throw "Not Implemented"
    }
    
    [hashtable] Transform() {
        throw "Not Implemented"
        return $null;
    }

    [void] Close() {
    }

    <# 
    # Cleans up any open connections or other unmanaged resources
    [void] Close() {
        if ($this.Connection -ne $null) {
            $this.Connection.Close()
        }
    }

    # Creates a SQL command
    [System.Data.Common.DbCommand] CreateCommand([string]$CommandText) {
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $CommandText
        $cmd.CommandTimeout = $this.Timeout
        return $cmd
    }

    # Executes a script without expecting a result set
    [void] ExecNonQuery([string]$Script) {
        $cmd = $this.CreateCommand($Script)
        $cmd.ExecuteNonQuery()
    }
    
    # Executes a script and expects a result set
    [System.Data.Common.DbDataReader] ExecReader([string]$Script) {
        $cmd = $this.CreateCommand($Script)
        $reader = $cmd.ExecuteReader()
        return $reader
    }
    
    # Retrieves the SchemaTable of the given query (the columns returned and their data type)
    [object] GetQuerySchema([string]$Query) {
        throw "Not Implemented"
        return $null
    }

    # Generates a CREATE TABLE script based on a SchemaTable
    [string] ScriptCreateTable([string]$TableName, [object]$TableSchema) {
        throw "Not Implemented"
        return $null
    }
    
    # Performs the heavy lifting of copying data from the source (DataReader) to the destination (TableName)
    [void] BulkCopyData([System.Data.Common.DbDataReader]$DataReader, [string]$TableName) {
        throw "Not Implemented"
    }

    # Renames a given table, optionally overwriting it if already exists
    [void] RenameTable([string]$OldTableName, [string]$NewTableName, [switch]$Overwrite) {
        throw "Not Implemented"
    } #>
}