using System.Threading.Tasks;

namespace EcomixIA.Services
{
    public class EmailDeliveryResult
    {
        public bool Succeeded { get; set; }
        public string MessageId { get; set; }
        public string ProviderName { get; set; }
        public string ErrorMessage { get; set; }
        public bool IsTransientError { get; set; }

        public static EmailDeliveryResult Success(string messageId, string provider)
        {
            return new EmailDeliveryResult
            {
                Succeeded = true,
                MessageId = messageId,
                ProviderName = provider
            };
        }

        public static EmailDeliveryResult Failed(string error, string provider, bool transient = false)
        {
            return new EmailDeliveryResult
            {
                Succeeded = false,
                ErrorMessage = error,
                ProviderName = provider,
                IsTransientError = transient
            };
        }
    }

    public interface ITransactionalEmailSender
    {
        Task SendEmailAsync(string toEmail, string subject, string bodyHtml);
        Task<EmailDeliveryResult> SendWithResultAsync(string toEmail, string subject, string bodyHtml);
    }
}
