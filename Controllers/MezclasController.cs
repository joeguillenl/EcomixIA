using System;
using System.Data.Entity;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using EcomixIA.Models;
using EcomixIA.Models.Dtos;
using EcomixIA.Models.ViewModels;
using EcomixIA.Services;
using Newtonsoft.Json;

namespace EcomixIA.Controllers
{
    public class MezclasController : Controller
    {
        private readonly EcomixContext db;
        private readonly IEcoMixMlClientService _mlClientService;

        public MezclasController() : this(new EcomixContext(), new EcoMixMlClientService())
        {
        }

        public MezclasController(EcomixContext context, IEcoMixMlClientService mlClientService)
        {
            this.db = context ?? throw new ArgumentNullException(nameof(context));
            this._mlClientService = mlClientService ?? throw new ArgumentNullException(nameof(mlClientService));
        }

        public ActionResult Index()
        {
            var mezclas = db.Mezclas.OrderBy(m => m.Nombre).ToList();
            return View(mezclas);
        }

        public ActionResult Details(int? id)
        {
            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }
            CargarMateriales();
            return View(mezcla);
        }

        public ActionResult Create()
        {
            return View(new Mezcla());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "Nombre,ResistenciaMPa,EdadDias,RelacionAguaCemento,AsentamientoCm,Notas")] Mezcla mezcla)
        {
            if (!ModelState.IsValid)
            {
                return View(mezcla);
            }

            db.Mezclas.Add(mezcla);
            db.SaveChanges();
            TempData["Mensaje"] = "Mezcla creada. Ahora agrega sus materiales.";
            return RedirectToAction("Details", new { id = mezcla.Id });
        }

        public ActionResult Edit(int? id)
        {
            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }
            return View(mezcla);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "Id,Nombre,ResistenciaMPa,EdadDias,RelacionAguaCemento,AsentamientoCm,Notas")] Mezcla mezcla)
        {
            if (!ModelState.IsValid)
            {
                return View(mezcla);
            }

            db.Entry(mezcla).State = EntityState.Modified;
            db.SaveChanges();
            TempData["Mensaje"] = "Mezcla actualizada correctamente.";
            return RedirectToAction("Details", new { id = mezcla.Id });
        }

        public ActionResult Delete(int? id)
        {
            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }
            return View(mezcla);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            var mezcla = db.Mezclas.Find(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            db.Mezclas.Remove(mezcla);
            db.SaveChanges();
            TempData["Mensaje"] = "Mezcla eliminada correctamente.";
            return RedirectToAction("Index");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult AgregarComponente(int mezclaId, [Bind(Include = "MaterialId,Cantidad")] MezclaComponente componente)
        {
            var mezcla = db.Mezclas.Find(mezclaId);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            componente.MezclaId = mezclaId;
            componente.Mezcla = null;
            componente.Material = null;

            ModelState.Remove("Mezcla");
            ModelState.Remove("Material");

            if (!ModelState.IsValid || !db.Materiales.Any(m => m.Id == componente.MaterialId))
            {
                TempData["Error"] = "Revisa el material y la cantidad del componente.";
                return RedirectToAction("Details", new { id = mezclaId });
            }

            if (db.Componentes.Any(c => c.MezclaId == mezclaId && c.MaterialId == componente.MaterialId))
            {
                TempData["Error"] = "Ese material ya está en la mezcla. Elimínalo y vuelve a agregarlo para cambiar la cantidad.";
                return RedirectToAction("Details", new { id = mezclaId });
            }

            db.Componentes.Add(componente);
            db.SaveChanges();
            TempData["Mensaje"] = "Material agregado a la mezcla.";
            return RedirectToAction("Details", new { id = mezclaId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult EliminarComponente(int id)
        {
            var componente = db.Componentes.Find(id);
            if (componente == null)
            {
                return HttpNotFound();
            }

            int mezclaId = componente.MezclaId;
            db.Componentes.Remove(componente);
            db.SaveChanges();
            TempData["Mensaje"] = "Material eliminado de la mezcla.";
            return RedirectToAction("Details", new { id = mezclaId });
        }

        // =============================================================
        // SIMULADOR DE INFERENCIA ML CONECTADO A AZURE CONTAINER APPS
        // =============================================================

        // GET: Mezclas/Simulador
        [HttpGet]
        public ActionResult Simulador(int? mezclaId)
        {
            var model = new SimuladorDosificacionViewModel();

            if (mezclaId.HasValue)
            {
                var mezcla = BuscarMezcla(mezclaId);
                if (mezcla != null)
                {
                    model.MezclaOrigenId = mezcla.Id;
                    model.MezclaOrigenNombre = mezcla.Nombre;
                    CargarValoresDesdeMezcla(mezcla, model);
                }
            }

            return View(model);
        }

        // POST: Mezclas/Simulador (Formulario POST tradicional)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Simulador(SimuladorDosificacionViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var request = new ConcretePredictionRequestDto
            {
                Cement = model.Cemento,
                BlastFurnaceSlag = model.EscoriaAltoHorno,
                FlyAsh = model.CenizaVolante,
                Water = model.Agua,
                Superplasticizer = model.Superplastificante,
                CoarseAggregate = model.AgregadoGrueso,
                FineAggregate = model.AgregadoFino
            };

            var sw = Stopwatch.StartNew();
            try
            {
                var response = await _mlClientService.PredictStrengthAsync(request);
                sw.Stop();

                model.Ejecutado = true;
                model.Resultado = response;
                model.LatenciaMs = sw.ElapsedMilliseconds;
            }
            catch (EcoMixMlClientException ex)
            {
                sw.Stop();
                model.Ejecutado = false;
                model.LatenciaMs = sw.ElapsedMilliseconds;
                model.ErrorMensaje = ex.Message;
                model.ErrorDetalle = ex.ProblemDetails;
            }
            catch (Exception ex)
            {
                sw.Stop();
                model.Ejecutado = false;
                model.LatenciaMs = sw.ElapsedMilliseconds;
                model.ErrorMensaje = "Ocurrió un error inesperado al consultar el servicio ML: " + ex.Message;
            }

            return View(model);
        }

        // POST: Mezclas/SimularAjax (Llamada asíncrona interactiva con Json.NET)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> SimularAjax(SimuladorDosificacionViewModel model)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                return Content(JsonConvert.SerializeObject(new { success = false, message = "Formulario con datos inválidos.", errors }), "application/json");
            }

            var request = new ConcretePredictionRequestDto
            {
                Cement = model.Cemento,
                BlastFurnaceSlag = model.EscoriaAltoHorno,
                FlyAsh = model.CenizaVolante,
                Water = model.Agua,
                Superplasticizer = model.Superplastificante,
                CoarseAggregate = model.AgregadoGrueso,
                FineAggregate = model.AgregadoFino
            };

            var sw = Stopwatch.StartNew();
            try
            {
                var response = await _mlClientService.PredictStrengthAsync(request);
                sw.Stop();

                return Content(JsonConvert.SerializeObject(new
                {
                    success = true,
                    latencyMs = sw.ElapsedMilliseconds,
                    data = response
                }), "application/json");
            }
            catch (EcoMixMlClientException ex)
            {
                sw.Stop();
                return Content(JsonConvert.SerializeObject(new
                {
                    success = false,
                    latencyMs = sw.ElapsedMilliseconds,
                    statusCode = ex.StatusCode,
                    message = ex.Message,
                    details = ex.ProblemDetails
                }), "application/json");
            }
            catch (Exception ex)
            {
                sw.Stop();
                return Content(JsonConvert.SerializeObject(new
                {
                    success = false,
                    latencyMs = sw.ElapsedMilliseconds,
                    statusCode = 500,
                    message = "Error inesperado: " + ex.Message
                }), "application/json");
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }

        private Mezcla BuscarMezcla(int? id)
        {
            if (id == null)
            {
                return null;
            }
            return db.Mezclas
                .Include(m => m.Componentes.Select(c => c.Material))
                .FirstOrDefault(m => m.Id == id.Value);
        }

        private void CargarMateriales()
        {
            ViewBag.Materiales = new SelectList(
                db.Materiales.OrderBy(m => m.Tipo).ThenBy(m => m.Nombre).ToList(),
                "Id",
                "Nombre");
        }

        private void CargarValoresDesdeMezcla(Mezcla mezcla, SimuladorDosificacionViewModel model)
        {
            if (mezcla?.Componentes == null || !mezcla.Componentes.Any())
            {
                return;
            }

            var comps = mezcla.Componentes.ToList();

            // Cemento
            var cemento = comps.Where(c => c.Material != null && c.Material.Tipo == "Cemento").Sum(c => c.Cantidad);
            if (cemento > 0) model.Cemento = cemento;

            // Escoria
            var escoria = comps.Where(c => c.Material != null && c.Material.Nombre.IndexOf("Escoria", StringComparison.OrdinalIgnoreCase) >= 0).Sum(c => c.Cantidad);
            model.EscoriaAltoHorno = escoria;

            // Ceniza / Puzolana
            var ceniza = comps.Where(c => c.Material != null && (c.Material.Nombre.IndexOf("Ceniza", StringComparison.OrdinalIgnoreCase) >= 0 || c.Material.Nombre.IndexOf("Puzolana", StringComparison.OrdinalIgnoreCase) >= 0)).Sum(c => c.Cantidad);
            model.CenizaVolante = ceniza;

            // Agua
            var agua = comps.Where(c => c.Material != null && c.Material.Tipo == "Agua").Sum(c => c.Cantidad);
            if (agua > 0) model.Agua = agua;

            // Superplastificante
            var sp = comps.Where(c => c.Material != null && (c.Material.Tipo == "Aditivo" || c.Material.Nombre.IndexOf("Superplastificante", StringComparison.OrdinalIgnoreCase) >= 0)).Sum(c => c.Cantidad);
            model.Superplastificante = sp;

            // Agregado Grueso
            var grueso = comps.Where(c => c.Material != null && (c.Material.Tipo == "Agregado grueso" || (c.Material.Tipo == "Agregado" && c.Material.Nombre.IndexOf("Piedra", StringComparison.OrdinalIgnoreCase) >= 0))).Sum(c => c.Cantidad);
            if (grueso > 0) model.AgregadoGrueso = grueso;

            // Agregado Fino
            var fino = comps.Where(c => c.Material != null && (c.Material.Tipo == "Agregado fino" || (c.Material.Tipo == "Agregado" && c.Material.Nombre.IndexOf("Arena", StringComparison.OrdinalIgnoreCase) >= 0))).Sum(c => c.Cantidad);
            if (fino > 0) model.AgregadoFino = fino;
        }
    }
}
