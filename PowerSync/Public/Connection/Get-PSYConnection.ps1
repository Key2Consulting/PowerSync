function Get-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        # Get the from the repository.
        return $repo.CriticalSection({
            $existing = $this.FindEntity('Connection', 'Name', $Name)
            if ($existing.Count -eq 0) {
                throw "No connection entry found with name '$Name'."
            }
            else {
                return $existing[0]
            }

        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting connection $Name."
    }
}