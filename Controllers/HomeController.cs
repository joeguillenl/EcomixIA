using System.Linq;
using System.Web.Mvc;
using EcomixIA.Models;

namespace EcomixIA.Controllers
{
    public class HomeController : Controller
    {
        private readonly EcomixContext db = new EcomixContext();

        public ActionResult Index()
        {
            ViewBag.TotalMateriales = db.Materiales.Count();
            ViewBag.TotalMezclas = db.Mezclas.Count();
            return View();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
