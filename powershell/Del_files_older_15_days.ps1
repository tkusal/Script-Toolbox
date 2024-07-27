$Pasta = "C:\Scanner\"
$LogFile = "C:\Scanner\Log.txt"

function Add-Log {
    param (
        [string]$Message
    )
    Add-Content -Path $LogFile -Value ("{0} - {1}" -f (Get-Date), $Message)
}

function Apagar-Arquivos {
    param (
        [string]$Pasta
    )

    try {
        $folder = Get-Item -Path $Pasta

        Get-ChildItem -Path $folder.FullName -File | ForEach-Object {
################# Na linha abaixoi, altere o 15 para a quantidade de dias ##########################
            if ((New-TimeSpan -Start $_.CreationTime -End (Get-Date)).Days -gt 15) {
                try {
                    Remove-Item -Path $_.FullName -Force
                    Add-Log "Arquivo apagado: $($_.FullName)"
                } catch {
                    Add-Log "Erro ao apagar arquivo: $($_.FullName) - $_"
                }
            }
        }
        
        Get-ChildItem -Path $folder.FullName -Directory | ForEach-Object {
            Apagar-Arquivos -Pasta $_.FullName
        }

        if ((Get-ChildItem -Path $folder.FullName -File).Count -eq 0 -and 
            (Get-ChildItem -Path $folder.FullName -Directory).Count -eq 0 -and
            $folder.FullName -ne $Pasta) {
            try {
                Remove-Item -Path $folder.FullName -Recurse -Force
                Add-Log "Pasta apagada: $($folder.FullName)"
            } catch {
                Add-Log "Erro ao apagar pasta: $($folder.FullName) - $_"
            }
        }
    } catch {
        Add-Log "Erro ao processar a pasta: $Pasta - $_"
    }
}

if (Test-Path $LogFile) {
    Remove-Item -Path $LogFile -Force
}
Add-Log "Início da execução do script."

Apagar-Arquivos -Pasta $Pasta

Add-Log "Execução do script concluída."