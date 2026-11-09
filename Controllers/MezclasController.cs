using System;
using System.Data.Entity;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
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

        private string CurrentUserId => (User != null && User.Identity.IsAuthenticated) ? User.Identity.GetUserId() : null;

        // GET: Mezclas
        public ActionResult Index()
        {
            // Fase 3: Mezclas Privadas por Usuario (D-01 / D-08 / AUTH-09 / AUTH-10)
            // Si el usuario no ha iniciado sesión, no se muestran mezclas.
            if (!Request.IsAuthenticated || string.IsNullOrEmpty(CurrentUserId))
            {
                ViewBag.IsAnonymous = true;
                return View(Enumerable.Empty<Mezcla>().ToList());
            }

            // Cada usuario autenticado visualiza EXCLUSIVAMENTE sus fórmulas guardadas
            var mezclasUsuario = db.Mezclas
                .Include(m => m.Componentes.Select(c => c.Material))
                .Where(m => m.OwnerUserId == CurrentUserId)
                .OrderByDescending(m => m.Id)
                .ToList();

            return View(mezclasUsuario);
        }

        // GET: Mezclas/Details/5
        public ActionResult Details(int? id)
        {
            if (!id.HasValue)
            {
                return HttpNotFound();
            }

            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            // Safe Denial Completo: Bloqueo estricto a mezclas legadas sin propietario o pertenecientes a otro usuario
            if (string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Esta mezcla es privada y no pertenece a su cuenta (D-01 / D-08).");
            }

            CargarMateriales();
            return View(mezcla);
        }

        // GET: Mezclas/Create
        [Authorize(Roles = "Registrado,Administrador")]
        public ActionResult Create()
        {
            return View(new Mezcla());
        }

        // POST: Mezclas/Create
        [HttpPost]
        [Authorize(Roles = "Registrado,Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "Nombre,ResistenciaMPa,EdadDias,RelacionAguaCemento,AsentamientoCm,Notas")] Mezcla mezcla)
        {
            if (string.IsNullOrEmpty(CurrentUserId))
            {
                return new HttpStatusCodeResult(401, "Autenticación requerida para crear mezclas.");
            }

            if (!ModelState.IsValid)
            {
                return View(mezcla);
            }

            // Asignación criptográfica del propietario actual
            mezcla.OwnerUserId = CurrentUserId;
            db.Mezclas.Add(mezcla);
            db.SaveChanges();

            TempData["Mensaje"] = "Mezcla creada correctamente. Ahora agrega sus materiales.";
            return RedirectToAction("Details", new { id = mezcla.Id });
        }

        // GET: Mezclas/Edit/5
        [Authorize(Roles = "Registrado,Administrador")]
        public ActionResult Edit(int? id)
        {
            if (!id.HasValue)
            {
                return HttpNotFound();
            }

            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            // Safe Denial: Edición bloqueada para fórmulas ajenas o sin propietario
            if (string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: No tiene permisos de edición sobre esta mezcla (D-01 / D-08).");
            }

            return View(mezcla);
        }

        // POST: Mezclas/Edit/5
        [HttpPost]
        [Authorize(Roles = "Registrado,Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "Id,Nombre,ResistenciaMPa,EdadDias,RelacionAguaCemento,AsentamientoCm,Notas")] Mezcla mezcla)
        {
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            var existente = db.Mezclas.Find(mezcla.Id);
            if (existente == null)
            {
                return HttpNotFound();
            }

            // Verificación estricta de propiedad
            if (string.IsNullOrEmpty(existente.OwnerUserId) || existente.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Modificación bloqueada para mezclas ajenas o sin propietario (D-01 / D-08).");
            }

            if (!ModelState.IsValid)
            {
                return View(mezcla);
            }

            existente.Nombre = mezcla.Nombre;
            existente.ResistenciaMPa = mezcla.ResistenciaMPa;
            existente.EdadDias = mezcla.EdadDias;
            existente.RelacionAguaCemento = mezcla.RelacionAguaCemento;
            existente.AsentamientoCm = mezcla.AsentamientoCm;
            existente.Notas = mezcla.Notas;

            db.SaveChanges();
            TempData["Mensaje"] = "Mezcla actualizada correctamente.";
            return RedirectToAction("Details", new { id = mezcla.Id });
        }

        // GET: Mezclas/Delete/5
        [Authorize(Roles = "Registrado,Administrador")]
        public ActionResult Delete(int? id)
        {
            if (!id.HasValue)
            {
                return HttpNotFound();
            }

            var mezcla = BuscarMezcla(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            // Safe Denial: Eliminación bloqueada para mezclas ajenas o sin propietario
            if (string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: No tiene permisos de eliminación sobre esta mezcla (D-01 / D-08).");
            }

            return View(mezcla);
        }

        // POST: Mezclas/Delete/5
        [HttpPost, ActionName("Delete")]
        [Authorize(Roles = "Registrado,Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            var mezcla = db.Mezclas.Find(id);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            if (string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Eliminación bloqueada para mezclas ajenas o sin propietario (D-01 / D-08).");
            }

            var componentes = db.Componentes.Where(c => c.MezclaId == id).ToList();
            if (componentes.Any())
            {
                db.Componentes.RemoveRange(componentes);
            }

            db.Mezclas.Remove(mezcla);
            db.SaveChanges();

            TempData["Mensaje"] = "Mezcla eliminada correctamente.";
            return RedirectToAction("Index");
        }

        // GET or POST: Mezclas/Duplicar/5 (Fase 3: Clonación de fórmula propia)
        [Authorize(Roles = "Registrado,Administrador")]
        public ActionResult Duplicar(int id)
        {
            var original = db.Mezclas.Include(m => m.Componentes).FirstOrDefault(m => m.Id == id);
            if (original == null)
            {
                return HttpNotFound();
            }

            if (string.IsNullOrEmpty(original.OwnerUserId) || original.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Solo puede duplicar sus propias fórmulas guardadas.");
            }

            var copia = new Mezcla
            {
                Nombre = original.Nombre + " (Copia)",
                ResistenciaMPa = original.ResistenciaMPa,
                EdadDias = original.EdadDias,
                RelacionAguaCemento = original.RelacionAguaCemento,
                AsentamientoCm = original.AsentamientoCm,
                Notas = original.Notas,
                OwnerUserId = CurrentUserId
            };

            db.Mezclas.Add(copia);
            db.SaveChanges();

            if (original.Componentes != null && original.Componentes.Any())
            {
                foreach (var comp in original.Componentes)
                {
                    db.Componentes.Add(new MezclaComponente
                    {
                        MezclaId = copia.Id,
                        MaterialId = comp.MaterialId,
                        Cantidad = comp.Cantidad
                    });
                }
                db.SaveChanges();
            }

            TempData["Mensaje"] = "Mezcla duplicada exitosamente.";
            return RedirectToAction("Index");
        }

        // POST: Mezclas/AgregarComponente
        [HttpPost]
        [Authorize(Roles = "Registrado,Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult AgregarComponente(int mezclaId, [Bind(Include = "MaterialId,Cantidad")] MezclaComponente componente)
        {
            var mezcla = db.Mezclas.Find(mezclaId);
            if (mezcla == null)
            {
                return HttpNotFound();
            }

            if (string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Modificación de componentes bloqueada en mezclas ajenas o sin propietario (D-01 / D-08).");
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

        // POST: Mezclas/EliminarComponente
        [HttpPost]
        [Authorize(Roles = "Registrado,Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult EliminarComponente(int id)
        {
            var componente = db.Componentes.Find(id);
            if (componente == null)
            {
                return HttpNotFound();
            }

            var mezcla = db.Mezclas.Find(componente.MezclaId);
            if (mezcla == null || string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Modificación de componentes bloqueada en mezclas ajenas o sin propietario (D-01 / D-08).");
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
                // Safe Denial: Precarga permitida exclusivamente para mezclas de la propia cuenta
                if (mezcla == null || string.IsNullOrEmpty(mezcla.OwnerUserId) || mezcla.OwnerUserId != CurrentUserId)
                {
                    ViewBag.SafeDenialWarning = "Privacidad de mezclas (D-01 / D-08): La precarga de fórmulas solo está permitida para mezclas de su propiedad.";
                    mezclaId = null;
                }
                else
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

                return Json(new
                {
                    success = false,
                    error = "Datos de dosificación inválidos.",
                    validationErrors = errors
                });
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
                Response.StatusCode = (int)ex.StatusCode;
                return Content(JsonConvert.SerializeObject(new
                {
                    success = false,
                    latencyMs = sw.ElapsedMilliseconds,
                    error = ex.Message,
                    problemDetails = ex.ProblemDetails
                }), "application/json");
            }
            catch (Exception ex)
            {
                sw.Stop();
                Response.StatusCode = 500;
                return Content(JsonConvert.SerializeObject(new
                {
                    success = false,
                    latencyMs = sw.ElapsedMilliseconds,
                    error = "Error interno al comunicarse con el microservicio de inferencia: " + ex.Message
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
