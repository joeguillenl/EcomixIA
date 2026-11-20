using System;
using System.Configuration;
using System.Diagnostics;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace EcomixIA.Services
{
    /// <summary>
    /// Adaptador SMTP estándar de .NET Framework (System.Net.Mail).
    /// COMPATIBILIDAD CRÍTICA (H04-A):
    /// SmtpClient en .NET Framework implementa STARTTLS explícito en puerto 587 (con EnableSsl = true).
    /// El puerto 465 (Implicit SSL/SMTPS) no está soportado nativamente por SmtpClient en .NET 4.7.2.
    /// Por ende, para relays transaccionales (Brevo, SendGrid, etc.) debe emplearse estrictamente el puerto 587 con STARTTLS.
    /// </summary>
    public class SmtpTransactionalEmailSender : ITransactionalEmailSender
    {
        private readonly string _host;
        private readonly int _port;
        private readonly bool _enableSsl;
        private readonly string _user;
        private readonly string _password;
        private readonly string _fromAddress;
        private readonly string _fromName;

        public SmtpTransactionalEmailSender(
            string host = null,
            int? port = null,
            bool? enableSsl = null,
            string user = null,
            string password = null,
            string fromAddress = null,
            string fromName = null)
        {
            _host = host ?? ConfigurationManager.AppSettings["EcoMix:Smtp:Host"];
            _port = port ?? (int.TryParse(ConfigurationManager.AppSettings["EcoMix:Smtp:Port"], out int p) ? p : 587);
            _enableSsl = enableSsl ?? (!string.Equals(ConfigurationManager.AppSettings["EcoMix:Smtp:EnableSsl"], "false", StringComparison.OrdinalIgnoreCase));
            _user = user ?? ConfigurationManager.AppSettings["EcoMix:Smtp:User"];
            _password = password ?? ConfigurationManager.AppSettings["EcoMix:Smtp:Password"];
            _fromAddress = fromAddress ?? ConfigurationManager.AppSettings["EcoMix:Email:FromAddress"] ?? "notificaciones@ecomixia.com";
            _fromName = fromName ?? ConfigurationManager.AppSettings["EcoMix:Email:FromName"] ?? "EcoMix IA Notificaciones";
        }

        public async Task SendEmailAsync(string toEmail, string subject, string bodyHtml)
        {
            var result = await SendWithResultAsync(toEmail, subject, bodyHtml);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException($"Error al enviar correo vía SMTP: {result.ErrorMessage}");
            }
        }

        public async Task<EmailDeliveryResult> SendWithResultAsync(string toEmail, string subject, string bodyHtml)
        {
            if (string.IsNullOrWhiteSpace(toEmail))
            {
                return EmailDeliveryResult.Failed("El correo de destino es obligatorio.", "Smtp");
            }

            if (string.IsNullOrWhiteSpace(_host))
            {
                Trace.WriteLine("[SmtpSender] Proveedor SMTP no aprovisionado. Host no configurado.");
                return EmailDeliveryResult.Failed("Proveedor SMTP no configurado en este entorno.", "Smtp", transient: true);
            }

            try
            {
                using (var client = new SmtpClient(_host, _port))
                {
                    client.EnableSsl = _enableSsl;
                    client.Timeout = 15000; // 15 segundos

                    if (!string.IsNullOrWhiteSpace(_user) && !string.IsNullOrWhiteSpace(_password))
                    {
                        client.UseDefaultCredentials = false;
                        client.Credentials = new NetworkCredential(_user, _password);
                    }

                    var from = new MailAddress(_fromAddress, _fromName, System.Text.Encoding.UTF8);
                    var to = new MailAddress(toEmail);

                    using (var mail = new MailMessage(from, to))
                    {
                        mail.Subject = subject;
                        mail.Body = bodyHtml;
                        mail.IsBodyHtml = true;
                        mail.SubjectEncoding = System.Text.Encoding.UTF8;
                        mail.BodyEncoding = System.Text.Encoding.UTF8;

                        await client.SendMailAsync(mail);
                    }
                }

                Trace.WriteLine($"[SmtpSender] Mensaje enviado exitosamente vía SMTP a: {toEmail} | Asunto: {subject}");
                return EmailDeliveryResult.Success(Guid.NewGuid().ToString("N"), "Smtp");
            }
            catch (SmtpException smtpEx)
            {
                Trace.WriteLine($"[SmtpSender] SmtpException: {smtpEx.StatusCode} - {smtpEx.Message}");
                return EmailDeliveryResult.Failed($"Error de protocolo SMTP ({smtpEx.StatusCode}): {smtpEx.Message}", "Smtp", transient: true);
            }
            catch (Exception ex)
            {
                Trace.WriteLine($"[SmtpSender] Excepción general al enviar correo: {ex.Message}");
                return EmailDeliveryResult.Failed(ex.Message, "Smtp", transient: true);
            }
        }
    }
}
