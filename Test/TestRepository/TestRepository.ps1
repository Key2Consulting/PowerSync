# Use PowerSync to initial test by importing our manifest data
. $PSScriptRoot\..\..\Script\PowerSync `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$rootPath\TestRepository\ManifestData.csv;Header=True;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "Load"
        Table = "Manifest"
        TransformScript = "
            INSERT INTO [dbo].[Manifest]([SourceSchema],[SourceTable],[TargetSchema],[TargetTable],[ProcessType],[IncrementalField])
            SELECT [SourceSchema],[SourceTable],[TargetSchema],[TargetTable],[ProcessType],[IncrementalField] FROM [Load].[Manifest]
            DROP TABLE [Load].[Manifest]"
        AutoCreate = $true
    }

# Process the initial load
. $PSScriptRoot\..\..\Script\PowerSync `
    -Log @{
        ConnectionString = "PSProvider=MSSQLLogProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        LogScript = "$rootPath\TestRepository\Log.sql";
    } `
    -Manifest @{
        ConnectionString = "PSProvider=MSSQLManifestProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        ReadManifestScript = "$rootPath\TestRepository\ReadManifest.sql"
    } `
    -Source @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        PrepareScript = "$rootPath\TestRepository\PrepareSource.sql"
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        PrepareScript = "$rootPath\TestRepository\PrepareTarget.sql"
        TransformScript = "$rootPath\TestRepository\Transform.sql"
    }    