Process
 - Activity
	- Extract
	- Load
	- Other...

State
 - Execution: Everytime PowerSync is executed (save file path, server, user, etc)
	- ExecutionDetailLog (New/get connections)
	- ActivityLog (DataFeed, etc)
		- ActivityDetail (table extracted, table loaded, rows processed
 - VariableLog (NewValue, OldValue, correlation to current step)

 - Terms: ExecutionLog, ActivityLog, InformationLog, ExceptionLog, VariableLog

Configuration
 - Scalar
 - Manifest (ID, Category, Table)
 - Connections

The framework is the kit i.e. AzureSQL State Kit

Model
	• Connections
		○ Methods:  Initialize, Search, Open, 
		○ Properties:  Credentials, Path/ConnString, 
	• Activity
	• Extractor / Loader
		○ Methods:  Initialize, Enumeration, Read(item), Write(item), Finalize
		○ Properties:  Max Parallel
	• Logger
	• State
	• Configuration
Kit (complete end-to-end template?)