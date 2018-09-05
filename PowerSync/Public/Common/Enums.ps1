<#
.DESCRIPTION
Global enumeration types defined by PowerSync.
#>
Enum PSYDbConnectionProvider {
    None = 0
    OleDb = 1
    Odbc = 2
    SqlServer = 3
    MySql = 4
    Oracle = 5
    PostgreSQL = 6
    TextFile = 7
    Json = 8
    Xml = 9
    Yaml = 10
    AzureBlobStorage = 11
    OData = 12
}

Enum PSYTextFileFormat {
    None = 0
    CSV = 1     # comma separated values
    TSV = 2     # tab separated values
}