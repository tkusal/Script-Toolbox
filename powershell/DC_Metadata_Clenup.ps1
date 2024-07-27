# ===========================================================
#               GUI Metadata Cleanup Utility
#                 Written By Thiago Kusal
#        Based on Clay Perrine's VBS script (v2.5)
#                   Version 1.0-2023
# ===========================================================
# This tool is furnished "AS IS". NO warranty is expressed or Implied.

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

function Install-ModuleIfNeeded {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Installing module: $ModuleName"
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    } else {
        Write-Host "Module $ModuleName is already installed."
    }
}

Install-ModuleIfNeeded -ModuleName "ActiveDirectory"
Install-ModuleIfNeeded -ModuleName "Microsoft.PowerShell.Management"

Import-Module ActiveDirectory
Import-Module Microsoft.PowerShell.Management

Add-Type -AssemblyName System.Windows.Forms

function Get-UserInput {
    param (
        [string]$Prompt
    )
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Input"
    $form.Width = 400
    $form.Height = 150
    $form.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Prompt
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Width = 360
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Width = 80
    $okButton.Location = New-Object System.Drawing.Point(290, 80)
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })
    $form.Controls.Add($okButton)

    $form.ShowDialog()
    return $form.Tag
}

function Show-MessageBox {
    param (
        [string]$Message,
        [string]$Title,
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $Buttons, $Icon)
}

$ErrorActionPreference = "Stop"

$computerName = (Get-WmiObject Win32_ComputerSystem).Name

$domainControllersPath = "LDAP://OU=Domain Controllers,$((Get-ADRootDSE).defaultNamingContext)"
$sitePath = "LDAP://CN=Sites,CN=Configuration,$((Get-ADRootDSE).defaultNamingContext)"
$SYSVOLPath = "LDAP://CN=Domain System Volume (SYSVOL share),CN=File Replication Service,CN=System,$((Get-ADRootDSE).defaultNamingContext)"
$dnsZonePath = "LDAP://CN=DomainDnsZones,$((Get-ADRootDSE).defaultNamingContext)"

$domainControllers = (Get-ADObject -SearchBase $domainControllersPath -Filter * -Properties Name).Name

$userInput = Get-UserInput -Prompt ($domainControllers -join "`n")
$currentDCName = $userInput.ToUpper()

if ($currentDCName -eq $computerName.ToUpper()) {
    Show-MessageBox -Message "O controlador de domínio inserido é o computador que está executando este script. Não é possível limpar os metadados para a máquina que está executando o script!" -Title "Erro na Limpeza de Metadados" -Icon [System.Windows.Forms.MessageBoxIcon]::Critical
    exit
}

$foundDC = (Get-ADObject -SearchBase $domainControllersPath -Filter {Name -eq $userInput})

if (-not $foundDC) {
    Show-MessageBox -Message "O controlador de domínio informado não foi encontrado no Active Directory." -Title "Erro na Limpeza de Metadados" -Icon [System.Windows.Forms.MessageBoxIcon]::Critical
    exit
}

if (Show-MessageBox -Message ("Você está prestes a remover todos os metadados para o servidor $userInput! Tem certeza?") -Title "Atenção!!" -Buttons [System.Windows.Forms.MessageBoxButtons]::YesNo -Icon [System.Windows.Forms.MessageBoxIcon]::Exclamation -eq [System.Windows.Forms.DialogResult]::No) {
    Show-MessageBox -Message "Limpeza de Metadados Abortada." -Title "Limpeza de Metadados" -Icon [System.Windows.Forms.MessageBoxIcon]::Information
    exit
}

$inputDC = "CN=$userInput"
$DCPath = "LDAP://$inputDC,OU=Domain Controllers,$((Get-ADRootDSE).defaultNamingContext)"

$sites = (Get-ADObject -SearchBase $sitePath -Filter * -Properties Name)

foreach ($site in $sites) {
    $siteContainerPath = "LDAP://CN=$userInput,CN=Servers,$($site.Name),CN=Sites,CN=Configuration,$((Get-ADRootDSE).defaultNamingContext)"
    try {
        $objCheck = Get-ADObject -Identity $siteContainerPath
        $objSitelink = Get-ADObject -Identity "LDAP://CN=NTDS Settings,$($objCheck.DistinguishedName)"
        $strFromServer = $objSitelink.FromServer
        if ($strFromServer -contains $inputDC) {
            Remove-ADObject -Identity $objSitelink.DistinguishedName
        }
    } catch {
        # Ignore errors
    }
}

try {
    Remove-ADObject -Identity $SYSVOLPath
} catch {
    # Ignore errors
}

try {
    Remove-ADObject -Identity "LDAP://CN=NTDS Settings,$($DCPath)"
} catch {
    # Ignore errors
}

try {
    Remove-ADObject -Identity $DCPath
} catch {
    # Ignore errors
}

$dnsZones = (Get-ADObject -SearchBase $dnsZonePath -Filter * -Properties Name)

foreach ($zone in $dnsZones) {
    try {
        $dnsEntry = "LDAP://CN=$userInput,CN=DomainDnsZones,$((Get-ADRootDSE).defaultNamingContext)"
        Remove-ADObject -Identity $dnsEntry
    } catch {
        # Ignore errors
    }
}

Show-MessageBox -Message "Limpeza de Metadados e DNS concluída para $userInput" -Title "Aviso"

exit