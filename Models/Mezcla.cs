using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;

namespace EcomixIA.Models
{
    public class Mezcla
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "El nombre es obligatorio.")]
        [StringLength(100)]
        [Display(Name = "Nombre")]
        public string Nombre { get; set; }

        [Required(ErrorMessage = "La resistencia de diseño es obligatoria.")]
        [Display(Name = "Resistencia f'c (MPa)")]
        [Range(1, 150, ErrorMessage = "La resistencia debe estar entre 1 y 150 MPa.")]
        public decimal ResistenciaMPa { get; set; }

        [Required(ErrorMessage = "La edad de diseño es obligatoria.")]
        [Display(Name = "Edad de diseño (días)")]
        [Range(1, 365, ErrorMessage = "La edad debe estar entre 1 y 365 días.")]
        public int EdadDias { get; set; } = 28;

        [Display(Name = "Relación agua/cemento")]
        [Range(0.2, 1.0, ErrorMessage = "La relación a/c debe estar entre 0.20 y 1.00.")]
        public decimal? RelacionAguaCemento { get; set; }

        [Display(Name = "Asentamiento (cm)")]
        [Range(0, 30, ErrorMessage = "El asentamiento debe estar entre 0 y 30 cm.")]
        public decimal? AsentamientoCm { get; set; }

        [StringLength(500)]
        [Display(Name = "Notas")]
        public string Notas { get; set; }

        /// <summary>
        /// Identificador del usuario propietario en AspNetUsers (Fase 3: Mezclas Privadas).
        /// Nullable para mantener aisladas las fórmulas legadas de Fase 1 bajo Safe Denial.
        /// </summary>
        [StringLength(128)]
        [Display(Name = "Propietario")]
        public string OwnerUserId { get; set; }

        public virtual ICollection<MezclaComponente> Componentes { get; set; } = new List<MezclaComponente>();

        /// <summary>
        /// Determina si la mezcla cuenta con snapshots históricos completos y verificados (D-09).
        /// Exige que la mezcla posea al menos un componente y que el 100% de ellos cuenten con
        /// OrigenSnapshot == "CAPTURADO" y valores unitarios no nulos.
        /// </summary>
        [NotMapped]
        public bool TieneSnapshotsCompletos =>
            Componentes != null &&
            Componentes.Any() &&
            Componentes.All(c => c.OrigenSnapshot == "CAPTURADO" &&
                                 c.CostoPorKgGuardado.HasValue &&
                                 c.Co2PorKgGuardado.HasValue);

        /// <summary>
        /// Costo histórico inmutable por m³ (S/ por m³) (RF-14).
        /// Únicamente válido (no nulo) cuando todos los componentes tienen snapshots completos y procedencia CAPTURADO.
        /// Retorna null si la mezcla es legada o tiene capturas pendientes.
        /// </summary>
        [NotMapped]
        [Display(Name = "Costo histórico por m³")]
        public decimal? CostoHistoricoPorM3 =>
            TieneSnapshotsCompletos
                ? Componentes.Sum(c => c.Cantidad * c.CostoPorKgGuardado.Value)
                : (decimal?)null;

        /// <summary>
        /// Emisión histórica de CO₂ por m³ (kg CO₂/m³) (RF-15).
        /// Únicamente válida (no nula) cuando todos los componentes tienen snapshots completos y procedencia CAPTURADO.
        /// Retorna null si la mezcla es legada o tiene capturas pendientes.
        /// </summary>
        [NotMapped]
        [Display(Name = "CO₂ histórico por m³")]
        public decimal? Co2HistoricoPorM3 =>
            TieneSnapshotsCompletos
                ? Componentes.Sum(c => c.Cantidad * c.Co2PorKgGuardado.Value)
                : (decimal?)null;

        /// <summary>
        /// Masa total verificada por m³ (kg/m³).
        /// Suma determinística de las cantidades de todos los componentes.
        /// </summary>
        [NotMapped]
        [Display(Name = "Masa total por m³")]
        public decimal MasaTotalPorM3 =>
            Componentes?.Any() == true ? Componentes.Sum(c => c.Cantidad) : 0m;

        /// <summary>
        /// Estimación de costo calculada con los precios vigentes del catálogo de materiales.
        /// Se presenta explícitamente como referencial para mezclas sin snapshots verificados.
        /// </summary>
        [NotMapped]
        [Display(Name = "Costo referencial actual por m³")]
        public decimal CostoReferencialActualPorM3 =>
            Componentes?.Any() == true
                ? Componentes.Sum(c => c.Cantidad * (c.Material != null ? c.Material.CostoPorKg : 0m))
                : 0m;

        /// <summary>
        /// Estimación de emisiones de CO₂ calculada con los factores vigentes del catálogo de materiales.
        /// Se presenta explícitamente como referencial para mezclas sin snapshots verificados.
        /// </summary>
        [NotMapped]
        [Display(Name = "CO₂ referencial actual por m³")]
        public decimal Co2ReferencialActualPorM3 =>
            Componentes?.Any() == true
                ? Componentes.Sum(c => c.Cantidad * (c.Material != null ? c.Material.Co2PorKg : 0m))
                : 0m;

        /// <summary>
        /// Propiedad de compatibilidad general.
        /// </summary>
        [NotMapped]
        [Display(Name = "Costo por m³")]
        public decimal CostoPorM3 => CostoHistoricoPorM3 ?? CostoReferencialActualPorM3;

        /// <summary>
        /// Propiedad de compatibilidad general.
        /// </summary>
        [NotMapped]
        [Display(Name = "CO₂ por m³")]
        public decimal Co2PorM3 => Co2HistoricoPorM3 ?? Co2ReferencialActualPorM3;
    }
}
