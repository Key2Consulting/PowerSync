﻿using System;

namespace PowerSync
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("CSharp Tests Started");
            
            var reader = new TextFileDataReader("D:\\Dropbox\\Project\\Key2\\PowerSync\\Test\\SampleFiles\\Sample100.csv", true, true, "(?:^|,)(?=[^\"]|(\")?)\"?((?(1)[^\"]*|[^,\"]*))\"?(?=,|$)", ",");
            Console.Write(reader.GetDataTypeName(2).ToString());
            Console.Write(reader.GetFieldType(0).ToString());
            Console.Write(reader.FieldCount);
            Console.Write(reader.GetOrdinal("Description"));
            Console.Write(reader.GetName(4));
            while (reader.Read())
            {
                Console.Write(reader.GetString(0));
                Console.Write(reader.GetString(1));
                Console.Write(reader.GetString(1));
                Console.WriteLine();
            }
        }
    }
}