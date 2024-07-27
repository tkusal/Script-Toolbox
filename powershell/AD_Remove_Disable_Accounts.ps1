# ===========================================================
#               Remove Inative Accounts from AD
#                  Written By Thiago Kusal
#                        Version 1.0
# ===========================================================
# This tool is furnished "AS IS". NO warranty is expressed or Implied.

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Importar o módulo Active Directory
Import-Module ActiveDirectory

# Função para obter a quantidade de dias inativos
function Get-InactiveDays {
    $days = Read-Host -Prompt "Digite a quantidade de dias inativos"
    if (-not [int]::TryParse($days, [ref]$null)) {
        Write-Host "Entrada inválida. Por favor, insira um número inteiro." -ForegroundColor Red
        exit
    }
    return [int]$days
}

# Função para perguntar sobre a remoção de usuários e computadores
function Get-RemovalChoice {
    $validChoices = @('U', 'C', 'A')
    do {
        $choice = Read-Host -Prompt "Deseja remover (U)suários, (C)omputadores ou (A)mbos? (U/C/A)"
        if ($validChoices -contains $choice.ToUpper()) {
            switch ($choice.ToUpper()) {
                'U' { return 'Users' }
                'C' { return 'Computers' }
                'A' { return 'Both' }
            }
        } else {
            Write-Host "Escolha inválida. Por favor, insira U, C ou A." -ForegroundColor Red
        }
    } while ($true)
}

# Obter a quantidade de dias inativos e a escolha de remoção
$daysInactive = Get-InactiveDays
$removalChoice = Get-RemovalChoice

# Calcular a data de corte para inatividade
$cutoffDate = (Get-Date).AddDays(-$daysInactive)

# Criar um arquivo de log para registrar as remoções
$logFilePath = "C:\teste.txt"

# Inicializar o arquivo de log
"Remoção de Objetos Inativos - $(Get-Date)" | Out-File -FilePath $logFilePath -Append

# Remover Computadores Inativos
if ($removalChoice -eq 'Computers' -or $removalChoice -eq 'Both') {
    $inactiveComputers = Get-ADComputer -Filter { LastLogonTimestamp -lt $cutoffDate } -Properties LastLogonTimestamp

    foreach ($computer in $inactiveComputers) {
        try {
            $computerName = $computer.Name
            "Removendo computador: $computerName" | Out-File -FilePath $logFilePath -Append

            Remove-ADComputer -Identity $computer.DistinguishedName -Confirm:$false -ErrorAction Stop
            "Computador $computerName removido com sucesso." | Out-File -FilePath $logFilePath -Append
        } catch {
            "Erro ao remover computador $($computer.Name): $_" | Out-File -FilePath $logFilePath -Append
        }
    }
}

# Remover Usuários Inativos
if ($removalChoice -eq 'Users' -or $removalChoice -eq 'Both') {
    $inactiveUsers = Get-ADUser -Filter { LastLogonTimestamp -lt $cutoffDate } -Properties LastLogonTimestamp

    foreach ($user in $inactiveUsers) {
        try {
            $userName = $user.Name
            "Removendo usuário: $userName" | Out-File -FilePath $logFilePath -Append

            Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false -ErrorAction Stop
            "Usuário $userName removido com sucesso." | Out-File -FilePath $logFilePath -Append
        } catch {
            "Erro ao remover usuário $($user.Name): $_" | Out-File -FilePath $logFilePath -Append
        }
    }
}

# Mensagem de conclusão
"Remoção de objetos inativos concluída." | Out-File -FilePath $logFilePath -Append