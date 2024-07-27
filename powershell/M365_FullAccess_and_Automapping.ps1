Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$OnlineCred = Get-Credential

Connect-ExchangeOnline -Credential $OnlineCred -ShowProgress $true

try {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $OnlineCred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber
    
    Add-MailboxPermission -Identity user1@contoso.com.br -User user2@contoso.com.br -AccessRights FullAccess -AutoMapping $true
} catch {
    Write-Error "Ocorreu um erro: $_"
} finally {
    if ($Session -ne $null) {
        Remove-PSSession $Session
    }
}