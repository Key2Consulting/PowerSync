class NoManifestProvider : ManifestProvider {

    NoManifestProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    [System.Collections.ArrayList] FetchManifest() {
        $this.Manifest = New-Object System.Collections.ArrayList
        $h = [ordered] @{}
        $this.Manifest.Add($h)
        return $this.Manifest
    }

    [void] CommitManifestItem([hashtable]$ManifestItem) {
    }
}