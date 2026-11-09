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

        [NotMapped]
        [Display(Name = "Costo por m³")]
        public decimal CostoPorM3 => Componentes?.Any() == true ? Componentes.Sum(c => c.Cantidad * (c.Material != null ? c.Material.CostoPorKg : 0m)) : 0m;

        [NotMapped]
        [Display(Name = "CO₂ por m³")]
        public decimal Co2PorM3 => Componentes?.Any() == true ? Componentes.Sum(c => c.Cantidad * (c.Material != null ? c.Material.Co2PorKg : 0m)) : 0m;

        [NotMapped]
        [Display(Name = "Masa total por m³ (kg)")]
        public decimal MasaTotalPorM3 => Componentes?.Any() == true ? Componentes.Sum(c => c.Cantidad) : 0m;
    }
}
