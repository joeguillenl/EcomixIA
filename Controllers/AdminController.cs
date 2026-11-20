using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using EcomixIA.Models;
using EcomixIA.Models.ViewModels;
using EcomixIA.Services;

namespace EcomixIA.Controllers
{
    [Authorize(Roles = "Administrador")]
    public class AdminController : Controller
    {
        private ApplicationUserManager _userManager;
        private ApplicationRoleManager _roleManager;
        private ApplicationDbContext _dbContext;
        private readonly IAuditService _auditService;

        public AdminController()
            : this(null, null, null, new AuditService())
        {
        }

        public AdminController(
            ApplicationUserManager userManager,
            ApplicationRoleManager roleManager,
            ApplicationDbContext dbContext,
            IAuditService auditService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _dbContext = dbContext;
            _auditService = auditService ?? new AuditService();
        }

        public ApplicationUserManager UserManager
        {
            get => _userManager ?? HttpContext?.GetOwinContext()?.GetUserManager<ApplicationUserManager>();
            private set => _userManager = value;
        }

        public ApplicationRoleManager RoleManager
        {
            get => _roleManager ?? HttpContext?.GetOwinContext()?.Get<ApplicationRoleManager>();
            private set => _roleManager = value;
        }

        public ApplicationDbContext DbContext
        {
            get => _dbContext ?? HttpContext?.GetOwinContext()?.Get<ApplicationDbContext>();
            private set => _dbContext = value;
        }

        private string CurrentUserId
        {
            get
            {
                try
                {
                    if (System.Web.HttpContext.Current != null && System.Web.HttpContext.Current.User != null)
                    {
                        return System.Web.HttpContext.Current.User.Identity.GetUserId();
                    }
                    return null;
                }
                catch { return null; }
            }
        }

        private string CurrentUserEmail
        {
            get
            {
                try
                {
                    if (System.Web.HttpContext.Current != null && System.Web.HttpContext.Current.User != null)
                    {
                        return System.Web.HttpContext.Current.User.Identity.GetUserName();
                    }
                    return null;
                }
                catch { return null; }
            }
        }

        private string ClientIp
        {
            get
            {
                try
                {
                    if (System.Web.HttpContext.Current != null && System.Web.HttpContext.Current.Request != null)
                    {
                        return System.Web.HttpContext.Current.Request.UserHostAddress ?? "127.0.0.1";
                    }
                    return "127.0.0.1";
                }
                catch { return "127.0.0.1"; }
            }
        }

        //
        // GET: /Admin / /Admin/Dashboard
        public async Task<ActionResult> Index()
        {
            return await Dashboard();
        }

        //
        // GET: /Admin/Dashboard
        public async Task<ActionResult> Dashboard()
        {
            var stats = await _auditService.GetDashboardStatsAsync(DbContext);

            // Obtener últimos eventos administrativos activos
            var recentEvents = await _auditService.GetActiveEvents(DbContext)
                .Where(e => e.Category == "Admin" || e.Category == "Security")
                .OrderByDescending(e => e.TimestampUtc)
                .Take(10)
                .ToListAsync();

            var vm = new AdminDashboardViewModel
            {
                Stats = stats,
                RecentAdminEvents = recentEvents
            };

            return View("Dashboard", vm);
        }

        //
        // GET: /Admin/Users
        public async Task<ActionResult> Users(string searchEmail, int page = 1, int pageSize = 10)
        {
            if (page < 1) page = 1;
            if (pageSize < 5) pageSize = 5;
            if (pageSize > 50) pageSize = 50;

            var query = DbContext.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(searchEmail))
            {
                string searchTrim = searchEmail.Trim().ToLowerInvariant();
                query = query.Where(u => u.Email.ToLower().Contains(searchTrim) || u.UserName.ToLower().Contains(searchTrim));
            }

            int totalUsers = await query.CountAsync();
            int totalPages = (int)Math.Ceiling((double)totalUsers / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (page > totalPages) page = totalPages;

            var usersPage = await query
                .OrderBy(u => u.Email)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userItems = new List<AdminUserItemViewModel>();
            foreach (var u in usersPage)
            {
                var roles = await UserManager.GetRolesAsync(u.Id);
                bool isLocked = await UserManager.IsLockedOutAsync(u.Id);

                userItems.Add(new AdminUserItemViewModel
                {
                    UserId = u.Id,
                    Email = u.Email,
                    UserName = u.UserName,
                    Roles = roles.ToList(),
                    IsEnabled = u.IsEnabled,
                    EmailConfirmed = u.EmailConfirmed,
                    IsLockedOut = isLocked,
                    AccessFailedCount = u.AccessFailedCount
                });
            }

            var vm = new AdminUsersListViewModel
            {
                Users = userItems,
                SearchEmail = searchEmail,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalUsers = totalUsers,
                PageSize = pageSize,
                CurrentUserId = CurrentUserId
            };

            return View("Users", vm);
        }

