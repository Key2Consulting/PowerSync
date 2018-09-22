Set-PSYConnection -Name "TestAzureBlob" -Provider AzureBlobStorage -ConnectionString "DefaultEndpointsProtocol=https;AccountName=7e93bbb5150f481f849d19eb;AccountKey=bTXM/FShvzZ9ZOql01iBWIa/+4KPU8eL6D2DEPV3sHNPk644TWa5IFc0kL9LJ9mltnQfmVqE7Xyf7aGKplWZ6Q==;EndpointSuffix=core.windows.net"
# To run this test, you'll need to create an Azure Blob storage account, and set the connection string in the following statement.
#Set-PSYConnection -Name "TestAzureBlob" -Provider AzureBlobStorage -ConnectionString "DefaultEndpointsProtocol=https;AccountName=MyAccountName;AccountKey=MyAccountKey;EndpointSuffix=core.windows.net"

Start-PSYActivity -Name 'Test Azure Blob to SQL' -ScriptBlock {

    Start-PSYActivity -Name 'Stream Blob' -ScriptBlock {
        Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header -Stream `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.AzureStreamSample10000" -Create
    }

    Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.AzureDownloadSample10000" -Create

}

Start-PSYActivity -Name 'Test SQL to Azure Blob' -ScriptBlock {

    Export-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.AzureDownloadSample10000" `
    | Import-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Temp/AzureDownloadSample10000.csv" -Format CSV -Header

}