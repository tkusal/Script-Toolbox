strPasta = "C:\Scanner\"

Set FSO = CreateObject("Scripting.FileSystemObject")

On Error Resume Next
Call Apagar_Arquivos(strPasta)
If Err.Number <> 0 Then
    WScript.Echo "Erro: " & Err.Description
End If
On Error GoTo 0

Sub Apagar_Arquivos(Pasta)
    Dim folder, file, SubFolder

    Set folder = FSO.GetFolder(Pasta)

    For Each file In folder.Files
        ' Altere a quantidade de dias na linha abaixo
        If DateDiff("d", file.DateCreated, Now) > 15 Then
            On Error Resume Next
            file.Delete
            If Err.Number <> 0 Then
                WScript.Echo "Erro ao apagar arquivo: " & file.Path & " - " & Err.Description
                Err.Clear
            End If
            On Error GoTo 0
        End If
    Next

    For Each SubFolder In folder.SubFolders
        Call Apagar_Arquivos(SubFolder.Path)
    Next

    If folder.SubFolders.Count = 0 And folder.Files.Count = 0 And folder.Path <> strPasta Then
        On Error Resume Next
        folder.Delete True
        If Err.Number <> 0 Then
            WScript.Echo "Erro ao apagar pasta: " & folder.Path & " - " & Err.Description
            Err.Clear
        End If
        On Error GoTo 0
    End If
End Sub