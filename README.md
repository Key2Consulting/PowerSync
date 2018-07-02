# PowerSync
The fundamental philosphy of PowerSync is that many data integration operations are repetitive and do not require large scale ETL frameworks to accomplish. The goal of PowerSync is to handle these common scenarios as a library of robust PowerShell commands. These commands can be used individually to tackle administrative/operational tasks, or can be composed into more a sophisticated data integration framework. 

*Note that PowerSync prefers an ELT over ETL approach to data integration, and leaves it up to the consumer to transform data according to their requirements.*

Features:
 - Quickly copy a table, view, or the results of query to a target database.
 - Copy single table, or an entire list (manifest) of tables.
 - Dynamically creates target table based on extract query.
 - Can optionally create clustered columnstore indexes on target.
 - Does not depend on link servers.
 - Perform full or incremental updates.
 - Can extract data from any OLEDB compatible data source.
  
 Benefits:
 - Easy to Use
 - Lightweight
 - Portable
 - Procedural
 - Bulk Operations