Remove-Item -Path "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PowerSync\" -Force -Confirm:$false -Recurse
Copy-Item -Path ".\Script\" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PowerSync\" -Force -Recurse