using System;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using Microsoft.AspNet.Identity.Owin;
using Microsoft.Owin.Security;
using EcomixIA.Models;
using EcomixIA.Services;

namespace EcomixIA.Controllers
{
    [Authorize]
    public class AccountController : Controller
    {
        private ApplicationUserManager _userManager;
        private ApplicationSignInManager _signInManager;
        private ApplicationRoleManager _roleManager;
        private ApplicationDbContext _dbContext;
        private readonly IEmailDomainValidator _domainValidator;
        private readonly IRegistrationSafetyGate _safetyGate;

        public AccountController()
            : this(null, null, null, null, new EmailDomainValidator(), new RegistrationSafetyGate())
        {
        }

        public AccountController(
            ApplicationUserManager userManager,
            ApplicationSignInManager signInManager,
            ApplicationRoleManager roleManager,
            ApplicationDbContext dbContext,
            IEmailDomainValidator domainValidator,
            IRegistrationSafetyGate safetyGate)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _roleManager = roleManager;
            _dbContext = dbContext;
            _domainValidator = domainValidator ?? new EmailDomainValidator();
            _safetyGate = safetyGate ?? new RegistrationSafetyGate();
        }

        public ApplicationUserManager UserManager
        {
            get => _userManager ?? HttpContext?.GetOwinContext()?.GetUserManager<ApplicationUserManager>();
            private set => _userManager = value;
        }

        public ApplicationSignInManager SignInManager
        {
            get => _signInManager ?? HttpContext?.GetOwinContext()?.Get<ApplicationSignInManager>();
            private set => _signInManager = value;
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

        private IAuthenticationManager _authManager;
        public IAuthenticationManager AuthenticationManager
        {
            get => _authManager ?? HttpContext?.GetOwinContext()?.Authentication;
            set => _authManager = value;
        }

        //
        // GET: /Account/Login
        [AllowAnonymous]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        //
        // POST: /Account/Login
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Login(LoginViewModel model, string returnUrl)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            string normalizedEmail = _domainValidator.NormalizeEmail(model.Email);

            // 1. Buscar cuenta por correo
            var user = await UserManager.FindByEmailAsync(normalizedEmail);
            if (user == null)
            {
                ModelState.AddModelError(string.Empty, "Credenciales incorrectas o usuario no encontrado.");
                return View(model);
            }

            // 2. Comprobación obligatoria de correo confirmado (RF-06)
            if (!user.EmailConfirmed)
            {
                ModelState.AddModelError(string.Empty, "Debe confirmar su correo electrónico antes de ingresar. Por favor revise el mensaje de activación en su bandeja.");
                return View(model);
            }

            // 3. Inicio de sesión mediante SignInManager con control de bloqueo (Lockout)
            var result = await SignInManager.PasswordSignInAsync(user.UserName, model.Password, model.RememberMe, shouldLockout: true);
            switch (result)
            {
                case SignInStatus.Success:
                    return RedirectToLocal(returnUrl);
                case SignInStatus.LockedOut:
                    return View("Lockout");
                case SignInStatus.Failure:
                default:
                    ModelState.AddModelError(string.Empty, "Credenciales incorrectas.");
                    return View(model);
            }
        }

        //
        // POST: /Account/LogOff
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult LogOff()
        {
            AuthenticationManager?.SignOut(DefaultAuthenticationTypes.ApplicationCookie);
            return RedirectToAction("Index", "Home");
        }

