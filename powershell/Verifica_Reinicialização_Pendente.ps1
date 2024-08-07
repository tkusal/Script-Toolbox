<#
  Script valida os registros RebootPending para verificar se há reinicialização pendente no Windows.
  O Retorno é uma string compatível com o Custom Sensor do PRTG.
  No PRTG é necessário configurar uma condicional para alarmar quando o valor for maior que zero.
#>

param(
    [string]$ComputerName = "",
    [switch]$verbose = $False    
)

$session = New-PSSession -ComputerName $ComputerName

Invoke-Command -Session $session -ScriptBlock {
    function Test-PendingReboot {
        $rebootRequired = $false

        $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        if (Test-Path $key) {
            $rebootRequired = $true
        }

        $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        if (Test-Path $key) {
            $rebootRequired = $true
        }

        return $rebootRequired
    }

    if (Test-PendingReboot) {
        $returnCode = 1
        $value = "true"
        $message = ">> Há uma reinicialização pendente no sistema !! <<"
    } else {
        $returnCode = 0
        $value = "false"
        $message = "Tudo OK por aqui."
    }

    $result = "${returnCode}:${$value}:${message}"

    return $result
    
    Remove-PSSession -Session $session
}
