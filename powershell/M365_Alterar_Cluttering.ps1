Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$OnlineCred = Get-Credential

Connect-ExchangeOnline -Credential $OnlineCred -ShowProgress $true

try {
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell-liveid/ -Credential $OnlineCred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber

    function Manage-Clutter {
        param (
            [bool]$Enable
        )

        do {
            Write-Host "Digite 1 para aplicar em uma conta específica ou 2 para aplicar em todas as contas:"
            $resp = Read-Host
        } while ($resp -ne "1" -and $resp -ne "2")

        if ($resp -eq "1") {
            Write-Host "Informe a conta (email) que você deseja modificar:"
            $email = Read-Host
            if ([string]::IsNullOrEmpty($email)) {
                Write-Host "Nenhum e-mail informado. Por favor, tente novamente."
            } else {
                Set-Clutter -Identity $email -Enable $Enable
                Write-Host "Clutter $(if ($Enable) { 'ativado' } else { 'desativado' }) para a conta $email."
            }
        } elseif ($resp -eq "2") {
            Get-Mailbox | Set-Clutter -Enable $Enable
            Write-Host "Clutter $(if ($Enable) { 'ativado' } else { 'desativado' }) para todas as contas."
        }
    }

    do {
        Write-Host "Digite 1 para ativar o Clutter ou 2 para desativar:"
        $resp = Read-Host
    } while ($resp -ne "1" -and $resp -ne "2")

    if ($resp -eq "1") {
        Manage-Clutter -Enable $true
    } elseif ($resp -eq "2") {
        Manage-Clutter -Enable $false
    }
} catch {
    Write-Error "Ocorreu um erro: $_"
} finally {
    if ($Session -ne $null) {
        Remove-PSSession $Session
    }
}