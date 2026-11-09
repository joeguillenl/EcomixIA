# EcoMix IA — Plan Técnico y Arquitectural de la Fase 2: Autenticación, Autorización y RBAC

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Optimización de Mezclas de Concreto Ecológico  
**Repositorio:** `https://github.com/joeguillenl/EcomixIA`  
**Directorio local:** `C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema`  
**Rama activa:** `feat/ecomix-fase-02-identidad-rbac`  
**Commit base:** `378a9e8b355ad4ecf1a9a8344e99f6b9c9f45672` (`378a9e8`, merge de PR #1 sobre `master`)  
**Fecha de elaboración:** 09 de noviembre de 2026 (America/Lima)  
**Versión del documento:** 1.0  
**Trazabilidad:** SRS v1.2 (D-01, D-02, D-03, D-08, D-10) | SAD v1.1  

---

## 1. Resumen Ejecutivo y Objetivos de la Fase 2

La **Fase 2 — Autenticación, Autorización y Control de Acceso Basado en Roles (RBAC)** tiene como objetivo dotar al sistema EcoMix IA de un marco de seguridad perimetral y granular robusto basado en **ASP.NET Identity 2** y el pipeline **OWIN**, permitiendo la identificación unívoca de usuarios, la protección server-side de recursos y la diferenciación estricta de privilegios.

### Objetivos Clave:
1. **Control perimetral de acceso:** Proteger todas las rutas y operaciones no públicas, exigiendo autenticación obligatoria y redirigiendo a visitantes anónimos al formulario de ingreso.
2. **Registro restringido por dominios autorizados:** Admitir exclusivamente cuentas pertenecientes a la Universidad Privada de Tacna (`@upt.pe`, `@virtual.upt.pe`) y cuentas `@gmail.com` de investigación/docencia, rechazando de forma categórica cualquier otro dominio o intento de spoofing.
3. **Verificación de correo electrónico:** Exigir confirmación obligatoria de posesión de la cuenta de correo mediante tokens temporales de un solo uso antes de autorizar el acceso a los servicios del sistema.
4. **Esquema de roles (RBAC):** Implementar dos roles fundamentales: `Registrado` (usuarios estándar) y `Administrador` (gestión del catálogo y de cuentas).
5. **Privacidad de mezclas y no intrusión administrativa (D-01 / D-08):** Garantizar que las mezclas sean privadas por propietario y que el Administrador **no tenga acceso de lectura, edición ni borrado sobre las mezclas privadas de otros usuarios**.
6. **Gobierno del catálogo de materiales (D-02):** Mantener el catálogo `Materials` como un recurso global único: consulta para todos los usuarios registrados y mantenimiento (CRUD) restringido exclusivamente al rol `Administrador`.
7. **Provisión segura del primer administrador (D-10):** Provisión explícita y manual, sin credenciales incrustadas en código ni endpoints web de elevación de privilegios.

---

## 2. Matriz de Requerimientos y Decisiones de Arquitectura

| Requerimiento / Decisión | Descripción Técnica | Criterio de Aceptación |
| :--- | :--- | :--- |
| **RF-03** | Barra de navegación y pie de página adaptativos | Visitante anónimo visualiza botón "Ingresar" / "Registrarse"; usuario autenticado visualiza nombre, rol y botón "Cerrar sesión". |
| **RF-04** | Registro por correo y contraseña | Solamente se aceptan correos cuyos dominios canónicos sean exactamente: `upt.pe`, `virtual.upt.pe` o `gmail.com`. |
| **RF-05** | Rechazo de dominios no autorizados | Denegación automática ante subdominios no autorizados (e.g., `@alumnos.upt.pe`), dominios alterados (e.g., `@upt.pe.attacker.com`) o genéricos ajenos (e.g., `@hotmail.com`, `@yahoo.com`). |
| **RF-06** | Confirmación obligatoria de correo | Cuenta recién creada tiene `EmailConfirmed = false`. Se genera un token criptográfico temporal con expiración. El acceso a servicios protegidos se bloquea hasta su confirmación. |
| **RF-07** | Manejo seguro de sesiones | Cookies de autenticación OWIN con banderas `HttpOnly`, `SameSite = Lax`, protección antiforgery (`[ValidateAntiForgeryToken]`) y expiración por inactividad. |
| **RF-08** | Restablecimiento de contraseña | Enlace temporal de un solo uso enviado por correo. La respuesta HTTP no revela si la cuenta existe (defensa contra enumeración de usuarios). |
| **RF-09** | Protección de rutas en servidor | Filtros `[Authorize]` y `[Authorize(Roles = "...")]` aplicados en controladores y acciones, no dependiendo del ocultamiento de elementos en la interfaz. |
| **RF-10** | Asignación única del rol `Registrado` | El endpoint público de registro asigna de forma unívoca el rol `Registrado`. Imposibilidad de elevación de privilegios mediante manipulación del payload POST. |
| **RF-12 (D-02)** | Catálogo global de materiales | Todos los usuarios autenticados consultan el catálogo (`Index`, `Details`). Únicamente el rol `Administrador` accede a `Create`, `Edit` y `Delete`. Visitantes anónimos no consultan el catálogo. |
| **D-01 / D-08** | Privacidad absoluta de mezclas | Cada mezcla pertenece exclusivamente a su creador. El rol `Administrador` no tiene privilegios para consultar, listar, editar o borrar mezclas privadas ajenas. |
| **D-03 (Prov.)** | Correo transaccional desacoplado | Interfaz `IEmailService` desacoplada. Emisor simulado local para desarrollo que no envía tráfico real a la red ni genera costos. |
| **D-10** | Provisión del Administrador inicial | Procedimiento manual y explícito por CLI/script fuera del flujo web. Sin contraseñas hardcoded ni auto-creación al iniciar la aplicación. |

---

## 3. Diagnóstico del Estado Actual y Arquitectura de Persistencia EF6

### 3.1 Inventario de Paquetes y Configuración Existente
* **Paquetes NuGet instalados:** `EntityFramework 6.5.1`, `Microsoft.AspNet.Mvc 5.2.9`, `Newtonsoft.Json 13.0.3`.
* **Estado de Identity/OWIN:** **Ausentes al 100%.** No existen referencias a `Microsoft.AspNet.Identity.Core`, `Microsoft.AspNet.Identity.EntityFramework`, `Microsoft.AspNet.Identity.Owin` ni `Microsoft.Owin.Host.SystemWeb`.
* **Canalización OWIN:** No existe archivo `Startup.cs` ni clase de configuración de autenticación.
* **Global.asax.cs:** No registra filtros globales (`FilterConfig` ausente); solo inicializa rutas y áreas.

### 3.2 Estado de la Base de Datos LocalDB (`EcomixIA`)
* `dbo.Materials`: 10 registros.
* `dbo.Mezclas`: 8 registros.
* `dbo.MezclaComponentes`: 32 registros.
* `dbo.__MigrationHistory`: 1 registro con `MigrationId = "202611082237174_InitialCreate"` y `ContextKey = "EcomixIA.Models.EcomixContext"`.
* **Directorio `Migrations/` en el proyecto:** **Inexistente.** No existe historial de código de migraciones en el repositorio Git.

### 3.3 Evaluación de Alternativas de Persistencia para Identity 2

#### Opción A: Contexto Integrado (`EcomixContext : IdentityDbContext<ApplicationUser>`)
* **Descripción:** Convertir el contexto existente de negocio en un contexto derivado de `IdentityDbContext`, integrando las entidades de negocio (`Materials`, `Mezclas`, `MezclaComponentes`) y las tablas de seguridad (`AspNetUsers`, `AspNetRoles`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`) bajo el mismo `DbContext`.
* **Ventajas:** Un solo contexto para inyectar y utilizar; atomicidad en transacciones simples.
* **Desventajas y Riesgos Críticos:**
  1. *Conflicto con `__MigrationHistory`:* Al modificar `EcomixContext`, EF6 detectará un cambio en el hash del modelo. Al no existir el código de `202611082237174_InitialCreate.cs`, generar migraciones forzará a EF a intentar recrear las tablas existentes o causará `ModelCompatibilityException`.
  2. *Violación de Separación de Responsabilidades:* Acopla el ciclo de vida del catálogo y las dosificaciones de concreto con la infraestructura de seguridad.
  3. *Riesgo de Regresión en Pruebas de Humo:* Podría alterar las consultas operativas existentes (SM-01 a SM-08).

#### Opción B: Contextos Independientes (`ApplicationDbContext : IdentityDbContext<ApplicationUser>`) — **RECOMENDADA**
* **Descripción:** Crear un contexto dedicado exclusivamente a la seguridad (`ApplicationDbContext`), residiendo en la misma base de datos (`DefaultConnection`), pero con su propio `ContextKey = "EcomixIA.Models.ApplicationDbContext"` en `dbo.__MigrationHistory`.
* **Ventajas:**
  1. *Compatibilidad total e inocuidad:* `EcomixContext` permanece **completamente intacto**, garantizando que las consultas de negocio no sufran alteraciones de compatibilidad ni requieran migraciones forzadas.
  2. *Migraciones aisladas:* Las migraciones de Identity se configuran en un directorio independiente (`Migrations\Identity`), aplicando exclusivamente la creación de las tablas de seguridad de ASP.NET Identity (`AspNet*`).
  3. *Alineación con el estándar Microsoft:* Es el patrón oficial y ampliamente probado en soluciones desacopladas de ASP.NET MVC 5.
  4. *Reversibilidad sencilla:* Permite revertir o rehacer el esquema de seguridad sin comprometer los datos de materiales o mezclas.

**Decisión Técnica F2.0:** Se aprueba formalmente la **Opción B (Contextos Independientes)** para salvaguardar la integridad de la base de datos y evitar colisiones de migración en EF6.

### 3.4 Regla Obligatoria de Safety Gate para Migraciones de Base de Datos
Para garantizar la integridad y cero pérdida de datos en el sistema EcoMix IA, se establece la siguiente regla arquitectural de cumplimiento obligatorio:

> **Regla de Safety Gate:** Ninguna migración de Entity Framework se aplica de forma directa sobre la base de datos de desarrollo principal (`EcomixIA`) o de producción sin haber sido previamente:
> 1. Respaldada mediante copia de seguridad controlada (`COPY_ONLY` con `CHECKSUM`).
> 2. Restaurada y ejecutada sobre una base de datos secundaria de pruebas clonada e independiente (`_Test`).
> 3. Verificada en su esquema físico resultante, integridad referencial y preservación estricta de las tablas preexistentes (`Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32`).
> 4. Validada en su procedimiento de reversibilidad (`Down` / Rollback) comprobando el retorno al estado previo sin efectos colaterales.

---

## 4. Matriz de Autorización y Control de Acceso (RBAC)

La siguiente matriz define el comportamiento server-side exacto para cada ruta y rol:

| Ruta / Controlador / Acción | Visitante Anónimo | Rol: `Registrado` | Rol: `Administrador` | Mecanismo de Control |
| :--- | :---: | :---: | :---: | :--- |
| `GET /` (Portada Home) | Permitido | Permitido | Permitido | `[AllowAnonymous]` |
| `GET /Content/*` (Estilos, Imágenes) | Permitido | Permitido | Permitido | Servidor web estático |
| `GET /Account/Login`, `Register` | Permitido | Redirige a Home | Redirige a Home | `[AllowAnonymous]` |
| `POST /Account/Login`, `Register` | Permitido | — | — | `[AllowAnonymous]`, `[ValidateAntiForgeryToken]` |
| `POST /Account/LogOff` | Denegado (302) | Permitido | Permitido | `[Authorize]`, `[ValidateAntiForgeryToken]` |
| `GET /Materiales/Index`, `Details` | **Denegado (Redirige Login)** | **Permitido** | **Permitido** | `[Authorize]` |
| `GET/POST /Materiales/Create`, `Edit`, `Delete` | **Denegado (302)** | **Denegado (403 Forbidden)** | **Permitido** | `[Authorize(Roles = "Administrador")]` |
| `GET /Mezclas/Index` | **Denegado (302)** | **Solo Propias** (Ver 5.1) | **Solo Propias** (D-08) | `[Authorize]`, filtrado en servidor |
| `GET /Mezclas/Details`, `Edit`, `Delete` | **Denegado (302)** | **Solo Propias** | **Solo Propias** (D-08) | `[Authorize]`, control IDOR |
| `POST /Mezclas/AgregarComponente`, `Eliminar` | **Denegado (302)** | **Solo Propias** | **Solo Propias** (D-08) | `[Authorize]`, control IDOR |
| `GET/POST /Mezclas/Simulador` | **Denegado (302)** | **Permitido** | **Permitido** | `[Authorize]` |
| `POST /Mezclas/SimularAjax` | **Denegado (401)** | **Permitido** | **Permitido** | `[Authorize]` |
| `GET/POST /Admin/Usuarios/*` | **Denegado (302)** | **Denegado (403 Forbidden)** | **Permitido** | `[Authorize(Roles = "Administrador")]` |

---

## 5. Estrategia de Mitigación de Riesgos de Transición (Datos Existentes F2/F3)

### 5.1 El Riesgo Crítico de Propiedad en Fase 2
En el esquema actual de SQL Server LocalDB, la tabla `dbo.Mezclas` **no cuenta con una columna `OwnerUserId`**. Esta columna será introducida formalmente en la **Fase 3**.

Si en Fase 2 simplemente aplicamos `[Authorize]` sobre `MezclasController`, se generaría un riesgo crítico de seguridad: cualquier usuario autenticado podría listar las 8 mezclas existentes en la base de datos, inspeccionar sus fórmulas o modificarlas, violando flagrantemente la decisión **D-01** (Privacidad de mezclas) y **D-08** (No intromisión).

### 5.2 Estrategia Transitoria de Denegación Segura (Safe Denial)
Durante la Fase 2, se aplicarán las siguientes salvaguardas transitorias de código en `MezclasController`:
1. **Listado maestro (`Index`):** Dado que en Fase 2 ninguna mezcla cuenta con propietario autenticado verificado, el listado devolverá una colección vacía (`Enumerable.Empty<Mezcla>()`), acompañada de un estado informativo en la vista: *"No cuenta con mezclas registradas a su nombre"*.
2. **Acceso directo por ID (`Details`, `Edit`, `Delete`):** Cualquier solicitud que apunte a las Mezclas 1 a 8 devolverá de forma segura un código **HTTP 404 Not Found** o **HTTP 403 Forbidden**, bloqueando la manipulación de fórmulas no asociadas al usuario actual.
3. **Simulador con precarga (`Simulador?mezclaId=1`):** La precarga de mezclas preexistentes quedará temporalmente bloqueada en Fase 2 para cuentas regulares, requiriendo que la dosificación se ingrese manualmente en los campos del formulario o se utilicen los botones de preset preconfigurados en la vista.
4. **Preservación en base de datos:** Las 8 mezclas preexistentes (6 semillas con 32 componentes y 2 de prueba locales) permanecerán **completamente intactas en SQL Server**, a la espera de que en Fase 3 se ejecute la migración formal que añada `OwnerUserId` y se decida su asignación o conversión a plantillas institucionales de referencia.

---

## 6. Servicio de Correo Transaccional (`IEmailService` - D-03)

### 6.1 Diseño Desacoplado
En estricto cumplimiento de **D-03 (provisional)**, el subsistema de correo se estructurará mediante una interfaz desacoplada:

```csharp
namespace EcomixIA.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string bodyHtml);
    }
}
```

### 6.2 Implementación de Desarrollo: Emisor Simulado Local
Para garantizar cero costos en la nube (D-06) y permitir pruebas completas en el entorno local:
* **Clase:** `SimulatedEmailService : IEmailService`
* **Comportamiento:** Escribe los correos generados (enlace de confirmación, token y cuerpo HTML) en archivos de texto estructurados dentro de un directorio local no versionado (`App_Data/EmailOutbox/`) y emite una traza en `System.Diagnostics.Trace`.
* **Salvaguarda estricta:** Este modo simulado no salta la validación: el usuario de prueba debe obligatoriamente copiar el enlace con el token generado y navegar a él para activar su cuenta (`EmailConfirmed = true`).
* **Protección para producción:** La configuración de inversión de control (o fábrica) exigirá que en configuración `Release` se requiera un proveedor real verificado (e.g., SendGrid, Brevo o Azure Communication Services).

### 6.3 Validación de Dominios (Destinatario vs. Remitente)
* **Validación de Destinatario (Aplicación):** Se implementará un validador regex canónico que verifique que el correo pertenezca estrictamente a:
  - `^[a-zA-Z0-9._%+-]+@upt\.pe$`
  - `^[a-zA-Z0-9._%+-]+@virtual\.upt\.pe$`
  - `^[a-zA-Z0-9._%+-]+@gmail\.com$`
* **Validación de Remitente (Infraestructura):** El correo remitente (e.g., `notificaciones@ecomixia.upt.pe`) se gestionará a nivel de DNS en Fase 4/5 con registros SPF, DKIM y DMARC al seleccionar el proveedor comercial.

---

## 7. Provisión Segura del Administrador Inicial (D-10)

En cumplimiento de la decisión **D-10**, el alta de la primera cuenta con rol `Administrador` seguirá un protocolo estricto:
1. **Sin credenciales en código:** Ningún archivo del repositorio contendrá contraseñas o tokens preconfigurados.
2. **Sin endpoint web público:** No existirá ninguna URL o parámetro que permita registrarse como administrador o elevar una cuenta existente.
3. **Sin auto-promoción por dominio:** El hecho de poseer un correo `@upt.pe` o `@virtual.upt.pe` otorga únicamente el rol `Registrado`.
4. **Procedimiento manual fuera de banda:** Se implementará una herramienta de consola administrativa (`tools/EcoMixAdminProvisioner` o script de gestión segura en PowerShell invocando `UserManager`) que:
   - Recibirá interactivamente el correo autorizado (e.g., cuenta institucional docente) y la contraseña temporal segura.
   - Creará el usuario mediante la API de ASP.NET Identity con `EmailConfirmed = true`.
   - Asignará explícitamente el rol `Administrador`.
5. **Aislamiento administrativo (D-08):** El rol `Administrador` solo habilita el acceso a la gestión de materiales y al panel de cuentas; no permite leer ni interactuar con las mezclas privadas de otros usuarios.

---

## 8. Plan de Implementación Incremental de la Fase 2

La Fase 2 se ejecutará en cinco subetapas secuenciales y verificables:

```
[F2.0] Diagnóstico y Planificación (Actual)
   │
   ▼
[F2.1] Infraestructura Identity 2, OWIN y Migración EF6
   │   - Paquetes NuGet, ApplicationDbContext, ApplicationUser, IdentityRole
   │   - Migración EF6 inicial para tablas AspNet* en LocalDB
   │   - Pipeline OWIN Startup.Auth.cs
   │
   ▼
[F2.2] Registro de Usuarios, Validación de Dominios y Correo (D-03)
   │   - AccountController.Register (GET/POST)
   │   - Filtro de validación estricta de dominios (@upt.pe, @virtual.upt.pe, @gmail.com)
   │   - IEmailService y SimulatedEmailService con tokens de confirmación
   │   - AccountController.ConfirmEmail
   │
   ▼
[F2.3] Autenticación, Sesiones Seguras y Recuperación de Contraseña
   │   - AccountController.Login / LogOff con cookies OWIN protegidas
   │   - Bloqueo por intentos fallidos (Lockout) y protección contra enumeración
   │   - AccountController.ForgotPassword y ResetPassword
   │   - Integración visual en _Layout.cshtml (botones Ingresar / Salir)
   │
   ▼
[F2.4] Control de Roles (RBAC), Provisión de Administrador (D-10) y Protección de Recursos (D-02)
   │   - Roles: "Administrador" y "Registrado"
   │   - Herramienta de provisión manual del primer administrador (D-10)
   │   - Protección de MaterialesController (Lectura para Registrado, CRUD para Administrador - D-02)
   │   - Aplicación de política Safe Denial en MezclasController
   │
   ▼
[F2.5] Auditoría de Seguridad, Pruebas de Regresión y Cierre de Fase 2
       - Pruebas de inyección de roles, IDOR, bypass de confirmación y fuerza bruta
       - Pruebas de humo SM-01 a SM-08
       - Verificación de SQL Server LocalDB y presupuesto Azure (D-06)
       - Cierre documental y commit local de Fase 2
```

---

## 9. Criterios de Aceptación y Puerta de Calidad para la Fase 2

1. **Compilación:** Cero errores de compilación en configuración `Debug | Any CPU`.
2. **Seguridad perimetral:** El 100% de las rutas operativas (`/Materiales`, `/Mezclas`, `/Mezclas/Simulador`) redirigen a login al ser consultadas por visitantes anónimos.
3. **Validación de dominios:** Se rechazan de forma comprobada correos con dominios ajenos, subdominios o extensiones alteradas.
4. **Activación de cuentas:** Las cuentas no confirmadas no pueden iniciar sesión ni utilizar servicios.
5. **Matriz RBAC comprobada:** Usuarios con rol `Registrado` reciben HTTP 403 Forbidden al intentar acceder a acciones `Create`, `Edit` o `Delete` de `MaterialesController`.
6. **No intromisión:** Cuentas con rol `Administrador` no pueden visualizar ni manipular mezclas de otras cuentas.
7. **No regresión:** Las 8 pruebas de humo (SM-01 a SM-08) se mantienen operativas para sesiones autorizadas.
8. **Integridad de datos:** Las tablas de negocio (`Materials`, `Mezclas`, `MezclaComponentes`) conservan su conteo exacto de registros (10, 8, 32).
9. **FinOps Azure (D-06):** Consumo atribuible a la sesión en US$ 0.00.
