PowerSync can handle basic data integration scenarios using an ELT strategy (Extract, Load, then Transform). The following data integration features are supported:
 - Copy a table or the results of a query into a new target database table.
 - Support a variety of sources and targets. For instance, can copy from CSV files to MySQL, or SQL to SQLDW.
 - Full or incremental extractions.
 - Supports logging, to a variety of targets (i.e. files, database tables).
 - Processing is data driven, so can add/remove data feeds with ease.
 - Highly customizable by client. PowerSync handles the heavy lifting, but leaves case specific requirements to its users.
 - Publish in a transactionally consistent manner (i.e. does not drop then recreate, but rather stages and swaps).

The key concepts in PowerSync are:
 - Manifest: Identifies all data feeds to process. Feeds include a source and target. Manifests can also be written back to, for instance to save last run date.
 - Source: The location where data is being extracted.
 - Target: The destination where data is being loaded and transformed.
 - Log: PowerSync includes a logging framework, which can be integrated into other logging frameworks.
 - Provider Configuration: The set of configurations defined and used by the different provider components (Source, Target, Manifest, Log), and can be set via command line, manifest, or both.
 - Project Configuration: The collection of customizations (scripts, manifests, etc) created and managed by client code.

Manifests are the workhorse of the process. Manifests identify each and every data feed, as well as provider configurations allowing each feed to be 
customized. The provider configuration passed into the command-line is overlayed with configuration retrieved from the manifest (must include namespace 
i.e. SourceTableName instead of just TableName). PowerSync also supports writebacks to the manifest itself. This is useful for tracking runtime 
information like the last incremental extraction value (for incremental loads), the last run date/time, or count of extracted records. Operations are also 
logged to a file.

Events execute in the following order:
 1) Prepare (Source and Target)
 2) Extract (Source)
 3) Load (Target)
 4) Transform (Target)

Client provided scripts are used in each event to support customization. Each script is defined in separate .SQL files and (optionally) 
passed into PowerSync. PowerSync attempts to pass every field from the provider configuration into each script using SQMCMD :setvar syntax, and also applies 
SQLCMD variables that only exist in the script so that the script has no SQLCMD syntax prior to execution.