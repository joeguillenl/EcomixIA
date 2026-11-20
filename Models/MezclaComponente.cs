using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace EcomixIA.Models
{
    public class MezclaComponente
    {
        public int Id { get; set; }

        [Required]
        public int MezclaId { get; set; }

        [ForeignKey("MezclaId")]
        public virtual Mezcla Mezcla { get; set; }

        [Required(ErrorMessage = "Selecciona un material.")]
        [Display(Name = "Material")]
        public int MaterialId { get; set; }

        [ForeignKey("MaterialId")]
        public virtual Material Material { get; set; }

        [Required(ErrorMessage = "La cantidad es obligatoria.")]
        [Display(Name = "Cantidad (kg/m³)")]
        [Range(0.01, 5000, ErrorMessage = "La cantidad debe estar entre 0.01 y 5000 kg/m³.")]
        public decimal Cantidad { get; set; }

        /// <summary>
        /// Snapshot histórico inmutable: Costo unitario por kg en el momento de captura (D-09 / RF-14).
        /// Nullable para registros legados previos a la migración H02.
        /// </summary>
        [Display(Name = "Costo por kg guardado (S/)")]
        public decimal? CostoPorKgGuardado { get; set; }

        /// <summary>
        /// Snapshot histórico inmutable: Factor de emisión de CO₂ por kg en el momento de captura (D-09 / RF-15).
        /// Nullable para registros legados previos a la migración H02.
        /// </summary>
        [Display(Name = "CO₂ por kg guardado (kg CO₂/kg)")]
        public decimal? Co2PorKgGuardado { get; set; }

        /// <summary>
        /// Fecha y hora UTC en la que se capturó el snapshot del componente.
        /// </summary>
        [Display(Name = "Fecha snapshot (UTC)")]
        public DateTime? FechaSnapshotUtc { get; set; }

        /// <summary>
        /// Procedencia del snapshot: 'CAPTURADO' para componentes verificados desde catálogo,
        /// o 'LEGADO_SIN_VERIFICAR' para registros históricos preexistentes.
        /// </summary>
        [StringLength(24)]
        [Display(Name = "Origen snapshot")]
        public string OrigenSnapshot { get; set; }
    }
}
