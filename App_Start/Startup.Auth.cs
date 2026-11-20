using System;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.Owin;
using Microsoft.Owin.Security.Cookies;
using Owin;
using EcomixIA.Models;

namespace EcomixIA
{
    public partial class Startup
    {
        public void ConfigureAuth(IAppBuilder app)
        {
            // Configure el contexto de base de datos, el administrador de usuarios y el administrador de inicios de sesión para usar una única instancia por solicitud
            app.CreatePerOwinContext(ApplicationDbContext.Create);
            app.CreatePerOwinContext<ApplicationUserManager>(ApplicationUserManager.Create);
            app.CreatePerOwinContext<ApplicationSignInManager>(ApplicationSignInManager.Create);
            app.CreatePerOwinContext<ApplicationRoleManager>(ApplicationRoleManager.Create);

            // Permitir que la aplicación use una cookie para almacenar información para el usuario que inicia sesión
            app.UseCookieAuthentication(new CookieAuthenticationOptions
            {
                AuthenticationType = DefaultAuthenticationTypes.ApplicationCookie,
                LoginPath = new PathString("/Account/Login"),
                Provider = new CookieAuthenticationProvider
                {
                    OnValidateIdentity = async context =>
                    {
                        // 1. Validador estándar de SecurityStamp (revalida cada 1 minuto)
                        var standardValidator = SecurityStampValidator.OnValidateIdentity<ApplicationUserManager, ApplicationUser>(
                            validateInterval: TimeSpan.FromMinutes(1),
                            regenerateIdentity: (manager, user) => user.GenerateUserIdentityAsync(manager));

                        await standardValidator(context);

                        // 2. Verificación estricta de cuenta habilitada en middleware OWIN (H05-A3)
                        if (context.Identity != null && context.Identity.IsAuthenticated)
                        {
                            var userManager = context.OwinContext.GetUserManager<ApplicationUserManager>();
                            string userId = context.Identity.GetUserId();
                            if (userManager != null && !string.IsNullOrEmpty(userId))
                            {
                                var user = await userManager.FindByIdAsync(userId);
                                if (user == null || !user.IsEnabled)
                                {
                                    context.OwinContext.Set("AccountDisabled", true);
                                    context.RejectIdentity();
                                    context.OwinContext.Authentication.SignOut(DefaultAuthenticationTypes.ApplicationCookie);
                                }
                            }
                        }
                    },
                    OnApplyRedirect = context =>
                    {
                        if (context.OwinContext.Get<bool>("AccountDisabled"))
                        {
                            context.Response.Redirect("/Account/Login?disabled=1");
                        }
                        else
                        {
                            context.Response.Redirect(context.RedirectUri);
                        }
                    }
                },
                CookieHttpOnly = true,
                ExpireTimeSpan = TimeSpan.FromHours(8),
                SlidingExpiration = true
            });            
            app.UseExternalSignInCookie(DefaultAuthenticationTypes.ExternalCookie);

            // Permite que la aplicación almacene temporalmente la información del usuario cuando se comprueba el segundo factor
            app.UseTwoFactorSignInCookie(DefaultAuthenticationTypes.TwoFactorCookie, TimeSpan.FromMinutes(5));

            // Permite que la aplicación recuerde el segundo factor de verificación de inicio de sesión
            app.UseTwoFactorRememberBrowserCookie(DefaultAuthenticationTypes.TwoFactorRememberBrowserCookie);
        }
    }
}
