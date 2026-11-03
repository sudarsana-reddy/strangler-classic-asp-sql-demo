<html>
  <head>
    <title>Classic ASP</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/uikit/3.0.0-beta.25/css/uikit.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/default.min.css" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/vs2015.min.css" />
    <link rel="stylesheet" href="css/style.css" />
  </head>
  <body>
    <div class="uk-container">
      <nav class="site-navbar" aria-label="Main navigation">
        <a class="site-navbar-home" href="default.asp">Home</a>
        <% If Session("currentUser") <> "" Then %>
          <div class="site-nav-account">
            <span>Signed in as <%= Server.HTMLEncode(Session("currentUser")) %></span>
            <a class="site-logout-button" href="<%= Server.HTMLEncode(Application("gatewayURL") & "/logout") %>">Logout</a>
          </div>
        <% End If %>
      </nav>
      <div class="main-content">
    <!-- main content is in here -->
  