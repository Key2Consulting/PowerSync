Start-PSYActivity -Name 'Test Quick Commands' -ScriptBlock {

    Start-PSYActivity -Name 'Test Quick CSV to SqlServer' -ScriptBlock {
        Copy-PSYTable -SProvider TextFile -SConnectionString "Test\SampleFiles\Sample100.csv" -SFormat CSV -SHeader `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickCSVCopy"

        Copy-PSYTable -SProvider TextFile -SConnectionString "Test\SampleFiles\Sample100.csv" -SFormat CSV -SHeader `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickTypedCSVCopy"
    }

    Start-PSYActivity -Name 'Test Quick SqlServer to SqlServer' -ScriptBlock {    
        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickTypedCSVCopyOfCopy"
    }
    
    Start-PSYActivity -Name 'Test Quick SqlServer to CSV' -ScriptBlock {
        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider TextFile -TConnectionString "Test\SampleFiles\TempOutput.csv" -TFormat CSV -THeader
    }
}

$x = 1
<#
SProvider
SConnectionString
SServer
SDatabase
SFormat
SHeader
TTable
TProvider
TConnectionString
TServer
TDatabase
TFormat
THeader
TTable
Timeout
#>