<%
On Error Resume Next

Set conn = Server.CreateObject("ADODB.Connection")
conn.Open Application("connectionString")

If Err.Number <> 0 Then
    Response.Write "ERROR: " & Err.Number & "<br>"
    Response.Write Err.Description
    Response.End
End If

Set rs = conn.Execute( _
    "SELECT SYSTEM_USER AS LoginName, " & _
    "DB_NAME() AS DatabaseName")

Response.Write "SQL Login: " & rs("LoginName") & "<br>"
Response.Write "Database: " & rs("DatabaseName")

rs.Close
conn.Close
%>