using Newtonsoft.Json;

namespace EcomixIA.Models.Dtos
{
    /// <summary>
    /// Contrato de solicitud para el endpoint /api/v1/predict/concrete-strength de FastAPI.
    /// Representa las 7 componentes físicas de dosificación de concreto en kg/m³.
    /// </summary>
    public class ConcretePredictionRequestDto
    {
        [JsonProperty("cement")]
        public decimal Cement { get; set; }

        [JsonProperty("blast_furnace_slag")]
        public decimal BlastFurnaceSlag { get; set; }

        [JsonProperty("fly_ash")]
        public decimal FlyAsh { get; set; }

        [JsonProperty("water")]
        public decimal Water { get; set; }

        [JsonProperty("superplasticizer")]
        public decimal Superplasticizer { get; set; }

        [JsonProperty("coarse_aggregate")]
        public decimal CoarseAggregate { get; set; }

        [JsonProperty("fine_aggregate")]
        public decimal FineAggregate { get; set; }
    }
}
