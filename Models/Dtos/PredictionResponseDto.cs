using System.Collections.Generic;
using Newtonsoft.Json;

namespace EcomixIA.Models.Dtos
{
    /// <summary>
    /// Contrato de respuesta exitosa (HTTP 200 OK) retornado por el servicio de inferencia.
    /// </summary>
    public class PredictionResponseDto
    {
        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("predictions")]
        public PredictionValuesDto Predictions { get; set; }

        [JsonProperty("mix_ratios")]
        public MixRatiosDto MixRatios { get; set; }

        [JsonProperty("warnings")]
        public List<DomainWarningDto> Warnings { get; set; } = new List<DomainWarningDto>();

        [JsonProperty("metadata")]
        public PredictionMetadataDto Metadata { get; set; }
    }

    public class PredictionValuesDto
    {
        [JsonProperty("strength_7d_mpa")]
        public decimal Strength7dMpa { get; set; }

        [JsonProperty("strength_28d_mpa")]
        public decimal Strength28dMpa { get; set; }
    }

    public class MixRatiosDto
    {
        [JsonProperty("water_cement_ratio")]
        public decimal WaterCementRatio { get; set; }

        [JsonProperty("water_binder_ratio")]
        public decimal WaterBinderRatio { get; set; }

        [JsonProperty("total_cementitious_content_kg_m3")]
        public decimal TotalCementitiousContentKgM3 { get; set; }

        [JsonProperty("scm_replacement_percentage")]
        public decimal ScmReplacementPercentage { get; set; }

        [JsonProperty("aggregates_total_kg_m3")]
        public decimal AggregatesTotalKgM3 { get; set; }

        [JsonProperty("total_mass_kg_m3")]
        public decimal TotalMassKgM3 { get; set; }
    }

    public class DomainWarningDto
    {
        [JsonProperty("code")]
        public string Code { get; set; }

        [JsonProperty("severity")]
        public string Severity { get; set; }

        [JsonProperty("field")]
        public string Field { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }

        [JsonProperty("observed_value")]
        public object ObservedValue { get; set; }

        [JsonProperty("reference_boundary")]
        public string ReferenceBoundary { get; set; }
    }

    public class PredictionMetadataDto
    {
        [JsonProperty("model_id")]
        public string ModelId { get; set; }

        [JsonProperty("model_type")]
        public string ModelType { get; set; }

        [JsonProperty("model_sha256")]
        public string ModelSha256 { get; set; }

        [JsonProperty("inference_timestamp")]
        public string InferenceTimestamp { get; set; }
    }
}
