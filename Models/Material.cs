using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace EcomixIA.Models
{
    public class Material
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "El nombre es obligatorio.")]
        [StringLength(100)]
        [Display(Name = "Nombre")]
        public string Nombre { get; set; }

        [Required(ErrorMessage = "El tipo es obligatorio.")]
        [StringLength(50)]
        [Display(Name = "Tipo")]
        public string Tipo { get; set; }

        [Display(Name = "Densidad relativa")]
        [Range(0.5, 5, ErrorMessage = "La densidad relativa debe estar entre 0.5 y 5.")]
        public decimal? DensidadRelativa { get; set; }

        [Required(ErrorMessage = "El costo por kg es obligatorio.")]
        [Display(Name = "Costo por kg")]
        [Range(0, 100000, ErrorMessage = "El costo debe ser mayor o igual a 0.")]
        public decimal CostoPorKg { get; set; }

        [Required(ErrorMessage = "La emisión de CO₂ por kg es obligatoria.")]
        [Display(Name = "Emisión de CO₂ por kg")]
        [Range(0, 100000, ErrorMessage = "La emisión debe ser mayor o igual a 0.")]
        public decimal Co2PorKg { get; set; }

        [StringLength(500)]
        [Display(Name = "Notas")]
        public string Notas { get; set; }

        public virtual ICollection<MezclaComponente> Componentes { get; set; } = new List<MezclaComponente>();
    }
}
