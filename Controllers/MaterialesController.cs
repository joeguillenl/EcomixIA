using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;
using EcomixIA.Models;

namespace EcomixIA.Controllers
{
    public class MaterialesController : Controller
    {
        private readonly EcomixContext db = new EcomixContext();

        public ActionResult Index()
        {
            var materiales = db.Materiales.OrderBy(m => m.Tipo).ThenBy(m => m.Nombre).ToList();
            return View(materiales);
        }

        public ActionResult Details(int? id)
        {
            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            return View(material);
        }

        public ActionResult Create()
        {
            CargarTipos();
            return View(new Material());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "Nombre,Tipo,DensidadRelativa,CostoPorKg,Co2PorKg,Notas")] Material material)
        {
            if (!ModelState.IsValid)
            {
                CargarTipos(material.Tipo);
                return View(material);
            }

            db.Materiales.Add(material);
            db.SaveChanges();
            TempData["Mensaje"] = "Material creado correctamente.";
            return RedirectToAction("Index");
        }

        public ActionResult Edit(int? id)
        {
            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            CargarTipos(material.Tipo);
            return View(material);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "Id,Nombre,Tipo,DensidadRelativa,CostoPorKg,Co2PorKg,Notas")] Material material)
        {
            if (!ModelState.IsValid)
            {
                CargarTipos(material.Tipo);
                return View(material);
            }

            db.Entry(material).State = EntityState.Modified;
            db.SaveChanges();
            TempData["Mensaje"] = "Material actualizado correctamente.";
            return RedirectToAction("Index");
        }

        public ActionResult Delete(int? id)
        {
            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            ViewBag.EnUso = db.Componentes.Any(c => c.MaterialId == material.Id);
            return View(material);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            var material = db.Materiales.Find(id);
            if (material == null)
            {
                return HttpNotFound();
            }

            if (db.Componentes.Any(c => c.MaterialId == id))
            {
                TempData["Error"] = "No se puede eliminar: el material forma parte de una o más mezclas.";
                return RedirectToAction("Index");
            }

            db.Materiales.Remove(material);
            db.SaveChanges();
            TempData["Mensaje"] = "Material eliminado correctamente.";
            return RedirectToAction("Index");
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }

        private Material BuscarMaterial(int? id)
        {
            return id == null ? null : db.Materiales.Find(id.Value);
        }

        private void CargarTipos(string seleccionado = null)
        {
            ViewBag.Tipos = new SelectList(TiposMaterial.Todos, seleccionado);
        }
    }
}
