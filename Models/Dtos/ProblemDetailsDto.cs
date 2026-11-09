using System.Collections.Generic;
using Newtonsoft.Json;

namespace EcomixIA.Models.Dtos
{
    /// <summary>
    /// Estándar RFC 7807 para representación estructurada de errores de validación de dominio.
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

        [JsonProperty("invalid_fields")]
        public List<InvalidFieldDto> InvalidFields { get; set; } = new List<InvalidFieldDto>();
    }

    public class InvalidFieldDto
    {
        [JsonProperty("field")]
        public string Field { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }
    }
}
