<% Option Explicit %>
<%
  If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
    Response.Status = "405 Method Not Allowed"
    Response.End
  End If

  Session("currentUser") = ""
  Session("currentUserId") = ""
  Response.Redirect Application("loginURL")
%>
