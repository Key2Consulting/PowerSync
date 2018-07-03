# PowerSync #
*Under Development*

The fundamental philosphy of PowerSync is that many data integration operations are repetitive and do not require large scale ETL frameworks to accomplish. The goal of PowerSync is to handle these common scenarios as a library of robust PowerShell commands. These commands can be used individually to tackle administrative/operational tasks, or can be composed into more a sophisticated data integration framework.

*Note that PowerSync prefers an ELT over ETL approach to data integration, and leaves it up to the consumer to transform data according to their requirements.*

Features:
 - Quickly copy a table, view, or the results of query to a target database.
 - Copy single table, or an entire list (manifest) of tables.
 - Dynamically creates target table based on extract query (think SELECT INTO).
 - Can optionally automatically create [clustered columnstore] indexes on target.
 - Does not depend on link servers.
 - Perform full or incremental updates.
 - Can extract data from any ADO.NET or OLEDB compatible data source.
  
 Benefits:
 - Easy to Use
 - Lightweight
 - Portable
 - Procedural
 - Bulk Operations

Situations where PowerSync is not a good fit:
 - When each extraction has custom transformation requirements (it's best suited for repetitive transformations scenarios)
 - Long running processes
 - Highly customized workflows
 
## PowerSync.ps1 ##

## PowerSync-Manifest.ps1 ##
Runs PowerSync for a collection of items defined in a manifest file (CSV format), and performs an Extract, Load, Transform for each item. The TSQL used
at each stage is defined in separate .SQL files and (optionally) passed into PowerSync. PowerSync attempts to pass every field in the manifest into each 
TSQL script using SQMCMD :setvar syntax, and also applies SQLCMD variables that only exist in the script. 

PowerSync-Manifest also supports writebacks to the manifest file itself. This is useful for tracking runtime information like the last incremental 
extraction value (for incremental loads), or the last run date/time.

Scripts are called in the following order:
 1) Preparation (incremental extract range, writebacks)
 2) Extract
 3) Transform
 4) Publish (called once for entire process)
Executed against the source to prepare the extraction (i.e. identify incremental extraction range). Any results returned