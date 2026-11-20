using System;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using EcomixIA.Models;

namespace EcomixIA.Services
{
    public class AuditService : IAuditService
    {
        private readonly Func<ApplicationDbContext> _contextFactory;
        private static DateTime _lastOpportunisticPurgeUtc = DateTime.MinValue;
        private static readonly System.Threading.SemaphoreSlim _purgeSemaphore = new System.Threading.SemaphoreSlim(1, 1);

        public AuditService() : this(() => new ApplicationDbContext())
        {
        }

        public AuditService(string nameOrConnectionString)
            : this(() => new ApplicationDbContext(nameOrConnectionString))
        {
        }

        public AuditService(Func<ApplicationDbContext> contextFactory)
        {
            _contextFactory = contextFactory ?? (() => new ApplicationDbContext());
        }

        public async Task LogEventAsync(
            string category,
            string action,
            bool success,
            string userId = null,
            string actorEmail = null,
            string details = null,
            string ipAddress = null,
            string correlationId = null)
        {
            try
            {
                using (var db = _contextFactory())
                {
                    var evt = new AuditEvent
                    {
                        Category = Truncate(category, 64) ?? "General",
                        Action = Truncate(action, 64) ?? "Unknown",
                        Success = success,
                        UserId = Truncate(userId, 128),
                        ActorEmail = Truncate(actorEmail, 256),
                        Details = SanitizeDetails(details),
                        IpAddress = Truncate(ipAddress, 45),
                        CorrelationId = Truncate(correlationId ?? Guid.NewGuid().ToString("N"), 64),
                        TimestampUtc = DateTime.UtcNow
                    };

                    db.AuditEvents.Add(evt);
                    await db.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                // La auditoría nunca debe derribar la transacción principal de negocio si la base falla
                Trace.WriteLine($"[AuditService] Error no fatal al persistir evento de auditoría: {ex.Message}");
            }
        }

        public IQueryable<AuditEvent> GetActiveEvents(ApplicationDbContext db, DateTime? cutoffUtc = null)
        {
            if (db == null) throw new ArgumentNullException(nameof(db));

            // Política de retención estricta de 30 días (D-07 / RF-49)
            var effectiveCutoff = cutoffUtc ?? DateTime.UtcNow.AddDays(-30);

            // Activación oportunista de depuración física controlada (H05-A5 / D-07)
            TriggerOpportunisticPurge(db, effectiveCutoff);

            return db.AuditEvents
                .Where(e => e.TimestampUtc >= effectiveCutoff);
        }

        public async Task<int> PurgeExpiredEventsAsync(ApplicationDbContext db, int batchSize = 500, DateTime? cutoffUtc = null)
        {
            if (db == null) throw new ArgumentNullException(nameof(db));

            var effectiveCutoff = cutoffUtc ?? DateTime.UtcNow.AddDays(-30);
            int totalDeleted = 0;

            // Protección de concurrencia para evitar purgas simultáneas (H05-A5)
            await _purgeSemaphore.WaitAsync();
            try
            {
                int deletedInBatch;
                do
                {
                    var pBatch = new SqlParameter("@batchSize", batchSize > 0 ? batchSize : 500);
                    var pCutoff = new SqlParameter("@cutoff", effectiveCutoff);

                    string sql = "DELETE TOP (@batchSize) FROM [dbo].[AuditEvents] WHERE [TimestampUtc] < @cutoff";
                    deletedInBatch = await db.Database.ExecuteSqlCommandAsync(sql, pBatch, pCutoff);
                    totalDeleted += deletedInBatch;

                } while (deletedInBatch > 0 && totalDeleted < 50000); // Límite de seguridad para evitar bloqueos prolongados

                if (totalDeleted > 0)
                {
                    Trace.WriteLine($"[AuditService] Depuración física completada: {totalDeleted} registros eliminados anteriores a {effectiveCutoff:yyyy-MM-dd HH:mm:ss} UTC");
                }

                _lastOpportunisticPurgeUtc = DateTime.UtcNow;
            }
            finally
            {
                _purgeSemaphore.Release();
            }

            return totalDeleted;
        }

        private void TriggerOpportunisticPurge(ApplicationDbContext db, DateTime cutoffUtc)
        {
            // Disparar purga oportunista no bloqueante si ha transcurrido al menos 1 hora desde la última ejecución
            if (DateTime.UtcNow - _lastOpportunisticPurgeUtc >= TimeSpan.FromHours(1))
            {
                _lastOpportunisticPurgeUtc = DateTime.UtcNow;
                Task.Run(async () =>
                {
                    if (await _purgeSemaphore.WaitAsync(0))
                    {
                        try
                        {
                            using (var localDb = _contextFactory())
                            {
                                var pBatch = new SqlParameter("@batchSize", 500);
                                var pCutoff = new SqlParameter("@cutoff", cutoffUtc);
                                string sql = "DELETE TOP (@batchSize) FROM [dbo].[AuditEvents] WHERE [TimestampUtc] < @cutoff";
                                await localDb.Database.ExecuteSqlCommandAsync(sql, pBatch, pCutoff);
                            }
                        }
                        catch (Exception ex)
                        {
                            Trace.WriteLine($"[AuditService] Purga oportunista omitida por error: {ex.Message}");
                        }
                        finally
                        {
                            _purgeSemaphore.Release();
                        }
                    }
                });
            }
        }

        public async Task<AdminDashboardStatsDto> GetDashboardStatsAsync(ApplicationDbContext db, DateTime? cutoffUtc = null)
        {
            if (db == null) throw new ArgumentNullException(nameof(db));

            var effectiveCutoff = cutoffUtc ?? DateTime.UtcNow.AddDays(-30);

            int totalUsers = await db.Users.CountAsync();
            int enabledUsers = await db.Users.CountAsync(u => u.IsEnabled);
            int disabledUsers = totalUsers - enabledUsers;

            // Consultas agregadas sobre eventos activos dentro de los 30 días (RF-50)
            var activeEvents = db.AuditEvents.Where(e => e.TimestampUtc >= effectiveCutoff);

            int mlInvocations = await activeEvents.CountAsync(e => e.Category == "ML");
            int operationalErrors = await activeEvents.CountAsync(e => !e.Success);
            int adminActivity = await activeEvents.CountAsync(e => e.Category == "Admin");

            return new AdminDashboardStatsDto
            {
                TotalUsuarios = totalUsers,
                UsuariosHabilitados = enabledUsers,
                UsuariosDeshabilitados = disabledUsers,
                InvocacionesML = mlInvocations,
                ErroresOperativos = operationalErrors,
                ActividadAdministrativa = adminActivity,
                RetentionCutoffUtc = effectiveCutoff
            };
        }

        private static string Truncate(string val, int maxLen)
        {
            if (string.IsNullOrEmpty(val)) return null;
            return val.Length <= maxLen ? val : val.Substring(0, maxLen);
        }

        private static string SanitizeDetails(string input)
        {
            if (string.IsNullOrWhiteSpace(input)) return null;

            // 1. Erradicación de contraseñas, tokens, firmas y claves de autenticación (H05-A4)
            string sanitized = Regex.Replace(input, @"(Password|Contraseña|Token|Key|ApiKey|Secret|Bearer|Authorization|signature|sig)\s*[:=]\s*[^;&,\s]+", "$1=[PROTEGIDO]", RegexOptions.IgnoreCase);

            // 2. Erradicación de cadenas de conexión completas o parciales
            sanitized = Regex.Replace(sanitized, @"(Data Source|Initial Catalog|User ID|Password|Server|Database)\s*=\s*[^;]+", "$1=[PROTEGIDO]", RegexOptions.IgnoreCase);

            // 3. Erradicación de rutas del sistema de archivos local (Windows y Unix)
            sanitized = Regex.Replace(sanitized, @"[A-Za-z]:\\[\w\s\.-]+(?:\\[\w\s\.-]+)*", "[RUTA_PROTEGIDA]");
            sanitized = Regex.Replace(sanitized, @"/(?:Users|home|var|etc|app|inetpub)/[\w\.-]+(?:/[\w\.-]+)*", "[RUTA_PROTEGIDA]");

            // 4. Erradicación de trazas de pila internas (stack traces)
            sanitized = Regex.Replace(sanitized, @"\s+at\s+[\w\.<>]+(?:\([^\)]*\))?", " [STACK_PROTEGIDO]");

            return sanitized;
        }
    }
}
