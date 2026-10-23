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
    }
}
