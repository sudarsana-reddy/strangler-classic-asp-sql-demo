using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace LoginApp.Pages;

public sealed class TransferModel : PageModel
{
    public string Ticket { get; private set; } = "";

    public IActionResult OnGet()
    {
        Ticket = TempData["SessionTicket"] as string ?? "";
        return Ticket.Length == 64 ? Page() : RedirectToPage("/Index");
    }
}
