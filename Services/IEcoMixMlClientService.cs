using System.Threading.Tasks;
using EcomixIA.Models.Dtos;

namespace EcomixIA.Services
{
    /// <summary>
    /// Contrato de servicio para la comunicación HTTP cliente con el motor de inferencia ML en Azure.
    /// </summary>
    public interface IEcoMixMlClientService
    {
        /// <summary>
        /// Invoca el endpoint de predicción de resistencia de concreto (7 y 28 días).
        /// </summary>
        /// <param name="request">7 cantidades físicas de la dosificación en kg/m³.</param>
        /// <param name="requestId">Identificador único de trazabilidad (X-Request-ID).</param>
        /// <returns>Respuesta con estimaciones de resistencia, ratios físicos y advertencias ACI.</returns>
        Task<PredictionResponseDto> PredictStrengthAsync(ConcretePredictionRequestDto request, string requestId = null);
    }
}
