# PowerSync
The fundamental philosphy of PowerSync is that many data integration operations are repetitive and do not require large scale ETL frameworks to accopmlish. The goal of PowerSync is to handle these common scenarios as a library of robust PowerShell commands. These commands can be used individually to tackle administrative/operational tasks, or can be composed into more a sophisticated data integration framework. 

*Note that PowerSync prefers an ELT over ETL approach to data integration.*

Features:
 - Quickly copy a table, view, or the results of query to a target database.
 - Copy single table, or an entire list (manifest) of tables.
 - Does not depend on link servers.
 - Perform Full or Incremental updates.
 
 Benefits:
 - Lightweight
 - Portable
 - Procedural
 - High Performance (all operations performed in bulk)