        //
        // POST: /Admin/ToggleUserStatus
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ToggleUserStatus(string userId)
        {
            if (TempData == null) TempData = new TempDataDictionary();
            if (string.IsNullOrWhiteSpace(userId))
            {
                return new HttpStatusCodeResult(400, "Identificador de usuario no proporcionado.");
            }

            var user = await UserManager.FindByIdAsync(userId);
            if (user == null)
            {
                return HttpNotFound();
            }

            bool willDisable = user.IsEnabled;

            // PROTECCIÓN CRÍTICA (H04-B / D-10): No deshabilitar al último administrador activo
            if (willDisable && await UserManager.IsInRoleAsync(user.Id, "Administrador"))
            {
                int activeAdminCount = await CountActiveAdministratorsAsync();
                if (activeAdminCount <= 1)
                {
                    await _auditService.LogEventAsync(
                        "Admin",
                        "BlockDisableLastAdmin",
                        false,
                        CurrentUserId,
                        CurrentUserEmail,
                        $"Intento bloqueado de deshabilitar al último Administrador activo ({user.Email}).",
                        ClientIp);

                    TempData["MensajeError"] = "Operación bloqueada por seguridad: No es posible deshabilitar al último Administrador activo del sistema.";
                    return RedirectToAction("Users");
                }
            }

            user.IsEnabled = !user.IsEnabled;
            var updateResult = await UserManager.UpdateAsync(user);

            if (updateResult.Succeeded)
            {
                // Invalidar sesiones activas del usuario modificado mediante cambio de SecurityStamp
                await UserManager.UpdateSecurityStampAsync(user.Id);

                await _auditService.LogEventAsync(
                    "Admin",
                    user.IsEnabled ? "UserEnabled" : "UserDisabled",
                    true,
                    CurrentUserId,
                    CurrentUserEmail,
                    $"Usuario {user.Email} {(user.IsEnabled ? "habilitado" : "deshabilitado")} por administrador.",
                    ClientIp);

                TempData["MensajeExito"] = $"La cuenta {user.Email} ha sido {(user.IsEnabled ? "habilitada" : "deshabilitada")} exitosamente.";
            }
            else
            {
                TempData["MensajeError"] = "Error al actualizar el estado de la cuenta.";
            }

            return RedirectToAction("Users");
        }

        //
        // POST: /Admin/ChangeUserRole
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> ChangeUserRole(string userId, string targetRole)
        {
            if (TempData == null) TempData = new TempDataDictionary();
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(targetRole))
            {
                return new HttpStatusCodeResult(400, "Parámetros incompletos.");
            }

            if (targetRole != "Registrado" && targetRole != "Administrador")
            {
                return new HttpStatusCodeResult(400, "Rol no reconocido.");
            }

            var user = await UserManager.FindByIdAsync(userId);
            if (user == null)
            {
                return HttpNotFound();
            }

            bool isCurrentlyAdmin = await UserManager.IsInRoleAsync(user.Id, "Administrador");

            // PROTECCIÓN CRÍTICA: No revocar privilegios al último administrador activo
            if (isCurrentlyAdmin && targetRole == "Registrado")
            {
                int activeAdminCount = await CountActiveAdministratorsAsync();
                if (activeAdminCount <= 1)
                {
                    await _auditService.LogEventAsync(
                        "Admin",
                        "BlockRevokeLastAdmin",
                        false,
                        CurrentUserId,
                        CurrentUserEmail,
                        $"Intento bloqueado de revocar rol al último Administrador activo ({user.Email}).",
                        ClientIp);

                    TempData["MensajeError"] = "Operación bloqueada por seguridad: No es posible revocar privilegios al último Administrador activo del sistema.";
                    return RedirectToAction("Users");
                }
            }

            // Aplicar cambio de rol
            if (targetRole == "Administrador")
            {
                if (!isCurrentlyAdmin)
                {
                    await UserManager.AddToRoleAsync(user.Id, "Administrador");
                }
            }
            else if (targetRole == "Registrado")
            {
                if (isCurrentlyAdmin)
                {
                    await UserManager.RemoveFromRoleAsync(user.Id, "Administrador");
                }
                if (!await UserManager.IsInRoleAsync(user.Id, "Registrado"))
                {
                    await UserManager.AddToRoleAsync(user.Id, "Registrado");
                }
            }

