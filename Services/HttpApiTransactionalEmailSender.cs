using System;
using System.Configuration;
using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace EcomixIA.Services
{
    public class HttpApiTransactionalEmailSender : ITransactionalEmailSender
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiUrl;
        private readonly string _apiKey;
        private readonly string _fromAddress;
        private readonly string _fromName;

        public HttpApiTransactionalEmailSender(
            HttpClient httpClient = null,
            string apiUrl = null,
            string apiKey = null,
            string fromAddress = null,
            string fromName = null)
        {
            _httpClient = httpClient ?? new HttpClient();
            _apiUrl = apiUrl ?? ConfigurationManager.AppSettings["EcoMix:HttpEmail:ApiUrl"];
            _apiKey = apiKey ?? ConfigurationManager.AppSettings["EcoMix:HttpEmail:ApiKey"];
            _fromAddress = fromAddress ?? ConfigurationManager.AppSettings["EcoMix:Email:FromAddress"] ?? "notificaciones@ecomixia.com";
            _fromName = fromName ?? ConfigurationManager.AppSettings["EcoMix:Email:FromName"] ?? "EcoMix IA Notificaciones";
        }

        public async Task SendEmailAsync(string toEmail, string subject, string bodyHtml)
        {
            var result = await SendWithResultAsync(toEmail, subject, bodyHtml);
            if (!result.Succeeded)
            {
                throw new InvalidOperationException($"Error al enviar correo vía API HTTPS: {result.ErrorMessage}");
            }
        }

        public async Task<EmailDeliveryResult> SendWithResultAsync(string toEmail, string subject, string bodyHtml)
        {
            if (string.IsNullOrWhiteSpace(toEmail))
            {
                return EmailDeliveryResult.Failed("El correo de destino es obligatorio.", "HttpApi");
            }

            if (string.IsNullOrWhiteSpace(_apiUrl) || string.IsNullOrWhiteSpace(_apiKey))
            {
                Trace.WriteLine("[HttpApiSender] Proveedor API HTTPS no aprovisionado. Claves o URL no configuradas.");
                return EmailDeliveryResult.Failed("Proveedor API HTTPS no configurado en este entorno.", "HttpApi", transient: true);
            }

            try
            {
                var payload = new
                {
                    from = $"{_fromName} <{_fromAddress}>",
                    to = new[] { toEmail },
                    subject = subject,
                    html = bodyHtml
                };

                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");

                using (var req = new HttpRequestMessage(HttpMethod.Post, _apiUrl))
                {
                    req.Content = content;
                    req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);

                    var resp = await _httpClient.SendAsync(req);
                    string respBody = await resp.Content.ReadAsStringAsync();

                    if (!resp.IsSuccessStatusCode)
                    {
                        Trace.WriteLine($"[HttpApiSender] Respuesta fallida HTTP {(int)resp.StatusCode}: {resp.StatusCode}");
                        return EmailDeliveryResult.Failed($"HTTP {(int)resp.StatusCode}: {resp.ReasonPhrase}", "HttpApi", transient: (int)resp.StatusCode >= 500);
                    }

                    Trace.WriteLine($"[HttpApiSender] Correo despachado exitosamente vía API HTTPS a {toEmail}");
                    return EmailDeliveryResult.Success(Guid.NewGuid().ToString("N"), "HttpApi");
                }
            }
            catch (Exception ex)
            {
                Trace.WriteLine($"[HttpApiSender] Excepción al invocar API HTTPS: {ex.Message}");
                return EmailDeliveryResult.Failed(ex.Message, "HttpApi", transient: true);
            }
        }
    }
}
