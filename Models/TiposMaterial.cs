using System.Collections.Generic;

namespace EcomixIA.Models
{
    public static class TiposMaterial
    {
        public static readonly IReadOnlyList<string> Todos = new List<string>
        {
            "Cemento",
            "Adición",
            "Agregado fino",
            "Agregado grueso",
            "Agua",
            "Aditivo"
        };
    }
}
