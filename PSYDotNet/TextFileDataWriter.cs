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
        int _format;
        string _delimeter;
        string _quote;
        string _quoteEscape;
        bool _header;
        System.IO.StreamWriter _writer;

        public TextFileDataWriter(string filePath, int format, bool header)
        {
            this._filePath = filePath;
            this._format = format;
            this._header = header;
            
            // Open the target file, overwriting if exists
            this._writer = new StreamWriter(this._filePath);

            // Initialize write operation.
            this.Initialize(format);
        }

        public TextFileDataWriter(System.IO.StreamWriter writer, int format, bool header)
        {
            this._format = format;
            this._header = header;
            this._writer = writer;

            // Initialize write operation.
            this.Initialize(format);
        }

        protected void Initialize(int format) 
        {
            // Set parsing information based on format
            if (format == 1)        // CSV
            {
                this._delimeter = ",";
                this._quote = "\"";
                this._quoteEscape = "\"\"";
            }
            else if (format == 2)   // TSV
            {
                this._delimeter = "\t";
            }
        }

        public void Write(IDataReader reader)
        {
            var writer = this._writer;
            try
            {
                // If writing the header
                if (this._header)
                {
                    // For each column
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        // If not the first column, write the delimeter
                        if (i > 0)
                        {
                            writer.Write(this._delimeter);
                        }                    
                        writer.Write(reader.GetName(i));
                    }
                    // Next line
                    writer.Write("\r\n");
                }

                // For each data row
                while (reader.Read())
                {
                    // For each data column
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        // If not the first column, write the delimeter
                        if (i > 0)
                        {
                            writer.Write(this._delimeter);
                        }

                        // If the column requires quotes
                        if (reader.GetFieldType(i) == typeof(string) && this._quote != null)
                        {
                            var val = this._quote + reader.GetValue(i).ToString().Replace(this._quote, this._quoteEscape) + this._quote;
                            writer.Write(val);
                        }
                        else
                        {
                            writer.Write(reader.GetValue(i));
                        }
                    }
                    // Next line
                    writer.Write("\r\n");
                }
            }
            finally 
            {
                // Clean up
                writer.Dispose();
            }
        }
    }
}