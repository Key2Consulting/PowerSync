<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Represents the abstract base class for the ManifestProvider interface.
#>
class ManifestProvider : Provider {
    [System.Collections.ArrayList] $Manifest

    ManifestProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    # Reads the entirety of a manifest and prepares it for processing.
    [System.Collections.ArrayList] ReadManifest() {
        # If we haven't loaded the manifest, do it now
        if ($this.Manifest -eq $null) {
            $this.Manifest = $this.FetchManifest()
            # Add a runtime key column so we can correlate it during updates
            foreach ($item in $this.Manifest) {
                $item.RuntimeID = $this.GetUniqueID()
            }
        }
        return $this.Manifest
    }

    # Writes changed configuration back to a manifest.
    [void] WriteManifestItem([hashtable]$ManifestItem) {
        if ($ManifestItem) {
            # Find the manifest item from our internal list
            $h = $null
            foreach ($item in $this.Manifest) {
                if ($item.RuntimeID -eq $ManifestItem.RuntimeID) {
                    $h = $item
                    break
                }
            }
            # Update any matching properties from the passed in manifest item
            foreach ($key in $ManifestItem.Keys) {
                if ($h.Contains($key)) {
                    $h."$key" = $ManifestItem."$key"
                }
            }
            $this.CommitManifestItem($h)
        }
    }

    # Implemented by derived classes to fetch the entire manifest from storage. Not intended to be called directly.
    [System.Collections.ArrayList] FetchManifest() {
        throw "Not Implemented"
    }

    # Implemented by derived classes to commit a manifest entry to storage. Not intended to be called directly.
    [void] CommitManifestItem([hashtable]$ManifestItem) {
        throw "Not Implemented"
    }

    # Combines two manifests into one, where the override takes precedence, optionally applying a namespace (i.e. prefix).
    [hashtable] OverrideManifest([string] $BaseNamespace, [hashtable]$Base, [string] $OverrideNamespace, [hashtable]$Override) {
        # Always create a new hashtable since we don't want callers changing our original values
        $h = @{}
        # Apply override first since it takes precedence
        foreach ($key in $Override.Keys) {
            $nsKey = $OverrideNamespace + $key
            $h."$nsKey" = $Override."$nsKey"
        }
        # Apply base where not already applied
        foreach ($key in $Base.Keys) {
            $nsKey = $BaseNamespace + $key
            if ($h.ContainsKey($nsKey) -eq $false) {
                $h."$nsKey" = $Base."$key"
            }
        }
        return $h
    }
}