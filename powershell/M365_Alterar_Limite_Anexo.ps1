Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$Cred = Get-Credential

Connect-ExchangeOnline -Credential $Cred -ShowProgress $true

try {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber

    $validInput = $true

    do {
        Write-Host "Você deseja aumentar o limite para uma conta específica ou para todas?"
        Write-Host "Digite 1 para uma conta específica ou 2 para todas as contas:"
        $resp = Read-Host

        if ($resp -eq "1") {
            Write-Host "Informe o e-mail da conta:"
            $email = Read-Host
            if ([string]::IsNullOrEmpty($email)) {
                Write-Host "Nenhum e-mail informado. Por favor, tente novamente."
            } else {
                Set-Mailbox -Identity $email -MaxSendSize 75MB -MaxReceiveSize 75MB
                Write-Host "Limites ajustados para a conta $email."
            }
        } elseif ($resp -eq "2") {
            Get-Mailbox | Set-Mailbox -MaxSendSize 75MB -MaxReceiveSize 75MB
            Write-Host "Limites ajustados para todas as contas."
        } else {
            Write-Host "Resposta inválida. Por favor, insira uma resposta válida (1 ou 2)."
            $validInput = $false
        }
    } while (-not $validInput)
} catch {
    Write-Error "Ocorreu um erro: $_"
} finally {
    if ($Session -ne $null) {
        Remove-PSSession $Session
    }
}