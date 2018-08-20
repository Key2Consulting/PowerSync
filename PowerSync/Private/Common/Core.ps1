function Confirm-PSYInitialized {
    if (-not $Ctx) {
        throw "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
    }
}