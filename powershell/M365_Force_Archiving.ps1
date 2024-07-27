Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$OnlineCred = Get-Credential

Connect-ExchangeOnline -Credential $OnlineCred -ShowProgress $true

try {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $OnlineCred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber

    Write-Host "Digite o e-mail da conta que você deseja habilitar e forçar o archiving:"
    $email = Read-Host

    if ([string]::IsNullOrEmpty($email) -or $email -notmatch "^[\w\.-]+@[\w\.-]+\.\w+$") {
        Write-Host "E-mail inválido. Por favor, informe um e-mail válido e tente novamente."
    } else {
        Enable-Mailbox -Identity $email -AutoExpandingArchive
        Start-ManagedFolderAssistant -Identity $email

        Write-Host "O arquivamento automático foi habilitado e o Assistente de Pastas Gerenciadas foi iniciado para a conta $email."
    }
} catch {
    Write-Error "Ocorreu um erro ao processar a solicitação: $_"
} finally {
    if ($Session -ne $null) {
        Remove-PSSession $Session
    }
}