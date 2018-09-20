# To run this test, you'll need to create an Azure Blob storage account, and set the connection string in the following statement.
Set-PSYConnection -Name "TestAzureBlob" -Provider AzureBlobStorage -ConnectionString "DefaultEndpointsProtocol=https;AccountName=MyAccountName;AccountKey=MyAccountKey;EndpointSuffix=core.windows.net"

Start-PSYActivity -Name 'Test Azure Blob to SQL' -ScriptBlock {

    Start-PSYActivity -Name 'Stream Blob' -ScriptBlock {
        Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header -Stream `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.AzureStreamSample10000" -Create
    }

    Start-PSYActivity -Name 'Download Blob' -ScriptBlock {
        Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.AzureDownloadSample10000" -Create
    }
}