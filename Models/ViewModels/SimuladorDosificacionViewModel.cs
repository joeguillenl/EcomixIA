using System.ComponentModel.DataAnnotations;
using EcomixIA.Models.Dtos;

namespace EcomixIA.Models.ViewModels
{
    /// <summary>
    /// Modelo de vista para el simulador interactivo de dosificaciones y estimación de resistencia.
    /// </summary>
    public class SimuladorDosificacionViewModel
    {
        // -------------------------------------------------------------
        // Parámetros de Entrada (7 componentes en kg/m³)
        // -------------------------------------------------------------
        [Required(ErrorMessage = "La cantidad de cemento es obligatoria.")]
        [Display(Name = "Cemento Portland")]
        [Range(0, 1500, ErrorMessage = "El cemento debe estar entre 0 y 1500 kg/m³.")]
        public decimal Cemento { get; set; } = 280;

        [Required(ErrorMessage = "La cantidad de escoria es obligatoria.")]
        [Display(Name = "Escoria de alto horno (Slag)")]
        [Range(0, 1000, ErrorMessage = "La escoria debe estar entre 0 y 1000 kg/m³.")]
        public decimal EscoriaAltoHorno { get; set; } = 0;

        [Required(ErrorMessage = "La cantidad de ceniza volante es obligatoria.")]
        [Display(Name = "Ceniza volante / Puzolana (Fly Ash)")]
        [Range(0, 1000, ErrorMessage = "La ceniza volante debe estar entre 0 y 1000 kg/m³.")]
        public decimal CenizaVolante { get; set; } = 0;

        [Required(ErrorMessage = "La cantidad de agua es obligatoria.")]
        [Display(Name = "Agua de mezclado")]
        [Range(1, 1000, ErrorMessage = "El agua debe ser mayor a 0 y hasta 1000 kg/m³.")]
        public decimal Agua { get; set; } = 180;

        [Required(ErrorMessage = "La cantidad de superplastificante es obligatoria.")]
        [Display(Name = "Aditivo Superplastificante")]
        [Range(0, 100, ErrorMessage = "El superplastificante debe estar entre 0 y 100 kg/m³.")]
        public decimal Superplastificante { get; set; } = 0;

        [Required(ErrorMessage = "La cantidad de agregado grueso es obligatoria.")]
        [Display(Name = "Agregado grueso (Piedra / Grava)")]
        [Range(0, 3000, ErrorMessage = "El agregado grueso debe estar entre 0 y 3000 kg/m³.")]
        public decimal AgregadoGrueso { get; set; } = 1050;

        [Required(ErrorMessage = "La cantidad de agregado fino es obligatoria.")]
        [Display(Name = "Agregado fino (Arena)")]
        [Range(0, 3000, ErrorMessage = "El agregado fino debe estar entre 0 y 3000 kg/m³.")]
        public decimal AgregadoFino { get; set; } = 750;

        // Contexto si la simulación parte de una mezcla guardada
        public int? MezclaOrigenId { get; set; }
        public string MezclaOrigenNombre { get; set; }

        // -------------------------------------------------------------
        // Resultados y Telemetría de la Inferencia ML
        // -------------------------------------------------------------
        public bool Ejecutado { get; set; }
        public PredictionResponseDto Resultado { get; set; }
        public long LatenciaMs { get; set; }
        public string ErrorMensaje { get; set; }
        public ProblemDetailsDto ErrorDetalle { get; set; }
    }
}
