function Copy-Object {
    param($SourceObject)
    $memStream = New-Object IO.MemoryStream
    $formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream, $SourceObject)
    $memStream.Position=0
}

function Copy-ObjectToStream {
    param($SourceObject)
    $stream = New-Object IO.MemoryStream
    $formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($stream, $SourceObject)
    $stream.Position=0
    $stream
}

function Copy-ObjectFromStream {
    param($Stream)
    $formatter = New-Object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Deserialize($Stream)
}
 