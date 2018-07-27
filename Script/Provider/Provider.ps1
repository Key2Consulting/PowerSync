# Represents the abstract base class for the Provider interface
class Provider {
    [string] $Namespace
    [hashtable] $Configuration
    [string] $ConnectionString
    [hashtable] $ConnectionStringParts
    [object] $Connection    

    Provider ([string] $Namespace, [hashtable] $Configuration) {
        $this.Namespace = $Namespace
        $this.Configuration = $Configuration
        $sb = New-Object System.Data.Common.DbConnectionStringBuilder
        $this.ConnectionString = $Configuration."${Namespace}ConnectionString"
        $sb.set_ConnectionString($this.ConnectionString)
        $this.ConnectionStringParts = $sb
    }
}