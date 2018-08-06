# TODO: ADD TAB DELIMITED TEST

# 100 rows
PowerSync `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$rootPath\TestCSVToSQL\Sample100.csv;Header=False;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "dbo"
        Table = "TestCSVToSQL100"
        AutoCreate = $true;
        Overwrite = $true;
    }

# 1,000 rows
PowerSync `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$rootPath\TestCSVToSQL\Sample1000.csv;Header=True;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "dbo"
        Table = "TestCSVToSQL1000"
        AutoCreate = $true;
        Overwrite = $true;
    }    

# 10,000 rows
PowerSync `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$rootPath\TestCSVToSQL\Sample10000.csv;Header=True;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "dbo"
        Table = "TestCSVToSQL10000"
        AutoCreate = $false;
        BatchSize = 50000;
    }