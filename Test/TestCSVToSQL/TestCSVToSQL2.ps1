# Load conn strings from a local file
$connString = Get-Content -Path "myfile"

Start-PSYMainActivity -PrintVerbose -ConnectScriptBlock {
    Connect-PSYJsonRepository
} -Name 'Test CSV To SQL' -ScriptBlock {

    #New-PSYConnection -Name 'SourceA' -ConnectionString "$connString"
    #Set-PSYConnection -Name 'TargetA' -ConnectionString "myconnectionstring"
    #Use-Kit "$rootPath\MyProject\ScenarioA\"

   # Export-PSYTextFile -Format "CSV" -Header -Path "$rootPath\TestCSVToSQL\Sample100.csv" `
    #    | Import-PSYOleDb -Schema "Load" -Table "Foo2" -AutoCreate -Overwrite -AutoIndex -ConnectionName 'SourceA'
    
    #Invoke-PSYOleDbCommand 'Publish.sql'
}