Update-TypeData -TypeName SecureString -MemberType ScriptMethod -MemberName ToPlainText -Force -Value {
    [System.Net.NetworkCredential]::new("TempCredential", $this).Password
}