            // Invalidar sesiones activas del usuario para forzar revalidación de claims de rol
            await UserManager.UpdateSecurityStampAsync(user.Id);

            await _auditService.LogEventAsync(
                "Admin",
                "RoleChanged",
                true,
                CurrentUserId,
                CurrentUserEmail,
                $"Rol de {user.Email} cambiado a '{targetRole}' por administrador.",
                ClientIp);

            TempData["MensajeExito"] = $"El rol de {user.Email} ha sido modificado a '{targetRole}' exitosamente.";
            return RedirectToAction("Users");
        }

        //
        // GET: /Admin/Audit
        public async Task<ActionResult> Audit(
            string category,
            bool? success,
            string searchTerm,
            DateTime? startDate,
            DateTime? endDate,
            int page = 1,
            int pageSize = 20)
        {
            if (page < 1) page = 1;
            if (pageSize < 10) pageSize = 10;
            if (pageSize > 100) pageSize = 100;

            // Exclusión innegociable de registros anteriores a 30 días (RF-49 / D-07)
            var cutoffUtc = DateTime.UtcNow.AddDays(-30);
            var query = _auditService.GetActiveEvents(DbContext, cutoffUtc);

            if (!string.IsNullOrWhiteSpace(category))
            {
                query = query.Where(e => e.Category == category);
            }

            if (success.HasValue)
            {
                query = query.Where(e => e.Success == success.Value);
            }

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                string term = searchTerm.Trim().ToLowerInvariant();
                query = query.Where(e => e.Action.ToLower().Contains(term) ||
                                         e.ActorEmail.ToLower().Contains(term) ||
                                         e.Details.ToLower().Contains(term));
            }

            if (startDate.HasValue)
            {
                var sUtc = startDate.Value.ToUniversalTime();
                if (sUtc < cutoffUtc) sUtc = cutoffUtc; // Blindaje: no permitir consultar antes del corte
                query = query.Where(e => e.TimestampUtc >= sUtc);
            }

            if (endDate.HasValue)
            {
                var eUtc = endDate.Value.ToUniversalTime().AddDays(1); // Final del día
                query = query.Where(e => e.TimestampUtc <= eUtc);
            }

            int totalEvents = await query.CountAsync();
            int totalPages = (int)Math.Ceiling((double)totalEvents / pageSize);
            if (totalPages < 1) totalPages = 1;
            if (page > totalPages) page = totalPages;

            var eventsPage = await query
                .OrderByDescending(e => e.TimestampUtc)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var vm = new AdminAuditListViewModel
            {
                Events = eventsPage,
                Category = category,
                SuccessFilter = success,
                SearchTerm = searchTerm,
                StartDateUtc = startDate,
                EndDateUtc = endDate,
                RetentionCutoffUtc = cutoffUtc,
                CurrentPage = page,
                TotalPages = totalPages,
                TotalEvents = totalEvents,
                PageSize = pageSize
            };

            return View("Audit", vm);
        }

        //
        // POST: /Admin/PurgeAudit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> PurgeAudit()
        {
            if (TempData == null) TempData = new TempDataDictionary();
            var cutoffUtc = DateTime.UtcNow.AddDays(-30);
            int purged = await _auditService.PurgeExpiredEventsAsync(DbContext, batchSize: 500, cutoffUtc: cutoffUtc);

            await _auditService.LogEventAsync(
                "Admin",
                "AuditPurged",
                true,
                CurrentUserId,
                CurrentUserEmail,
                $"Depuración física completada: Se eliminaron {purged} registros de auditoría anteriores a 30 días.",
                ClientIp);

            TempData["MensajeExito"] = $"Depuración física ejecutada: Se purgaron {purged} eventos anteriores al corte ({cutoffUtc:dd/MM/yyyy HH:mm} UTC).";
            return RedirectToAction("Audit");
        }

        private async Task<int> CountActiveAdministratorsAsync()
        {
            var adminRole = await RoleManager.FindByNameAsync("Administrador");
            if (adminRole == null) return 0;

            // Conteo directo y atómico sin depender de lazy loading en colecciones de Identity
            string sql = @"
                SELECT COUNT(*) 
                FROM [dbo].[AspNetUsers] u
                INNER JOIN [dbo].[AspNetUserRoles] ur ON u.Id = ur.UserId
                WHERE ur.RoleId = @roleId AND u.IsEnabled = 1";

            var roleParam = new System.Data.SqlClient.SqlParameter("@roleId", adminRole.Id);
            return await DbContext.Database.SqlQuery<int>(sql, roleParam).FirstOrDefaultAsync();
        }
    }
}
