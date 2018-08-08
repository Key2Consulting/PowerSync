#Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Remove-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PowerSync\" -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
Copy-Item -Path ".\Script\" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PowerSync\" -Force -Recurse

# If you use the geography type, you must download and install the Microsoft® SQL Server® 2012 SP1 Feature Pack, and include "Type System Version=SQL Server 2012"
# in the Source connection string. https://www.microsoft.com/en-us/download/details.aspx?id=35580