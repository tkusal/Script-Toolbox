Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Solicita as credenciais do usuário
$credential = Get-Credential -Message "Digite as credenciais de domínio"

# Definindo variáveis
$ComputerNamePrefix = Read-Host 'Entre com o prefixo, (EX: CONTOSO-)'
$ComputerNamePrefix = $ComputerNamePrefix.ToUpper()
$DomainLongName = "CONTOSO.LOCAL"  # Seu domínio
$OU = "OU=Computers,DC=CONTOSO,DC=LOCAL"  #A OU onde ficará o computador

# Gera o hostname com o prefixo + serialnumber
$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
$NewComputerName = "$ComputerNamePrefix$SerialNumber"
if ($NewComputerName.Length -gt 15) {
    $NewComputerName = $NewComputerName.Substring(0, 15)
}

# Renomeia o computador e ingressa no domínio
try {
    Add-Computer -DomainName $DomainLongName -Credential $credential -OUPath $OU -NewName $NewComputerName -Force -Restart
} catch {
    Write-Error "Falha ao renomear o computador e ingressar no domínio: $_"
}