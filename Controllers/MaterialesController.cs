using System;
using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;
using EcomixIA.Models;

namespace EcomixIA.Controllers
{
    public class MaterialesController : Controller
    {
        private readonly EcomixContext db;

        public MaterialesController() : this(new EcomixContext())
        {
        }

        public MaterialesController(EcomixContext context)
        {
            this.db = context ?? throw new ArgumentNullException(nameof(context));
        }

        [AllowAnonymous]
        public ActionResult Index()
        {
            var materiales = db.Materiales.OrderBy(m => m.Tipo).ThenBy(m => m.Nombre).ToList();
            return View(materiales);
        }

        [AllowAnonymous]
        public ActionResult Details(int? id)
        {
            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            return View(material);
        }

        [Authorize(Roles = "Administrador")]
        public ActionResult Create()
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para crear materiales.");
            }
            CargarTipos();
            return View(new Material());
        }

        [HttpPost]
        [Authorize(Roles = "Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "Nombre,Tipo,DensidadRelativa,CostoPorKg,Co2PorKg,Notas")] Material material)
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para crear materiales.");
            }

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

        [Authorize(Roles = "Administrador")]
        public ActionResult Edit(int? id)
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para editar materiales.");
            }

            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            CargarTipos(material.Tipo);
            return View(material);
        }

        [HttpPost]
        [Authorize(Roles = "Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "Id,Nombre,Tipo,DensidadRelativa,CostoPorKg,Co2PorKg,Notas")] Material material)
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para editar materiales.");
            }

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

        [Authorize(Roles = "Administrador")]
        public ActionResult Delete(int? id)
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para eliminar materiales.");
            }

            var material = BuscarMaterial(id);
            if (material == null)
            {
                return HttpNotFound();
            }
            ViewBag.EnUso = db.Componentes.Any(c => c.MaterialId == material.Id);
            return View(material);
        }

        [HttpPost, ActionName("Delete")]
        [Authorize(Roles = "Administrador")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            if (User == null || !User.IsInRole("Administrador"))
            {
                return new HttpStatusCodeResult(403, "Acceso denegado: Se requiere rol de Administrador para eliminar materiales.");
            }

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
