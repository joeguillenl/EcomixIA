using System.Collections.Generic;

namespace EcomixIA.Models.ViewModels
{
    /// <summary>
    /// Modelo de vista para el Dashboard Personal del Usuario Autenticado (D-04 / RF-41 a RF-43).
    /// Contiene los 3 KPIs consolidados calculados exclusivamente sobre mezclas privadas del usuario.
    /// </summary>
    public class DashboardViewModel
    {
        /// <summary>
        /// Correo o identificador de sesión del usuario propietario autenticado.
        /// </summary>
        public string UsuarioEmail { get; set; }

        /// <summary>
        /// KPI 1 (RF-41): Cantidad total de mezclas privadas guardadas por el usuario actual.
        /// </summary>
        public int TotalMezclasPrivadas { get; set; }

        /// <summary>
        /// KPI 2 (RF-42): Media aritmética del costo por m³ (S/) de las mezclas con capturas completas.
        /// Null si el usuario no tiene mezclas con snapshots verificados (se presenta como 'Sin datos').
        /// </summary>
        public decimal? CostoPromedioPorM3 { get; set; }

        /// <summary>
        /// KPI 3 (RF-43): Media aritmética de emisiones de CO₂ por m³ (kg CO₂/m³) de mezclas con capturas completas.
        /// Null si el usuario no tiene mezclas con snapshots verificados (se presenta como 'Sin datos').
        /// </summary>
        public decimal? Co2PromedioPorM3 { get; set; }

        /// <summary>
        /// Número de mezclas privadas con snapshots 100% capturados y verificados.
        /// </summary>
        public int MezclasConCapturasCompletas { get; set; }

        /// <summary>
        /// Número de mezclas privadas legadas o con componentes pendientes de validación.
        /// </summary>
        public int MezclasPendientesValidacion { get; set; }

        /// <summary>
        /// Últimas mezclas privadas del usuario para acceso rápido.
        /// </summary>
        public List<Mezcla> MezclasRecientes { get; set; } = new List<Mezcla>();
    }
}
