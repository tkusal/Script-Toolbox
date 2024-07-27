Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$OutputFile = "DistributionGroupMembers.csv"

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force
}

Import-Module ExchangeOnlineManagement

Write-Host 'INFORME O E-MAIL DO ADMINISTRADOR DO TENANT:' -ForegroundColor White -BackgroundColor Red
Connect-ExchangeOnline

Out-File -FilePath $OutputFile -InputObject "Distribution Group DisplayName,Distribution Group Email,Member DisplayName, Member Email, Member Type" -Encoding UTF8

$objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited

Foreach ($objDistributionGroup in $objDistributionGroups) {
    Write-Host "Processing $($objDistributionGroup.DisplayName)..."

    $objDGMembers = Get-DistributionGroupMember -Identity $($objDistributionGroup.PrimarySmtpAddress)

    Write-Host "Found $($objDGMembers.Count) members..."
   
    Foreach ($objMember in $objDGMembers) {
        Out-File -FilePath $OutputFile -InputObject "$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" -Encoding UTF8 -Append
        Write-Host "`t$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType)" 
    }
}

Disconnect-ExchangeOnline
Write-Host 'GRUPOS EXPORTADOS. O RESULTADO ESTÁ NA MESMA PASTA DO SCRIPT DENOMINADO DistributionGroupMembers.csv.' -ForegroundColor White -BackgroundColor Green
pause