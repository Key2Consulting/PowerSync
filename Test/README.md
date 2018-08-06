# Unit Tests
In order to run the unit tests, you must install SQL Server LocalDB.  The following configuration was used:
 - SQL Server 2017
 - Instance:  (LocalDb)\MSSQLLocalDB
 - Visual Studio Code 1.24 as our text editor/debugger

Afterwards, simply run the RunTests.ps1 script.

Note that the structures created within script are for demonstration purposes. Clients can connect or connect PowerSync to their 
specific logging and manifest sources using custom configuration scripts specified in the command line.