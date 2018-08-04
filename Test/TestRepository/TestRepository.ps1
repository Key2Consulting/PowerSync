. $PSScriptRoot\..\..\Script\PowerSync `
-Log @{
     ConnectionString = "PSProvider=MSSQLLogProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$dataFolder\PowerSyncTestDB.mdf;";
     LogScript = "$testFolder\Package\Log.sql";
} `
-Source @{
    ConnectionString = "PSProvider=TextDataProvider;FilePath=$dataFolder\Sample1.csv;Header=True;Format=CSV;Quoted=True";
    PrepareScript = "$testFolder\Package\PrepareSource.sql";
    ExtractScript = "$testFolder\Package\Extract.sql";
    Timeout = 3600;
} `
-Target @{
    ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$dataFolder\PowerSyncTestDB.mdf;";
    PrepareScript = "$testFolder\Package\PrepareTarget.sql";
    TransformScript = "$testFolder\Package\Transform.sql";
    Schema = "dbo"
    Table = "LogTest1"
    AutoIndex = $true;
    AutoCreate = $true;
    Overwrite = $true;
    BatchSize = 10000;
}