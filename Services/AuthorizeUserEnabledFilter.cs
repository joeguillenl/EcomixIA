using System;
using System.Web;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;

namespace EcomixIA.Services
{
    /// <summary>
    /// Filtro de autorización global que verifica que las cuentas autenticadas permanezcan habilitadas (IsEnabled).
    /// Si una cuenta es inhabilitada o eliminada por un administrador, su sesión se revoca inmediatamente.
    /// Requerimientos: H05-A3, RF-22, D-10.
    /// </summary>
    public class AuthorizeUserEnabledFilter : IAuthorizationFilter
    {
        private readonly Func<ApplicationUserManager> _userManagerFactory;

        public AuthorizeUserEnabledFilter() : this(null)
        {
        }

        public AuthorizeUserEnabledFilter(Func<ApplicationUserManager> userManagerFactory)
        {
            _userManagerFactory = userManagerFactory;
        }

        public void OnAuthorization(AuthorizationContext filterContext)
        {
            if (filterContext == null) return;

            var httpContext = filterContext.HttpContext;
            var user = httpContext?.User;

            if (user != null && user.Identity != null && user.Identity.IsAuthenticated)
            {
                Microsoft.Owin.IOwinContext owinContext = null;
                try
                {
                    owinContext = httpContext.GetOwinContext();
                }
                catch (InvalidOperationException)
                {
                    // Entorno OWIN no presente en contexto simulado/sintético
                }

                var userManager = _userManagerFactory != null
                    ? _userManagerFactory()
                    : owinContext?.GetUserManager<ApplicationUserManager>();

                string userId = user.Identity.GetUserId();

                if (userManager != null && !string.IsNullOrEmpty(userId))
                {
                    var appUser = userManager.FindById(userId);
                    if (appUser == null || !appUser.IsEnabled)
                    {
                        // Revocación inmediata de cookie de sesión activa
                        try
                        {
                            owinContext?.Authentication?.SignOut(DefaultAuthenticationTypes.ApplicationCookie);
                        }
                        catch (Exception)
                        {
                            // Ignorar si el proveedor de autenticación no está inicializado en la prueba
                        }

                        // Si la acción requiere autenticación (no permite anónimos), redirigir a Login con mensaje de rechazo
                        bool allowAnonymous = filterContext.ActionDescriptor.IsDefined(typeof(AllowAnonymousAttribute), inherit: true)
                                           || filterContext.ActionDescriptor.ControllerDescriptor.IsDefined(typeof(AllowAnonymousAttribute), inherit: true);

                        if (!allowAnonymous)
                        {
                            filterContext.Result = new RedirectResult("/Account/Login?disabled=1");
                        }
                    }
                }
            }
        }
    }
}
