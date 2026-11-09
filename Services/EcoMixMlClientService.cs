using System;
using System.Configuration;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using EcomixIA.Models.Dtos;
using Newtonsoft.Json;

namespace EcomixIA.Services
{
    /// <summary>
    /// Cliente HTTP para el microservicio de inferencia de concreto en Azure Container Apps.
    /// Diseñado como Singleton / cliente estático reutilizable para evitar socket exhaustion en .NET Framework.
    /// </summary>
    public class EcoMixMlClientService : IEcoMixMlClientService
    {
        private static readonly HttpClient _httpClient;
        private readonly string _apiKey;

        static EcoMixMlClientService()
        {
            var baseUrl = ConfigurationManager.AppSettings["EcoMix:ApiUrl"]
                ?? "https://ca-ecomix-inference-api.salmontree-d9db53a4.chilecentral.azurecontainerapps.io";

            var timeoutSecondsStr = ConfigurationManager.AppSettings["EcoMix:TimeoutSeconds"];
            var timeoutSeconds = int.TryParse(timeoutSecondsStr, out var t) && t > 0 ? t : 45;

            var handler = new HttpClientHandler
            {
                AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate
            };

            _httpClient = new HttpClient(handler)
            {
                BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/"),
                Timeout = TimeSpan.FromSeconds(timeoutSeconds)
            };
        }

        public EcoMixMlClientService()
        {
            // Busca la clave en Web.config / Web.Secrets.config, o en variable de entorno
            var key = ConfigurationManager.AppSettings["EcoMix:ApiKey"];
            if (string.IsNullOrWhiteSpace(key) || key.StartsWith("DUMMY_"))
            {
                key = Environment.GetEnvironmentVariable("ECOMIX_API_KEY");
            }

            _apiKey = key;
        }

        public async Task<PredictionResponseDto> PredictStrengthAsync(ConcretePredictionRequestDto request, string requestId = null)
        {
            if (request == null)
            {
                throw new ArgumentNullException(nameof(request));
            }

            if (string.IsNullOrWhiteSpace(_apiKey))
            {
                throw new EcoMixMlClientException(
                    "La clave de autenticación del servicio ML no está configurada. Configure 'EcoMix:ApiKey' en Web.Secrets.config o en la variable de entorno ECOMIX_API_KEY.",
                    401
                );
            }

            var jsonPayload = JsonConvert.SerializeObject(request);
            var reqId = string.IsNullOrWhiteSpace(requestId) ? Guid.NewGuid().ToString("N") : requestId;

            using (var httpRequest = new HttpRequestMessage(HttpMethod.Post, "api/v1/predict/concrete-strength"))
            {
                httpRequest.Headers.Add("X-API-Key", _apiKey);
                httpRequest.Headers.Add("X-Request-ID", reqId);
                httpRequest.Content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                HttpResponseMessage response;
                try
                {
                    response = await _httpClient.SendAsync(httpRequest);
                }
                catch (TaskCanceledException ex)
                {
                    throw new EcoMixMlClientException(
                        $"Tiempo de espera agotado al consultar el servicio ML en Azure ({_httpClient.Timeout.TotalSeconds} s). Si el servicio estaba en reposo (0 réplicas), el arranque en frío puede haber tardado más de lo habitual.",
                        408,
                        null,
                        ex
                    );
                }
                catch (HttpRequestException ex)
                {
                    throw new EcoMixMlClientException(
                        $"Error de conectividad de red con el servicio de inferencia en Azure: {ex.Message}",
                        503,
                        null,
                        ex
                    );
                }

                using (response)
                {
                    var responseBody = await response.Content.ReadAsStringAsync();

                    if (!response.IsSuccessStatusCode)
                    {
                        var status = (int)response.StatusCode;

                        if (status == 422)
                        {
                            ProblemDetailsDto problem = null;
                            try
                            {
                                problem = JsonConvert.DeserializeObject<ProblemDetailsDto>(responseBody);
                            }
                            catch { }

                            var detail = problem != null && !string.IsNullOrWhiteSpace(problem.Detail)
                                ? problem.Detail
                                : "La dosificación no cumple con las restricciones físicas o normativas del modelo.";

                            throw new EcoMixMlClientException(detail, 422, problem);
                        }

                        if (status == 401 || status == 403)
                        {
                            throw new EcoMixMlClientException(
                                "Error de autenticación con el servicio de inferencia de Azure (X-API-Key rechazada o inválida).",
                                status
                            );
                        }

                        if (status == 429)
                        {
                            throw new EcoMixMlClientException(
                                "El servicio de inferencia ha alcanzado su límite de tasa de solicitudes (HTTP 429 Rate Limit). Intente nuevamente en unos instantes.",
                                429
                            );
                        }

                        if (status == 503 || status == 500)
                        {
                            throw new EcoMixMlClientException(
                                $"El servicio ML en Azure no pudo procesar la solicitud (HTTP {status}).",
                                status
                            );
                        }

                        throw new EcoMixMlClientException(
                            $"Error inesperado del servicio de inferencia (HTTP {status}): {responseBody}",
                            status
                        );
                    }

                    try
                    {
                        return JsonConvert.DeserializeObject<PredictionResponseDto>(responseBody);
                    }
                    catch (Exception ex)
                    {
                        throw new EcoMixMlClientException(
                            "No se pudo deserializar la respuesta JSON del servicio de inferencia.",
                            500,
                            null,
                            ex
                        );
                    }
                }
            }
        }
    }
}
