using System;
using System.Linq;
using System.Threading.Tasks;
using EcomixIA.Models;

namespace EcomixIA.Services
{
    public class AdminDashboardStatsDto
    {
        public int TotalUsuarios { get; set; }
        public int UsuariosHabilitados { get; set; }
        public int UsuariosDeshabilitados { get; set; }
        public int InvocacionesML { get; set; }
        public int ErroresOperativos { get; set; }
        public int ActividadAdministrativa { get; set; }
        public DateTime RetentionCutoffUtc { get; set; }
    }

    public interface IAuditService
    {
        Task LogEventAsync(
            string category,
            string action,
            bool success,
            string userId = null,
            string actorEmail = null,
            string details = null,
            string ipAddress = null,
            string correlationId = null);

        IQueryable<AuditEvent> GetActiveEvents(ApplicationDbContext db, DateTime? cutoffUtc = null);

        Task<int> PurgeExpiredEventsAsync(ApplicationDbContext db, int batchSize = 500, DateTime? cutoffUtc = null);

        Task<AdminDashboardStatsDto> GetDashboardStatsAsync(ApplicationDbContext db, DateTime? cutoffUtc = null);
    }
}
