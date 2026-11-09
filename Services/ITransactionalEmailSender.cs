using System.Threading.Tasks;

namespace EcomixIA.Services
{
    public interface ITransactionalEmailSender
    {
        Task SendEmailAsync(string toEmail, string subject, string bodyHtml);
    }
}
