<% Option Explicit %>
<%
  Dim ticket, connection, command, recordset, parameter

  If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
    Response.Status = "405 Method Not Allowed"
    Response.End
  End If

  ticket = Request.Form("ticket")
  If Len(ticket) <> 64 Then
    Response.Redirect Application("loginURL")
  End If

  Set connection = Server.CreateObject("ADODB.Connection")
  connection.ConnectionString = Application("connectionString")
  connection.Open

  Set command = Server.CreateObject("ADODB.Command")
  Set command.ActiveConnection = connection
  command.CommandType = 1
  command.CommandText = "DELETE FROM [dbo].[tb_login_bridge_tickets] " & _
    "OUTPUT DELETED.[user_id], DELETED.[username] " & _
    "WHERE [ticket_hash] = HASHBYTES('SHA2_256', CONVERT(varbinary(64), ?)) " & _
    "AND [expires_at] > SYSUTCDATETIME()"
  Set parameter = command.CreateParameter("@ticket", 200, 1, 64, ticket)
  command.Parameters.Append parameter

  Set recordset = command.Execute
  If Not recordset.EOF Then
    Session("currentUserId") = recordset.Fields("user_id").Value
    Session("currentUser") = recordset.Fields("username").Value
    recordset.Close
    Set recordset = Nothing
    Set command = Nothing
    connection.Close
    Set connection = Nothing
    Response.Redirect "/default.asp"
  End If

  recordset.Close
  Set recordset = Nothing
  Set command = Nothing
  connection.Close
  Set connection = Nothing
  Response.Redirect Application("loginURL")
%>
