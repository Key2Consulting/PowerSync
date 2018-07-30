# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class DataProvider : Provider {
    [int] $Timeout = 3 * 3600   # 3 hours
    [string] $TableName
    [System.Collections.ArrayList] $SchemaInfo

    # Constructor - assumes derived class will create the Connection object in its constructor
    DataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.TableName = $this.GetConfigSetting("TableName", "")
    }

    [hashtable] Prepare() {
        throw "Not Implemented"
        return $null;
    }

    [object[]] Extract() {
        throw "Not Implemented"
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        throw "Not Implemented"
    }
    
    [hashtable] Transform() {
        throw "Not Implemented"
        return $null;
    }

    [void] Close() {
    }
}

class SchemaInformation {
    [string] $Name
    [int] $Size
    [int] $Precision
    [int] $Scale
    [bool] $IsKey
    [bool] $IsNullable
    [bool] $IsIdentity
    [string] $DataType
}