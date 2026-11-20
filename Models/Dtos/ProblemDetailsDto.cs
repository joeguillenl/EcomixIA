using System.Collections.Generic;
using Newtonsoft.Json;

namespace EcomixIA.Models.Dtos
{
    /// <summary>
    /// Estándar RFC 7807 para representación estructurada de errores de validación de dominio.
    /// Retornado por FastAPI ante errores de validación (HTTP 422), parámetros inválidos (HTTP 400),
    /// autenticación (HTTP 401/403) o indisponibilidad (HTTP 503).
    /// </summary>
    public class ProblemDetailsDto
    {
        [JsonProperty("type")]
        public string Type { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; }

        [JsonProperty("status")]
        public int Status { get; set; }

        [JsonProperty("detail")]
        public string Detail { get; set; }

        [JsonProperty("instance")]
        public string Instance { get; set; }

        [JsonProperty("invalid_fields")]
        public List<InvalidFieldDto> InvalidFields { get; set; } = new List<InvalidFieldDto>();

        [JsonProperty("timestamp")]
        public string Timestamp { get; set; }
    }

    /// <summary>
    /// Detalle de campo inválido devuelto en la colección invalid_fields de ProblemDetails.
    /// </summary>
    public class InvalidFieldDto
    {
        [JsonProperty("field")]
        public string Field { get; set; }

        [JsonProperty("value")]
        public object Value { get; set; }

        [JsonProperty("constraint")]
        public string Constraint { get; set; }

        [JsonProperty("limit")]
        public object Limit { get; set; }

        [JsonProperty("unit")]
        public string Unit { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }
    }
}
