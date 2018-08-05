. $PSScriptRoot\..\..\Script\PowerSync `
    -Manifest @{
        ConnectionString = "PSProvider=TextManifestProvider;Data Source=$rootPath\TestSQLToSQL\Manifest.csv;Header=True;Format=CSV"
    } `
    -Log @{
      ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        ExtractScript = "$rootPath\TestSQLToSQL\Extract.sql";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        TransformScript = "$rootPath\TestSQLToSQL\Transform.sql";
        AutoIndex = $true;
        AutoCreate = $true;
    }