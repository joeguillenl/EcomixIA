using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;
using EcomixIA.Models;
using EcomixIA.Models.ViewModels;
using Microsoft.AspNet.Identity;

namespace EcomixIA.Controllers
{
    /// <summary>
    /// Controlador del Dashboard Personal del Usuario Autenticado (D-04 / RF-41 a RF-43).
    /// Asegura aislamiento multi-inquilino estricto por OwnerUserId en servidor.
    /// </summary>
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly EcomixContext db;

        public DashboardController()
        {
            db = new EcomixContext();
        }

        public DashboardController(EcomixContext context)
        {
            db = context;
        }

        private string CurrentUserId => User?.Identity != null ? User.Identity.GetUserId() : null;

        // GET: Dashboard
        [HttpGet]
        public ActionResult Index()
        {
            var userId = CurrentUserId;
            if (string.IsNullOrEmpty(userId))
            {
                return RedirectToAction("Login", "Account");
            }

            // Regla D-04 / Seguridad: Filtrar estrictamente por OwnerUserId
            // El administrador tampoco visualiza mezclas ajenas en su dashboard personal
            var misMezclas = db.Mezclas
                .Include(m => m.Componentes.Select(c => c.Material))
                .Where(m => m.OwnerUserId == userId)
                .OrderByDescending(m => m.Id)
                .ToList();

            int totalMezclas = misMezclas.Count;

            // Identificar mezclas con capturas completas y verificadas (D-09)
            var mezclasCompletas = misMezclas
                .Where(m => m.TieneSnapshotsCompletos)
                .ToList();

            decimal? costoPromedio = null;
            decimal? co2Promedio = null;

            if (mezclasCompletas.Any())
            {
                // Medias aritméticas por mezcla (no sumas de presupuesto)
                costoPromedio = mezclasCompletas.Average(m => m.CostoHistoricoPorM3.Value);
                co2Promedio = mezclasCompletas.Average(m => m.Co2HistoricoPorM3.Value);
            }

            var vm = new DashboardViewModel
            {
                UsuarioEmail = User.Identity.Name,
                TotalMezclasPrivadas = totalMezclas,
                CostoPromedioPorM3 = costoPromedio,
                Co2PromedioPorM3 = co2Promedio,
                MezclasConCapturasCompletas = mezclasCompletas.Count,
                MezclasPendientesValidacion = totalMezclas - mezclasCompletas.Count,
                MezclasRecientes = misMezclas.Take(5).ToList()
            };

            return View(vm);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && db != null)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
