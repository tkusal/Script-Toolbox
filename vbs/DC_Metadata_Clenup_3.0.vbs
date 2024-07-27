REM    ========================================================== 
REM                GUI Metadata Cleanup Utility 
REM                  Written By Thiago Kusal
REM             Based on Clay Perrine s version@2.5
REM                      Version "3.0"
REM    ========================================================== 
REM     This tool is furnished "AS IS". NO warranty is expressed or Implied. 

On Error Resume Next

Dim objRoot, objConfig, objContainer, computerName, domainControllersPath
Dim inputDC, currentDCName, foundDC, userInput, sitePath, SYSVOLPath, DCName
Dim objCheck, objReplLinkVal, objSitelink, objGuidPath, objNTDSPath, objFRSSysvol
Dim siteContainer, sitePath, strFromServer, isPresent, guidPath, objReplLink
Dim dnsZonePath, dnsServer, dnsEntry, objDNS, objZone

Set sh = CreateObject("WScript.Shell")
computerName = sh.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\ComputerName")

Set objRoot = GetObject("LDAP://RootDSE")
domainControllersPath = "LDAP://OU=Domain Controllers," & objRoot.Get("defaultNamingContext")

Set objConfig = GetObject(domainControllersPath)
Dim outputValue
outputValue = ""
For Each objContainer In objConfig
    outputValue = outputValue & vbTab & objContainer.Name & vbCrLf
Next
outputValue = Replace(outputValue, "CN=", "")

userInput = InputBox(outputValue, "Digite o nome do computador para remover", "")
currentDCName = UCase(userInput)

If currentDCName = UCase(computerName) Then
    MsgBox "O controlador de domínio inserido é o computador que está executando este script. Não é possível limpar os metadados para a máquina que está executando o script!", vbCritical, "Erro na Limpeza de Metadados"
    WScript.Quit
End If

Set objConfig = GetObject(domainControllersPath)
foundDC = False

For Each objContainer In objConfig
    Err.Clear
    Dim checkDCPath
    checkDCPath = "LDAP://CN=" & userInput & ",OU=Domain Controllers," & objRoot.Get("defaultNamingContext")
    Set myObj = GetObject(checkDCPath)
    If Err.Number = 0 Then
        foundDC = True
        Exit For
    End If
Next

If Not foundDC Then
    MsgBox "O controlador de domínio informado não foi encontrado no Active Directory.", vbCritical, "Erro na Limpeza de Metadados"
    WScript.Quit
End If

If MsgBox("Você está prestes a remover todos os metadados para o servidor " & userInput & "! Tem certeza?", vbYesNo + vbExclamation, "Atenção!!") = vbNo Then
    MsgBox "Limpeza de Metadados Abortada.", vbInformation, "Limpeza de Metadados"
    WScript.Quit
End If

inputDC = "CN=" & userInput
DCPath = "LDAP://" & inputDC & ",OU=Domain Controllers," & objRoot.Get("defaultNamingContext")
sitePath = "LDAP://CN=Sites,CN=Configuration," & objRoot.Get("defaultNamingContext")
SYSVOLPath = "LDAP://CN=Domain System Volume (SYSVOL share),CN=File Replication Service,CN=System," & objRoot.Get("defaultNamingContext")

Set objConfig = GetObject(sitePath)
For Each siteContainer In objConfig
    Dim sitePath
    sitePath = "LDAP://" & inputDC & ",CN=Servers," & siteContainer.Name & ",CN=Sites,CN=Configuration," & objRoot.Get("defaultNamingContext")
    Err.Clear
    Set objCheck = GetObject(sitePath)
    If Err.Number = 0 Then
        Set objSitelink = GetObject("LDAP://" & objCheck.Name & ",CN=NTDS Settings," & sitePath)
        objSitelink.GetInfo
        strFromServer = objSitelink.Get("fromServer")
        isPresent = InStr(1, strFromServer, inputDC, 1)
        If isPresent <> 0 Then
            objSitelink.DeleteObject(0)
        End If
    End If
Next

Set objFRSSysvol = GetObject(SYSVOLPath)
If Not objFRSSysvol Is Nothing Then
    objFRSSysvol.DeleteObject(0)
End If

Set objNTDSPath = GetObject("LDAP://" & inputDC & ",CN=NTDS Settings," & DCPath)
If Not objNTDSPath Is Nothing Then
    objNTDSPath.DeleteObject(0)
End If

Set objComputer = GetObject(DCPath)
If Not objComputer Is Nothing Then
    objComputer.DeleteObject(0)
End If

dnsZonePath = "LDAP://CN=DomainDnsZones," & objRoot.Get("defaultNamingContext")
Set objDNS = GetObject(dnsZonePath)
For Each objZone In objDNS
    Err.Clear
    dnsEntry = "LDAP://CN=" & userInput & ",CN=DomainDnsZones," & objRoot.Get("defaultNamingContext")
    Set objZone = GetObject(dnsEntry)
    If Err.Number = 0 Then
        objZone.DeleteObject(0)
    End If
Next

MsgBox "Limpeza de Metadados e DNS concluída para " & userInput, vbInformation, "Aviso"

WScript.Quit