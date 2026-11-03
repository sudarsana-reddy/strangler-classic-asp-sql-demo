using System.ComponentModel.DataAnnotations;
using System.Data;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;

namespace LoginApp.Pages;

public sealed class IndexModel(IConfiguration configuration) : PageModel
{
    [BindProperty]
    public LoginInput Input { get; set; } = new();

    public string? ErrorMessage { get; private set; }

    public async Task<IActionResult> OnPostAsync(CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        var username = Input.Username.Trim();
        var connectionString = configuration.GetConnectionString("LearnAsp")
            ?? throw new InvalidOperationException("ConnectionStrings:LearnAsp is not configured.");

        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        await using var validateCommand = new SqlCommand(
            """
            SELECT [user_id], [username]
            FROM [dbo].[tb_users]
            WHERE [username] = @username
              AND [password_hash] = HASHBYTES(
                    'SHA2_512',
                    [password_salt] + CONVERT(varbinary(512), @password))
              AND [is_active] = 1;
            """,
            connection);
        validateCommand.Parameters.Add("@username", SqlDbType.NVarChar, 100).Value = username;
        validateCommand.Parameters.Add("@password", SqlDbType.NVarChar, 256).Value = Input.Password;

        int userId;
        string authenticatedUsername;
        await using (var reader = await validateCommand.ExecuteReaderAsync(cancellationToken))
        {
            if (!await reader.ReadAsync(cancellationToken))
            {
                ErrorMessage = "Username or password is incorrect.";
                return Page();
            }

            userId = reader.GetInt32(0);
            authenticatedUsername = reader.GetString(1);
        }

        var ticket = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var ticketHash = SHA256.HashData(Encoding.ASCII.GetBytes(ticket));

        await using (var ticketCommand = new SqlCommand(
            """
            DELETE FROM [dbo].[tb_login_bridge_tickets]
            WHERE [expires_at] <= SYSUTCDATETIME();

            INSERT INTO [dbo].[tb_login_bridge_tickets]
                ([ticket_hash], [user_id], [username], [expires_at])
            VALUES
                (@ticket_hash, @user_id, @username, DATEADD(MINUTE, 2, SYSUTCDATETIME()));
            """,
            connection))
        {
            ticketCommand.Parameters.Add("@ticket_hash", SqlDbType.VarBinary, 32).Value = ticketHash;
            ticketCommand.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
            ticketCommand.Parameters.Add("@username", SqlDbType.NVarChar, 100).Value = authenticatedUsername;
            await ticketCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Name, authenticatedUsername)
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        TempData["SessionTicket"] = ticket;
        return RedirectToPage("/Transfer");
    }

    public sealed class LoginInput
    {
        [Required]
        [StringLength(100)]
        [Display(Name = "Username")]
        public string Username { get; set; } = "";

        [Required]
        [StringLength(256)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; } = "";
    }
}