        private ActionResult RedirectToLocal(string returnUrl)
        {
            if (Url != null && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            return RedirectToAction("Index", "Home");
        }

        //
        // GET: /Account/Register
        [AllowAnonymous]
        public ActionResult Register()
        {
            // Verificación obligatoria de Safety Gate (Etapa 2)
            if (!_safetyGate.IsRegistrationAllowed(DbContext, out string denialReason))
            {
                ViewBag.DenialReason = denialReason;
                return View("RegistrationDisabled");
            }

            return View(new RegisterViewModel());
        }

        //
        // POST: /Account/Register
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Register(RegisterViewModel model)
        {
            // 1. Verificación Safety Gate del entorno y base de datos de destino
            if (!_safetyGate.IsRegistrationAllowed(DbContext, out string denialReason))
            {
                ViewBag.DenialReason = denialReason;
                return View("RegistrationDisabled");
            }

            // 2. Validación estricta de dominios de correo (RF-04, RF-05)
            if (string.IsNullOrWhiteSpace(model.Email) || !_domainValidator.IsDomainAllowed(model.Email))
            {
                ModelState.AddModelError("Email", "El dominio de correo no está autorizado. Solamente se admiten cuentas institucionales de la Universidad Privada de Tacna (@upt.pe, @virtual.upt.pe) o cuentas de investigación (@gmail.com).");
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            string normalizedEmail = _domainValidator.NormalizeEmail(model.Email);

            // 3. Prevención de correos duplicados
            var existingUser = await UserManager.FindByEmailAsync(normalizedEmail);
            if (existingUser != null)
            {
                ModelState.AddModelError("Email", "Ya existe una cuenta registrada con este correo electrónico.");
                return View(model);
            }

            // 4. Creación segura de usuario: EmailConfirmed siempre inicia en false (RF-06)
            var user = new ApplicationUser
            {
                UserName = normalizedEmail,
                Email = normalizedEmail,
                EmailConfirmed = false,
                LockoutEnabled = true
            };

            var createResult = await UserManager.CreateAsync(user, model.Password);
            if (!createResult.Succeeded)
            {
                AddErrors(createResult);
                return View(model);
            }

            // 5. Asignación exclusiva del rol 'Registrado' (RF-10)
            const string defaultRole = "Registrado";
            try
            {
                if (RoleManager != null && !await RoleManager.RoleExistsAsync(defaultRole))
                {
                    var roleResult = await RoleManager.CreateAsync(new IdentityRole(defaultRole));
                    if (!roleResult.Succeeded)
                    {
                        // Rollback seguro de estado parcial si falla la creación del rol
                        await UserManager.DeleteAsync(user);
                        ModelState.AddModelError(string.Empty, "Error de infraestructura al inicializar el rol de usuario. El registro fue cancelado por seguridad.");
                        return View(model);
                    }
                }

                var addRoleResult = await UserManager.AddToRoleAsync(user.Id, defaultRole);
                if (!addRoleResult.Succeeded)
                {
                    // Rollback seguro si falla la asignación de rol
                    await UserManager.DeleteAsync(user);
                    ModelState.AddModelError(string.Empty, "Error al asignar privilegios de usuario registrado. El registro fue cancelado por seguridad.");
                    return View(model);
                }
            }
            catch (Exception ex)
            {
                Trace.WriteLine($"[AccountController] Error al gestionar rol '{defaultRole}': {ex.Message}");
                await UserManager.DeleteAsync(user);
                ModelState.AddModelError(string.Empty, "Error interno al asignar rol de seguridad. El registro fue cancelado.");
                return View(model);
            }

            // 6. Generación de token criptográfico de confirmación de correo
            string code = await UserManager.GenerateEmailConfirmationTokenAsync(user.Id);
            string callbackUrl = Url != null
                ? Url.Action("ConfirmEmail", "Account", new { userId = user.Id, code = code }, protocol: Request?.Url?.Scheme ?? "https")
                : $"/Account/ConfirmEmail?userId={Uri.EscapeDataString(user.Id)}&code={Uri.EscapeDataString(code)}";

            // 7. Envío de correo mediante el servicio transaccional desacoplado (D-03)
            try
            {
                await UserManager.SendEmailAsync(
                    user.Id,
                    "EcoMix IA — Confirme su cuenta de correo",
                    $"<p>Bienvenido a EcoMix IA.</p>" +
                    $"<p>Para activar su cuenta y verificar su correo institucional o de investigación, haga clic en el siguiente enlace:</p>" +
                    $"<p><a href=\"{callbackUrl}\">Confirmar mi cuenta</a></p>" +
                    $"<p>Este enlace es válido por 24 horas.</p>");
            }
            catch (Exception ex)
            {
                Trace.WriteLine($"[AccountController] Excepción en servicio de correo: {ex.Message}");
                // El fallo del emisor no activa la cuenta ni detiene el flujo con excepción no controlada
                ViewBag.EmailWarning = "Se creó la cuenta, pero ocurrió un retraso en el emisor de correo. Podrá solicitar un reenvío más adelante.";
            }

            ViewBag.RegisteredEmail = normalizedEmail;
            return View("RegisterConfirmation");
        }

        //
        // GET: /Account/ConfirmEmail
        [AllowAnonymous]
        public async Task<ActionResult> ConfirmEmail(string userId, string code)
        {
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(code))
            {
                ViewBag.ErrorMessage = "El enlace de confirmación está incompleto o los parámetros son inválidos.";
                return View("ConfirmEmailError");
            }

            var user = await UserManager.FindByIdAsync(userId);
            if (user == null)
            {
                ViewBag.ErrorMessage = "La cuenta asociada a este enlace de confirmación no fue encontrada.";
                return View("ConfirmEmailError");
            }

            // Reutilización segura: Si ya está confirmado, informar sin re-ejecutar acciones privilegiadas
            if (user.EmailConfirmed)
            {
                ViewBag.InfoMessage = "Su correo electrónico ya ha sido confirmado previamente. Su cuenta se encuentra activa.";
                return View("ConfirmEmailSuccess");
            }

            var result = await UserManager.ConfirmEmailAsync(userId, code);
            if (result.Succeeded)
            {
                ViewBag.SuccessMessage = "¡Correo electrónico confirmado exitosamente! Su cuenta de EcoMix IA ha sido activada con el rol Registrado.";
                return View("ConfirmEmailSuccess");
            }

            ViewBag.ErrorMessage = "El token de confirmación es inválido o ha expirado (validez máxima: 24 horas).";
            return View("ConfirmEmailError");
        }

        private void AddErrors(IdentityResult result)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(string.Empty, error);
            }
        }
    }
}
