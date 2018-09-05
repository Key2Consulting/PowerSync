// Text exporting is done in .NET because it requires a custom IDataReader class. Although this can be implemented in PowerShell,
// it's incredibly slow due to the overhead of calling functions/methods written in PowerShell.
using System;
using System.Data;
using System.IO;
using System.Collections;

namespace PowerSync
{
    public class TextFileDataWriter
    {
        string _filePath;
        string _delimeter;
        string _quote;
        string _quoteEscape;
        bool _header;
        bool _isClosed = true;
        System.Collections.ArrayList _columnName;
        System.Collections.ArrayList _readBuffer;
        IDataReader _reader;
        StreamWriter _writer;

        public TextFileDataWriter(IDataReader reader, string filePath, bool header, string delimeter)
        {
            this._reader = reader;
            this._filePath = filePath;
            this._header = header;
            this._delimeter = delimeter;
            this._quote = "\"";
            this._quoteEscape = "\"\"";

            // Open the target file, overwriting if exists
            this._writer = new StreamWriter(filePath);
        }

        public void Write()
        {
            // If writing the header
            if (this._header)
            {
                // For each column
                for (int i = 0; i < this._reader.FieldCount; i++)
                {
                    // If not the first column, write the delimeter
                    if (i > 0)
                    {
                        this._writer.Write(this._delimeter);
                    }                    
                    this._writer.Write(this._reader.GetName(i));
                }
                // Next line
                this._writer.Write("\r\n");
            }

            // For each data row
            while (this._reader.Read())
            {
                // For each data column
                for (int i = 0; i < this._reader.FieldCount; i++)
                {
                    // If not the first column, write the delimeter
                    if (i > 0)
                    {
                        this._writer.Write(this._delimeter);
                    }

                    // If the column requires quotes
                    // this._writer.Write(this._reader.GetFieldType(i).Name);
                    if (this._reader.GetFieldType(i) == typeof(string))
                    {
                        var val = this._quote + this._reader.GetValue(i).ToString().Replace(this._quote, this._quoteEscape) + this._quote;
                        this._writer.Write(val);
                    }
                    else
                    {
                        this._writer.Write(this._reader.GetValue(i));
                    }
                }
                // Next line
                this._writer.Write("\r\n");
            }

            // Clean up
            this._writer.Dispose();
        }
    }
}