<#
    .SYNOPSIS
        Script pro PRTG; Realiza uma sessão remota no powershell (PSSession) e executa um script local na máquina de destino.

    .DESCRIPTION
        Este script realiza uma sessão remota no PowerShell (PSSession) e executa um script especificado na máquina de destino.
        O script é útil para monitoramento remoto e automação de tarefas em dispositivos que possuem o PRTG como ferramenta de monitoramento.
        A execução remota é feita através do protocolo WinRM, e o script que deve ser executado no dispositivo de destino é especificado pelo parâmetro `ScriptPath`.

    .PREREQUISITES
        1. No dispositivo de destino, habilite a execução remota de scripts PowerShell (WinRM) com os seguintes comandos:
        
            Enable-PSRemoting -Force                            # Habilita o PowerShell Remoting.
            Set-ExecutionPolicy RemoteSigned -Force             # Permite a execução de scripts remotos.
            winrm quickconfig                                   # Configura o WinRM para comunicação remota.
        
        2. Em seguida, adicione o IP e hostname do PRTG como hosts confiáveis. Substitua os valores pelo IP e hostname correto de seu PRTG:
        
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.1, HOSTNAME_PRTG"
        
        3. Reinicie o serviço WinRM para aplicar as configurações:
        
            Restart-Service winrm
        
        Observação: Para que o PRTG consiga acessar a máquina de destino, é necessário comuncação na porta 5985 (HTTP).

    .PARAMETER ComputerName
        É o hostname do dispositivo de destino. Será fornecido pelo próprio PRTG: -ComputerName HOSTNAME_DESTINO
        Pode-se obter o hosname usado no sensor, através da váriavel do PRTG %host:  -ComputerName %host

    .PARAMETER ScriptPath
        Caminho completo do script que será executado no dispositivo de destino. O script deve estar acessível e com permissões adequadas para execução remota.
        O valor padrão é "C:\scripts\teste.ps1", mas deve ser alterado conforme necessário.
        Caso queira, esse Path pode ser passado como parâmetro pelo PRTG também: -ScriptPath C:\scripts\teste.ps1   (Lembrar de deixar as aspas vazias no script)

    .PARAMETER verbose
        Habilita a saída detalhada para o processo de execução do script. Por padrão, está desativado.

    .EXAMPLE
        .\script_remoto.ps1 -ComputerName "HOSTNAME_DESTINO"

    .NOTES
        Thiago Kusal | ITGX
        https://tkusal.com.br
    .LINK
        https://github.com/tkusal/Script-Toolbox
#>

param(
    [string]$ComputerName = "", # ComputerName deverá ser fornecido pelo PRTG
    [switch]$verbose = $False,
    [string]$ScriptPath = "C:\scripts\teste.ps1" # Alterar para o caminho e nome do script que deverá ser executado no dispositivo de destino ou deixar vazio caso queira que o PRTG passe como parâmetro 
)

$session = New-PSSession -ComputerName $ComputerName

Invoke-Command -Session $session -ScriptBlock {
    param($ScriptPath)
    & $ScriptPath
} -ArgumentList $ScriptPath

Remove-PSSession -Session $session
