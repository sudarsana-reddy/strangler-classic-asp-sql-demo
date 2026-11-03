# Classic ASP strangler migration

The solution separates the application into three parts:

- `Gateway` is an ASP.NET Core 10 YARP reverse proxy. It sends `/`, `/session-login.asp`, `/logout`, and the `/loginapp/*` asset path to the modern login app, sends the session bridge endpoints to Classic ASP, and sends all other paths to Classic ASP.
- `LoginApp` is the ASP.NET Core 10/C# SQL-backed login UI. It retains the existing `tb_users` password verification behavior.
- `LegacyApp` contains the remaining Classic ASP pages and assets. The old `session-login.asp` page has been removed.

## Database

Run these scripts against the `learnasp` SQL Server database in order:

1. `LegacyApp/files/tb_users.sql`
2. `LegacyApp/files/tb_login_bridge_tickets.sql`

The first script creates the demo user (`demo` / `ClassicAsp!2026`) if it does not exist. Change or remove that account before using the application outside a local demo.

The login app stores only the SHA-256 hash of a random, short-lived, single-use bridge ticket. After SQL authentication, the browser posts that ticket through YARP to `LegacyApp/_bridge/session.asp`; the bridge consumes it and sets Classic ASP `Session("currentUser")` and `Session("currentUserId")`. The browser then redirects to `/default.asp` on the Gateway host, retaining the Classic ASP session cookie. Unauthenticated legacy requests and completed logout redirect to the canonical Gateway root (`Application("loginURL")`) in `LegacyApp\global.asa`.

Configure the login app connection string with `ConnectionStrings__LearnAsp` when the default local SQL Express connection is not suitable. Configure the legacy connection string in `LegacyApp/global.asa` for the same database.

## Deploy as three IIS applications

Deploy `Gateway`, `LoginApp`, and `LegacyApp` independently. The intended single-server IIS bindings are:

| App | IIS binding / application path | Exposure |
|---|---|---|
| `Gateway` | Public site binding (for example `https://app.example.com`) | Public |
| `LoginApp` | `http://127.0.0.1:5011/` | Loopback only |
| `LegacyApp` | `http://127.0.0.1:8200/` | Loopback only |

Use separate IIS application pools. Set the two ASP.NET Core pools to **No Managed Code** and install the .NET 10 Hosting Bundle on the IIS server. Enable Classic ASP on the legacy site, install the `MSOLEDBSQL` provider, and grant the legacy application pool identity access to its app files and required data files. Keep only the Gateway binding externally reachable.

Publish the .NET apps separately:

```powershell
dotnet publish LoginApp\LoginApp.csproj -c Release -o C:\inetpub\LoginApp
dotnet publish Gateway\Gateway.csproj -c Release -o C:\inetpub\Gateway
```

In IIS, create one site/application and pool per published app. Bind `LoginApp` to `127.0.0.1:8202`. Bind `Gateway` to the public hostname and configure its TLS certificate there. Create the Classic ASP `LegacyApp` as a separate IIS site bound to `127.0.0.1:8200`, with the site root pointing directly to the `LegacyApp` directory. Do not create a `/learn-classic-asp` child application: the site name is an IIS label, not a URL path segment.

Run the database scripts above before enabling traffic. Configure `ConnectionStrings__LearnAsp` for the LoginApp IIS application pool identity, and configure the Classic ASP connection string in `LegacyApp\global.asa` for that same database. Set `Application("gatewayURL")` in `LegacyApp\global.asa` to the externally reachable Gateway origin (for this local setup, `http://localhost:8201`); the legacy site's login and logout links use this origin.

The YARP destinations are in `Gateway\appsettings.json`. For deployment on a different host or port, set these Gateway application environment variables:

```text
ReverseProxy__Clusters__modern-login__Destinations__login-app__Address=http://<login-host>:<port>/
ReverseProxy__Clusters__legacy__Destinations__classic-asp__Address=http://<legacy-host>:<port>/
```

The legacy fallback route forwards paths unchanged to the LegacyApp site root. Keep the legacy bridge at `/_bridge/session.asp` and the home page at `/default.asp` on the Gateway host so the browser retains and sends the Classic ASP session cookie. Do not expose the backend bindings to external clients.

LoginApp owns its UI and static assets. Its stylesheet is referenced at `/loginapp/css/site.css`; YARP forwards only that app-scoped prefix to LoginApp and removes the prefix before forwarding, so legacy `/css/*` paths continue to belong to LegacyApp.

## Run locally

For development, start `LoginApp` on `http://127.0.0.1:8202` and `Gateway` on `http://localhost:8201`. Host `LegacyApp` in IIS with the binding and site root in the table above, then browse to `http://localhost:8201/`.
