using System;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.Hosting;
using Newtonsoft.Json;

namespace EcomixIA.Services
{
    public class SimulatedEmailRecord
    {
        public string Id { get; set; }
        public DateTime TimestampUtc { get; set; }
        public string To { get; set; }
        public string Subject { get; set; }
        public string BodyHtml { get; set; }
        public string ExtractedCallbackUrl { get; set; }
    }

    public class SimulatedEmailService : ITransactionalEmailSender
    {
        private readonly string _outboxDirectory;

        public SimulatedEmailService(string outboxDirectory = null)
        {
            if (!string.IsNullOrWhiteSpace(outboxDirectory))
            {
                _outboxDirectory = outboxDirectory;
            }
            else if (HostingEnvironment.IsHosted)
            {
                _outboxDirectory = HostingEnvironment.MapPath("~/App_Data/EmailOutbox");
            }
            else
            {
                _outboxDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "App_Data", "EmailOutbox");
            }

            if (!Directory.Exists(_outboxDirectory))
            {
                Directory.CreateDirectory(_outboxDirectory);
            }
        }

        public string OutboxDirectory => _outboxDirectory;

        public Task SendEmailAsync(string toEmail, string subject, string bodyHtml)
        {
            if (string.IsNullOrWhiteSpace(toEmail))
            {
                throw new ArgumentException("El destinatario no puede ser nulo o vacío.", nameof(toEmail));
            }

            // Extraer URL de confirmación si existe para facilitar las pruebas de ensayo
            string extractedUrl = null;
            var match = Regex.Match(bodyHtml ?? string.Empty, @"href=[""']([^""']+)[""']");
            if (match.Success)
            {
                extractedUrl = match.Groups[1].Value;
            }

            var record = new SimulatedEmailRecord
            {
                Id = Guid.NewGuid().ToString("N"),
                TimestampUtc = DateTime.UtcNow,
                To = toEmail.Trim().ToLowerInvariant(),
                Subject = subject,
                BodyHtml = bodyHtml,
                ExtractedCallbackUrl = extractedUrl
            };

            string filename = $"{record.TimestampUtc:yyyyMMdd_HHmmss}_{record.Id.Substring(0, 8)}.json";
            string filePath = Path.Combine(_outboxDirectory, filename);

            string json = JsonConvert.SerializeObject(record, Formatting.Indented);
            File.WriteAllText(filePath, json, System.Text.Encoding.UTF8);

            // Registro en traza sin exponer el token ni contraseñas
            Trace.WriteLine($"[SimulatedEmailService] Mensaje simulado guardado para: {record.To} | Asunto: {record.Subject} | Archivo: {filename}");

            return Task.FromResult(0);
        }
    }
}
