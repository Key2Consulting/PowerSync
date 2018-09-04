<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Represents the abstract base class for the DataProvider interface, including common functionality.
#>
class DataProvider : Provider {
    [int] $Timeout = 3 * 3600   # 3 hours
    [string] $Schema
    [string] $Table
    [System.Collections.ArrayList] $SchemaInfo

    # Constructor - assumes derived class will create the Connection object in its constructor
    DataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.Schema = $this.GetConfigSetting("Schema", "")
        $this.Table = $this.GetConfigSetting("Table", "")
    }

    # Prepares the source or target prior to extract/load
    [hashtable] Prepare() {
        throw "Not Implemented"
        return $null;
    }

    # Extracts from source returning an IDataReader and a list of SchemaInformation objects describing the schema of the data 
    # set using standard ANSI SQL data types.
    [object[]] Extract() {
        throw "Not Implemented"
    }

    # Loads into target using an IDataReader interface, and includes the SchemaInfo list so that the target 
    # has the option of generating its target table dynamically.
    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        throw "Not Implemented"
    }
    
    # Transforms data on the target after the load has completed.
    [hashtable] Transform() {
        throw "Not Implemented"
        return $null;
    }

    # Destroys any any managed resources, and prepares for provider termination.
    [void] Close() {
        # Don't throw not implemented exception since this is optional
    }
}

# Defines a standard set of schema attributes describing the source data feed structure. Should follow ANSI SQL standards.
class SchemaInformation {
    [string] $Name
    [int] $Size
    [int] $Precision
    [int] $Scale
    [bool] $IsKey
    [bool] $IsNullable
    [bool] $IsIdentity
    [string] $DataType      # VARCHAR, CHAR, BIT, SMALLINT, INTEGER, DECIMAL, DATE, TIME
}