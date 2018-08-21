function Write-PSYInformationLog {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Category
    )

    # Validation
    Confirm-PSYInitialized($Ctx)

    # Write Log and output to screen
    $Ctx.System.Repository.LogInformation($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Category, $Message)
    Write-Host "Information: $Category $Message"
}