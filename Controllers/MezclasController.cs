using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;
using EcomixIA.Models;

namespace EcomixIA.Controllers
{
    public class MezclasController : Controller
    {
        private readonly EcomixContext db = new EcomixContext();

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

            // Remueve la validación de la navegación; solo importan MaterialId y Cantidad.
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
    }
}
