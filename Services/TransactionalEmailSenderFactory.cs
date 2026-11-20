using System;
using System.Configuration;

namespace EcomixIA.Services
{
    public static class TransactionalEmailSenderFactory
    {
        private static ITransactionalEmailSender _customSender;

        public static void SetCustomSender(ITransactionalEmailSender sender)
        {
            _customSender = sender;
        }

        public static void ResetCustomSender()
        {
            _customSender = null;
        }

        public static ITransactionalEmailSender CreateFromConfiguration()
        {
            if (_customSender != null)
            {
                return _customSender;
            }

            string provider = ConfigurationManager.AppSettings["EcoMix:EmailProvider"];

            if (string.Equals(provider, "Smtp", StringComparison.OrdinalIgnoreCase))
            {
                return new SmtpTransactionalEmailSender();
            }

            if (string.Equals(provider, "HttpApi", StringComparison.OrdinalIgnoreCase))
            {
                return new HttpApiTransactionalEmailSender();
            }

            // Proveedor predeterminado para desarrollo, CI y pruebas locales (D-03)
            return new SimulatedEmailService();
        }
    }
}
