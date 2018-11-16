// A wrapper around another DataReader that provides type conversion using a mapped schema table. Without this 
// wrapper class, certain runtime types (e.g. Sql Geography) would cause importers to error. For most of those
// cases, simply retrieving the data as a binary byte stream seems to address the issue. Most functionality of
// the reader simply calls the psuedo base class functionality.
using System;
using System.Data;
using System.Collections;
using System.Text.RegularExpressions;

namespace PowerSync
{
    public class TypeConversionDataReader : System.Data.IDataReader
    {
        IDataReader _reader = null;
        DataTable _schemaTable = null;
        bool[] _getBytes = null;       // if true, the given column requires byte streaming

        public TypeConversionDataReader(IDataReader reader, DataTable schemaTable)
        {
            this._reader = reader;
            this._schemaTable = schemaTable;

            // Certain columns require special processing and type conversions. Inspect the schema table to determine
            // which columns require which processing, and build highly optimized lookups to perform this conversion
            // during read operations.
            this._getBytes = new bool[this.FieldCount];
            for (int i = 0; i < this._schemaTable.Rows.Count; i++)
            {
                this._getBytes[i] = (this._schemaTable.Rows[i]["TransportDataTypeName"].ToString().ToUpper() == "BINARY");
            }
        }

        public object this[int i]
        {
            get
            {
                return this._reader[i];
            }
        }

        public object this[string name]
        {
            get
            {
                return this._reader[name];
            }
        }

        public int Depth
        {
            get
            {
                return this._reader.Depth;
            }
        }

        public bool IsClosed
        {
            get
            {
                return this._reader.IsClosed;
            }
        }

        public int RecordsAffected
        {
            get
            {
                return this._reader.RecordsAffected;
            }
        }

        public int FieldCount
        {
            get
            {
                return this._reader.FieldCount;
            }
        }

        public void Close()
        {
            this._reader.Close();
        }

        public void Dispose()
        {
            this._reader.Dispose();
        }

        public bool GetBoolean(int i)
        {
            return this._reader.GetBoolean(i);
        }

        public byte GetByte(int i)
        {
            return this._reader.GetByte(i);
        }

        public long GetBytes(int i, long fieldOffset, byte[] buffer, int bufferoffset, int length)
        {
            return this._reader.GetBytes(i, fieldOffset, buffer, bufferoffset, length);
        }

        public char GetChar(int i)
        {
            return this._reader.GetChar(i);
        }

        public long GetChars(int i, long fieldoffset, char[] buffer, int bufferoffset, int length)
        {
            return this._reader.GetChars(i, fieldoffset, buffer, bufferoffset, length);
        }

        public IDataReader GetData(int i)
        {
            return this._reader.GetData(i);
        }

        public string GetDataTypeName(int i)
        {
            return this._reader.GetDataTypeName(i);
        }

        public DateTime GetDateTime(int i)
        {
            return this._reader.GetDateTime(i);
        }

        public decimal GetDecimal(int i)
        {
            return this._reader.GetDecimal(i);
        }

        public double GetDouble(int i)
        {
            return this._reader.GetDouble(i);
        }

        public Type GetFieldType(int i)
        {
            return this._reader.GetFieldType(i);
        }

        public float GetFloat(int i)
        {
            return this._reader.GetFloat(i);
        }

        public Guid GetGuid(int i)
        {
            return this._reader.GetGuid(i);
        }

        public short GetInt16(int i)
        {
            return this._reader.GetInt16(i);
        }

        public int GetInt32(int i)
        {
            return this._reader.GetInt32(i);
        }

        public long GetInt64(int i)
        {
            return this._reader.GetInt64(i);
        }

        public string GetName(int i)
        {
            return this._reader.GetName(i);
        }

        public int GetOrdinal(string name)
        {
            return this._reader.GetOrdinal(name);
        }

        public DataTable GetSchemaTable()
        {
            // For whatever reason, we haven't needed to pass our converted schema table. Perhaps byte streaming is enough.
            // return _schemaTable;
            return this._reader.GetSchemaTable();
        }

        public string GetString(int i)
        {
            return this._reader.GetString(i);
        }

        public object GetValue(int i)
        {
            if (this._getBytes[i])
            {
                // Console.WriteLine("Transporting binary for col{0}", i);
                var size = this.GetBytes(i, 0, null, 0, 0);
                var buffer = new byte[size];
                this.GetBytes(i, 0, buffer, 0, (int)size);
                return buffer;
            }
            else
            {
                return this._reader.GetValue(i);
            }
        }

        public int GetValues(object[] values)
        {
            return this._reader.GetValues(values);
        }

        public bool IsDBNull(int i)
        {
            return this._reader.IsDBNull(i);
        }

        public bool NextResult()
        {
            return this._reader.NextResult();
        }

        public bool Read()
        {
            return this._reader.Read();
        }
    }
}