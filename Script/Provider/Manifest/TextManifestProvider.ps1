class TextManifestProvider : ManifestProvider {
    [string] $Path

    TextManifestProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        if ($this.ConnectionStringParts.'format' -ne 'CSV') {
            throw "Only CSV text manifests are supported."
        }
        $this.Path = $this.ConnectionStringParts.'data source'
    }

    [System.Collections.ArrayList] FetchManifest() {
        try {
            $csvManifest = Import-Csv $this.Path
            # Comes out as an array list of pscustomobjects.  Need to convert to arraylist of hashtables.
            $this.Manifest = New-Object System.Collections.ArrayList
            foreach ($i in $csvManifest) {
                $h = [ordered] @{}
                $i.psobject.properties | Foreach { $h[$_.Name] = $_.Value }
                $this.Manifest.Add($h)
            }
            
            return $this.Manifest
        }
        catch {
            $this.HandleException($_.exception)
            return $null
        }
    }

    [void] CommitManifestItem([hashtable]$ManifestItem) {
        [System.Collections.ArrayList] $newList = $null
        try {
            # We're not smart enough to write a single line item to the manifest, and instead rewrite 
            # the entire file. This could be optimized, which would also enable the possibility of concurrency.
            #
            # Convert array list of hashtable objects back to pscustomobjects
            $newList = New-Object System.Collections.ArrayList
            foreach ($i in $this.Manifest) {
                $o = [PSCustomObject] $i
                $o.PSObject.Properties.Remove('RuntimeID')
                $newList.Add($o)
            }
            $newList | Export-Csv -Path $this.Path -Force -NoTypeInformation
        }
        catch {
            # Oddly, the export sometimes fails, presumably because the file is still being written
            # to from the last save.  When this occurs, we'll wait a second, and try again.
            if ($newList) {
                try {
                    Start-Sleep 1
                    $newList | Export-Csv -Path $this.Path -Force -NoTypeInformation
                }
                catch {
                    $this.HandleException($_.exception)
                }
            }
            else {
                $this.HandleException($_.exception)
            }
        }
    }
}