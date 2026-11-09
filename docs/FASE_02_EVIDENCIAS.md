# EcoMix IA — Evidencias de Ejecución: Fase 2 (Identidad, Autenticación y RBAC)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Optimización de Mezclas de Concreto Ecológico  
**Repositorio:** `https://github.com/joeguillenl/EcomixIA`  
**Directorio local:** `C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema`  
**Rama activa:** `feat/ecomix-fase-02-identidad-rbac`  
**Commit base de Fase 2:** `378a9e8b355ad4ecf1a9a8344e99f6b9c9f45672` (`378a9e8`, merge de PR #1 sobre `master`)  
**Fecha de registro:** 09/11/2026 (America/Lima)  
**Estado general Fase 2:** **F2.0 APROBADA** | **F2.1 APROBADA** | **F2.2 APROBADA** | Subetapas F2.3–F2.5 Planificadas  

---

## 1. Resumen Ejecutivo de la Subetapa F2.0

La subetapa **F2.0 — Diagnóstico de identidad, autorización y migración EF6** tuvo como objetivo realizar la auditoría técnica integral del estado de seguridad y persistencia de la solución tras la integración formal de la Fase 1 en `master`.

### Delimitación estricta del alcance en F2.0:
* **Actividades ejecutadas:**
  1. Creación segura de la rama de trabajo `feat/ecomix-fase-02-identidad-rbac` a partir de `origin/master` (commit `378a9e8`), conservando la configuración local `Web.config` para LocalDB sin conflictos ni descartes.
  2. Auditoría completa de dependencias de seguridad (paquetes NuGet, referencias de proyecto y pipeline OWIN).
  3. Inspección minuciosa de controladores, rutas y vistas para identificar brechas de acceso anónimo a información y operaciones sensibles.
  4. Diagnóstico de solo lectura del esquema de base de datos SQL Server LocalDB y del historial de migraciones EF6 (`dbo.__MigrationHistory`).
  5. Análisis arquitectural comparativo de persistencia entre Contexto Integrado (Opción A) y Contextos Separados (Opción B), seleccionando formalmente la **Opción B (`ApplicationDbContext`)**.
  6. Diseño formal del flujo de autenticación, validación estricta de dominios permitidos (`upt.pe`, `virtual.upt.pe`, `gmail.com`) y confirmación de correo (RF-04 a RF-06).
  7. Formulación de la matriz de autorización server-side (RBAC) y la política transitoria de denegación segura (*Safe Denial*) para mitigar riesgos de privacidad sobre mezclas en la transición F2/F3 (D-01 / D-08).
  8. Diseño del servicio de correo desacoplado `IEmailService` con emisor simulado local para desarrollo (D-03) y del protocolo de provisión segura del primer administrador (D-10).
  9. Elaboración del plan incremental de implementación F2.1 a F2.5 documentado en [docs/FASE_02_PLAN_IDENTIDAD_RBAC.md](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/FASE_02_PLAN_IDENTIDAD_RBAC.md).
* **Restricciones respetadas:**
  - Cero modificaciones a código fuente funcional o controladores.
  - Cero paquetes NuGet instalados.
  - Cero modificaciones o ejecuciones de migración sobre SQL Server LocalDB.
  - Cero llamadas a servicios de inferencia o recursos de Azure (salvaguarda presupuestaria D-06 en US$ 0.00).

---

## 2. Línea Base y Estado de Git

* **Rama de origen:** `origin/master`
* **Commit de integración:** `378a9e8 Merge pull request #1 from joeguillenl/feat/ecomix-fase-01-portal-publico`
* **Rama local creada:** `feat/ecomix-fase-02-identidad-rbac`
* **Comando ejecutado:** `git switch -c feat/ecomix-fase-02-identidad-rbac origin/master`
* **Estado de configuración:** [`Web.config`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Web.config) modificado localmente para apuntar a `(localdb)\MSSQLLocalDB`, conservado de forma no versionada.

---

## 3. Diagnóstico de Paquetes y Dependencias de Seguridad

Se inspeccionó el archivo [packages.config](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/packages.config) y las referencias en [EcomixIA.csproj](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/EcomixIA.csproj):

| Dependencia de Seguridad / OWIN | Estado en la Solución | Requerimiento para Fase 2 |
| :--- | :---: | :--- |
| `Microsoft.AspNet.Identity.Core` | **No instalada** | Requerida en F2.1 (Entidades de usuario, roles, hashing) |
| `Microsoft.AspNet.Identity.EntityFramework` | **No instalada** | Requerida en F2.1 (`IdentityDbContext`, `UserStore`, `RoleStore`) |
| `Microsoft.AspNet.Identity.Owin` | **No instalada** | Requerida en F2.1 (`UserManager`, `SignInManager`, cookies) |
| `Microsoft.Owin` | **No instalada** | Requerida en F2.1 (Pipeline de middleware) |
| `Microsoft.Owin.Host.SystemWeb` | **No instalada** | Requerida en F2.1 (Integración con IIS / ASP.NET clásico) |
| `Microsoft.Owin.Security` | **No instalada** | Requerida en F2.1 (Infraestructura criptográfica de sesión) |
| `Microsoft.Owin.Security.Cookies` | **No instalada** | Requerida en F2.1 (Autenticación por cookie `ApplicationCookie`) |
| Clase `Startup.cs` | **Inexistente** | Requerida en F2.1 para inicializar el pipeline OWIN |

---

## 4. Auditoría de Seguridad del Código Existente

Se evaluaron todos los controladores, rutas y vistas operativas preexistentes:

### 4.1 Brechas de Acceso Anónimo Detectadas
1. **Controlador `MaterialesController`:**
   - Métodos `Index()`, `Details()`, `Create()`, `Edit()`, `Delete()` y `DeleteConfirmed()` no cuentan con atributo `[Authorize]`.
   - **Riesgo:** Cualquier visitante anónimo puede no solo ver el catálogo, sino modificar insumos, costos y factores de emisión por peticiones directas GET/POST.
2. **Controlador `MezclasController`:**
   - Métodos `Index()` y `Details()` permiten a visitantes anónimos listar y consultar el 100% de las fórmulas registradas en la base de datos.
   - Acciones `Create()`, `Edit()`, `Delete()`, `AgregarComponente()` y `EliminarComponente()` carecen de autorización server-side.
   - Puntos de entrada `Simulador()` (GET/POST) y `SimularAjax()` (POST) no exigen autenticación, permitiendo consumo anónimo de inferencia ML.
3. **Controlador `HomeController`:**
   - En la acción `Index()`, se ejecuta `ViewBag.TotalMezclas = db.Mezclas.Count();`, exponiendo en la portada el conteo global de mezclas del sistema.
4. **Plantilla Maestra `Views/Shared/_Layout.cshtml`:**
   - El menú superior muestra enlaces directos a `/Materiales`, `/Mezclas` y `/Mezclas/Simulador` a cualquier visitante sin sesión activa.
   - No existe mecanismo visual para iniciar sesión, registrarse ni cerrar sesión (únicamente se muestra el badge estático `Demostración Local`).

---

## 5. Inspección del Esquema SQL Server LocalDB y Persistencia EF6

Se ejecutaron consultas de solo lectura en la base `EcomixIA` sobre la instancia `(localdb)\MSSQLLocalDB`:

### 5.1 Conteo de Registros Verificado
* `dbo.Materials`: **10 registros** (íntegros).
* `dbo.Mezclas`: **8 registros** (íntegros).
* `dbo.MezclaComponentes`: **32 registros** (íntegros).
* `dbo.__MigrationHistory`: **1 registro** (íntegro).

### 5.2 Detalle de `dbo.__MigrationHistory`
* **MigrationId:** `202611082237174_InitialCreate`
* **ContextKey:** `EcomixIA.Models.EcomixContext`
* **ModelLength:** 1,843 bytes
* **ProductVersion:** `6.5.1`

### 5.3 Estructura de `dbo.Mezclas`
Columnas existentes: `Id` (int), `Nombre` (nvarchar), `ResistenciaMPa` (decimal), `EdadDias` (int), `RelacionAguaCemento` (decimal, null), `AsentamientoCm` (decimal, null), `Notas` (nvarchar, null).  
**Constatación:** La columna de vinculación de propietario (`OwnerUserId`) **no existe** en la tabla.

### 5.4 Situación del Código de Migraciones
Se comprobó que el directorio `Migrations/` **no existe** en el árbol del proyecto ni ha existido en el historial de Git. El archivo `202611082237174_InitialCreate.cs` no está disponible en código fuente.

---

## 6. Justificación Técnica de la Estrategia de Migración Seleccionada

Se compararon dos arquitecturas de persistencia para incorporar ASP.NET Identity 2 en EF6:

* **Opción A (Contexto Integrado `EcomixContext : IdentityDbContext`):**
  - Obliga a modificar el `EcomixContext` preexistente.
  - Al detectar un modelo diferente a `202611082237174_InitialCreate` y carecer de las migraciones fuente, EF6 arrojaría `ModelCompatibilityException` o intentaría generar scripts de migración que dupliquen o alteren las tablas `Materials`, `Mezclas` y `MezclaComponentes`.
* **Opción B (Contexto Independiente `ApplicationDbContext : IdentityDbContext<ApplicationUser>`):**
  - Crea un nuevo contexto de seguridad que apunta a la misma cadena de conexión (`DefaultConnection`), registrándose en `dbo.__MigrationHistory` con su propio `ContextKey = "EcomixIA.Models.ApplicationDbContext"`.
  - Mantiene el contexto de negocio `EcomixContext` **100% inalterado y aislado**, eliminando cualquier riesgo de colisión de esquemas o fallo de compatibilidad de datos preexistentes.
  - Sus migraciones se gestionarán en un directorio dedicado (`Migrations\Identity`).

**Veredicto Arquitectural:** Se adopta de forma unánime y oficial la **Opción B**.

---

## 7. Plan de Mitigación de Riesgos de Transición (Safe Denial)

Para cumplir con la decisión **D-01** (Privacidad de mezclas por propietario) y **D-08** (No intromisión administrativa) antes de que la Fase 3 introduzca `OwnerUserId`:

1. **Listado en `MezclasController.Index()`:** No expondrá las mezclas existentes a ningún usuario autenticado; devolverá un listado vacío hasta que se implemente la propiedad formal en Fase 3.
2. **Acceso directo por ID (`Details`, `Edit`, `Delete`, `AgregarComponente`):** Cualquier solicitud sobre las Mezclas 1 a 8 devolverá de forma segura un código **HTTP 404** o **HTTP 403**, impidiendo la consulta o edición no autorizada de fórmulas legadas.
3. **Preservación:** Los 8 registros de mezclas y sus 32 componentes permanecerán resguardados en SQL Server LocalDB sin modificaciones ni eliminaciones.

---

## 8. Diseño del Servicio de Correo y Provisión Administrativa

### 8.1 Correo Transaccional (D-03)
* **Interfaz:** `IEmailService` desacoplada con método `Task SendEmailAsync(string toEmail, string subject, string bodyHtml)`.
* **Implementación local:** `SimulatedEmailService` que almacena los correos en `App_Data/EmailOutbox/` para inspección local de enlaces y tokens de confirmación, sin tráfico de red real ni costo alguno.
* **Validación de dominios autorizados:**
  - Expresión regular canónica que admite única y exclusivamente: `@upt.pe`, `@virtual.upt.pe` y `@gmail.com`.

### 8.2 Provisión del Administrador Inicial (D-10)
* Procedimiento manual fuera del flujo web (CLI interactivo o script de gestión que invoca a `UserManager`).
* Sin credenciales hardcoded en repositorio.
* Sin auto-promoción por dominio de correo y sin capacidad del Administrador para ver mezclas ajenas (D-08).

---

## 9. Plan de Implementación de la Fase 2 (F2.1 a F2.5)

| Subetapa | Alcance Técnico | Entregable Principal |
| :---: | :--- | :--- |
| **F2.1** | Infraestructura Identity 2 y OWIN | Instalación controlada de paquetes NuGet, creación de `ApplicationDbContext`, `ApplicationUser`, pipeline OWIN `Startup.Auth.cs` y migración inicial de tablas `AspNet*`. |
| **F2.2** | Registro y Verificación de Correo (D-03) | Vistas y acciones de registro con validación estricta de dominios (`upt.pe`, `virtual.upt.pe`, `gmail.com`), `IEmailService` con emisor simulado local y confirmación por token. |
| **F2.3** | Autenticación y Sesiones Seguras | Login y Logout con cookies OWIN protegidas, bloqueo por fuerza bruta, recuperación segura de contraseñas y adaptación dinámica de navbar (`_Layout.cshtml`). |
| **F2.4** | Control de Roles (RBAC) y Salvaguardas | Roles `Administrador` y `Registrado`, herramienta de provisión del administrador inicial (D-10), protección de `MaterialesController` (D-02) y Safe Denial en `MezclasController`. |
| **F2.5** | Pruebas de Seguridad y Cierre F2 | Pruebas de penetración (IDOR, role injection, bypass de token), suite de regresión SM-01 a SM-08, verificación de base de datos, consolidación y commit de Fase 2. |

---

## 10. Estado de la Base de Datos LocalDB y Presupuesto Azure

* **Integridad SQL Server LocalDB (`EcomixIA`):**
  - `dbo.Materials`: 10 registros (verificado).
  - `dbo.Mezclas`: 8 registros (verificado).
  - `dbo.MezclaComponentes`: 32 registros (verificado).
  - `dbo.__MigrationHistory`: 1 registro (verificado).
* **FinOps Azure (D-06):**
  - Gasto acumulado en la sesión: **US$ 0.00**.
  - Cero llamadas al microservicio de inferencia en la nube.

---

## 11. Declaración de Cierre de la Subetapa F2.0

La subetapa **F2.0 — Diagnóstico de identidad, autorización y migración EF6** queda formalmente **APROBADA**. El diagnóstico técnico, el análisis de riesgos y la planificación arquitectural de la Fase 2 se encuentran consolidados y listos para proceder con la subetapa **F2.1** bajo autorización del usuario.

---

## 12. Evidencias de Ejecución de la Subetapa F2.1: Infraestructura Identity 2, OWIN y Migración EF6 Controlada

### 12.1 Resumen de Actividades de F2.1
Durante la subetapa F2.1 se implementó la infraestructura de base para la autenticación y autorización en EcoMix IA:
1. **Instalación de paquetes oficiales:** Descarga e incorporación de ASP.NET Identity 2 y OWIN 4.2.2 en `packages.config` y `EcomixIA.csproj`.
2. **Modelos de Identidad y Contexto Independiente:** Creación de `ApplicationUser : IdentityUser` y `ApplicationDbContext : IdentityDbContext<ApplicationUser>` en [`Models/IdentityModels.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Models/IdentityModels.cs).
3. **Pipeline OWIN:** Configuración de middleware en [`Startup.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Startup.cs) y [`App_Start/Startup.Auth.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/App_Start/Startup.Auth.cs) con `CookieAuthenticationOptions` (`LoginPath = "/Account/Login"`, `HttpOnly = true`, `ExpireTimeSpan = 8h`, `SlidingExpiration = true`).
4. **Configuración de Servicios de Identidad:** Implementación de `ApplicationUserManager` y `ApplicationSignInManager` en [`App_Start/IdentityConfig.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/App_Start/IdentityConfig.cs) con directivas de contraseñas robustas (longitud mínima 8, mayúscula, minúscula, dígito, carácter especial) y bloqueo de cuenta tras 5 intentos fallidos.
5. **Configuración de Migraciones EF6:** Configuración independiente en [`Migrations/Identity/Configuration.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Migrations/Identity/Configuration.cs) con `ContextKey = "EcomixIA.Models.ApplicationDbContext"` y generación de la migración inicial `IdentityInitialCreate`.
6. **Cumplimiento Estricto del Safety Gate:**
   - Respaldo de seguridad `COPY_ONLY` con checksum de la base original `EcomixIA`.
   - Restauración `WITH MOVE` en base de prueba secundaria: `EcomixIA_F2_Migration_Test`.
   - Ejecución de la migración únicamente sobre `EcomixIA_F2_Migration_Test`.
   - Comprobación de integridad del esquema y datos de negocio preexistentes.
   - Prueba comprobada de reversibilidad (`Down` / Rollback) con retorno al estado previo.
   - Preservación al 100% de la base principal `EcomixIA` sin modificaciones.
7. **Compilación y Pruebas de Regresión:** Compilación exitosa con MSBuild (0 errores, 0 advertencias) y verificación operativa de las 8 pruebas de humo (SM-01 a SM-08: 100% PASS).

---

### 12.2 Inventario de Paquetes NuGet Instalados
Se añadieron formalmente las siguientes dependencias al proyecto:

| Paquete | Versión | Propósito Arquitectural |
| :--- | :---: | :--- |
| `Microsoft.AspNet.Identity.Core` | 2.2.4 | Definición de contratos de usuario, roles, hashing criptográfico y claims. |
| `Microsoft.AspNet.Identity.EntityFramework` | 2.2.4 | Proveedores de persistencia EF6 (`IdentityDbContext`, `UserStore`, `RoleStore`). |
| `Microsoft.AspNet.Identity.Owin` | 2.2.4 | Integración entre Identity y OWIN (`UserManager`, `SignInManager`, cookies). |
| `Microsoft.Owin` | 4.2.2 | Núcleo de abstracción del pipeline OWIN. |
| `Microsoft.Owin.Host.SystemWeb` | 4.2.2 | Adaptador de hosting OWIN para ASP.NET clásico e IIS Express. |
| `Microsoft.Owin.Security` | 4.2.2 | Infraestructura base de seguridad y protección de tickets criptográficos. |
| `Microsoft.Owin.Security.Cookies` | 4.2.2 | Middleware de autenticación mediante cookies (`ApplicationCookie`). |
| `Microsoft.Owin.Security.OAuth` | 4.2.2 | Infraestructura OAuth 2.0 y soporte de tokens. |
| `Owin` | 1.0 | Interfaz canónica OWIN `IAppBuilder`. |

---

### 12.3 Configuración de Enlaces y Redirecciones en `Web.config`
Para resolver los conflictos de dependencia entre ensamblados compilados para OWIN 3.0.1 e instalados en versión 4.2.2, se incorporaron las redirecciones requeridas en el nodo `<runtime>` de [`Web.config`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Web.config):
* `Microsoft.Owin`: de `0.0.0.0-4.2.2.0` a `4.2.2.0`.
* `Microsoft.Owin.Security`: de `0.0.0.0-4.2.2.0` a `4.2.2.0`.
* `Microsoft.Owin.Security.Cookies`: de `0.0.0.0-4.2.2.0` a `4.2.2.0`.
* `Microsoft.Owin.Security.OAuth`: de `0.0.0.0-4.2.2.0` a `4.2.2.0`.

---

### 12.4 Migración Inicial de Identidad (`IdentityInitialCreate`)
Generada bajo el namespace `EcomixIA.Migrations.Identity`:
* **Clase:** `IdentityInitialCreate : DbMigration, IMigrationMetadata`
* **Id de Migración:** `202611091550114_IdentityInitialCreate`
* **ContextKey:** `EcomixIA.Models.ApplicationDbContext`
* **Tablas Creadas en `Up()`:**
  1. `dbo.AspNetRoles`: `Id` (PK nvarchar 128), `Name` (nvarchar 256, índice único `RoleNameIndex`).
  2. `dbo.AspNetUsers`: `Id` (PK nvarchar 128), `Email`, `EmailConfirmed`, `PasswordHash`, `SecurityStamp`, `PhoneNumber`, `PhoneNumberConfirmed`, `TwoFactorEnabled`, `LockoutEndDateUtc`, `LockoutEnabled`, `AccessFailedCount`, `UserName` (índice único `UserNameIndex`).
  3. `dbo.AspNetUserRoles`: `UserId`, `RoleId` (PK compuesta, FKs a `AspNetUsers` y `AspNetRoles` con cascade delete).
  4. `dbo.AspNetUserClaims`: `Id` (PK int identity), `UserId` (FK a `AspNetUsers`), `ClaimType`, `ClaimValue`.
  5. `dbo.AspNetUserLogins`: `LoginProvider`, `ProviderKey`, `UserId` (PK compuesta, FK a `AspNetUsers`).
* **Operaciones en `Down()`:** Eliminación ordenada de llaves foráneas, índices y tablas `AspNet*`, y remoción del registro correspondiente en `dbo.__MigrationHistory`.

---

### 12.5 Protocolo Safety Gate: Ejecución y Verificación en Base Clonada

#### 12.5.1 Respaldo `COPY_ONLY`
* **Origen:** Base `EcomixIA` en `(localdb)\MSSQLLocalDB`.
* **Destino:** `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_PreF2_Migration.bak`.
* **Resultado:** Respaldo procesado exitosamente (425 páginas, 157.8 MB/s), verificación de integridad (`RESTORE VERIFYONLY WITH CHECKSUM`) válida.

#### 12.5.2 Restauración de Base de Pruebas (`EcomixIA_F2_Migration_Test`)
* **Archivos físicos asignados:**
  - MDF: `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_F2_Migration_Test.mdf`
  - LDF: `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_F2_Migration_Test_log.ldf`
* **Verificación de Integridad:** `DBCC CHECKDB ('EcomixIA_F2_Migration_Test') WITH NO_INFOMSGS` completada sin errores.
* **Línea base previa comprobada:**
  - `Materials`: 10 registros.
  - `Mezclas`: 8 registros.
  - `MezclaComponentes`: 32 registros.
  - `__MigrationHistory`: 1 registro (`202611082237174_InitialCreate`, `ContextKey = "EcomixIA.Models.EcomixContext"`).

#### 12.5.3 Aplicación de la Migración sobre `EcomixIA_F2_Migration_Test`
* **Comando:** `ef6.exe database update --migrations-config EcomixIA.Migrations.Identity.Configuration ...`
* **Resultado:** Migración `202611091550114_IdentityInitialCreate` aplicada exitosamente.
* **Inspección post-migración:**
  - Tablas físicas creadas: `AspNetRoles`, `AspNetUsers`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`.
  - Registros en tablas `AspNet*`: 0 en todas las tablas (sin usuarios ni roles semilla, cumpliendo la especificación).
  - Registros en tablas de negocio: `Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32` (completamente intactos).
  - Registros en `__MigrationHistory`: 2 registros:
    1. `202611082237174_InitialCreate` | `EcomixIA.Models.EcomixContext` | `6.5.1`
    2. `202611091550114_IdentityInitialCreate` | `EcomixIA.Models.ApplicationDbContext` | `6.5.1`

#### 12.5.4 Verificación de Reversibilidad (Rollback)
* **Comando:** `ef6.exe database update --target "0" --migrations-config EcomixIA.Migrations.Identity.Configuration ...`
* **Resultado:**
  - Las 5 tablas `AspNet*` y sus índices fueron eliminados.
  - El registro de `ApplicationDbContext` en `__MigrationHistory` fue removido.
  - Las tablas de negocio conservaron su conteo exacto (`Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32`).
  - `__MigrationHistory` retornó a 1 registro exacto (`EcomixContext`).
* **Re-aplicación final:** Se volvió a aplicar la migración sobre `EcomixIA_F2_Migration_Test` para dejar el entorno de pruebas actualizado.

---

### 12.6 Verificación de la Base de Datos Principal (`EcomixIA`)
En estricto cumplimiento de la restricción de alcance de F2.1, la base de datos principal `EcomixIA` **no fue alterada**:
* Tablas físicas en `EcomixIA`: 4 tablas (`Materials`, `Mezclas`, `MezclaComponentes`, `__MigrationHistory`).
* Cero tablas `AspNet*` creadas en `EcomixIA`.
* Conteos: `Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32`, `__MigrationHistory: 1`.

---

### 12.7 Resultado de Compilación MSBuild
* **Herramienta:** Visual Studio 2022 Community MSBuild 17.14.
* **Configuración:** `Debug | Any CPU`.
* **Resultado:** `Compilación correcta. 0 Advertencia(s), 0 Errores.`

---

### 12.8 Pruebas de Regresión y Humo (SM-01 a SM-08)
Ejecutadas con IIS Express activo sobre `https://localhost:44357/`:

| Prueba | Ruta / Endpoint | HTTP Status | Contenido Verificado | Resultado |
| :---: | :--- | :---: | :--- | :---: |
| **SM-01** | `/` | **200 OK** | Carga de portada promocional y marca EcoMix. | **PASS** |
| **SM-02** | `/Materiales/Index` | **200 OK** | Catálogo con 10 materiales visibles. | **PASS** |
| **SM-03** | `/Materiales/Details/1` | **200 OK** | Ficha de material 1 (`Cemento Portland Tipo I`). | **PASS** |
| **SM-04** | `/Mezclas/Index` | **200 OK** | Listado de 8 mezclas maestras operativas. | **PASS** |
| **SM-05** | `/Mezclas/Details/1` | **200 OK** | Ficha de Mezcla 1 (`Concreto f'c 210`) y componentes. | **PASS** |
| **SM-06** | `/Mezclas/Details/7` | **200 OK** | Mezcla 7 sin componentes renderizada con métricas cero. | **PASS** |
| **SM-07** | `/Mezclas/Simulador` | **200 OK** | Formulario de dosificación y controles de preset. | **PASS** |
| **SM-08** | `/Mezclas/Simulador?mezclaId=1` | **200 OK** | Precarga correcta de fórmula de Mezcla 1 (350 kg/m³ cemento). | **PASS** |

**Resultado global de regresión:** **8/8 PASS (100%)**. Cero regresiones funcionales detectadas.

---

### 12.9 Estado FinOps Azure (D-06)
* **Consumo atribuible a la subetapa F2.1:** **US$ 0.00**.
* **Estado:** Cumplimiento total de salvaguarda presupuestaria.

---

### 12.10 Declaración de Cierre de la Subetapa F2.1
La subetapa **F2.1 — Infraestructura Identity 2, OWIN y migración EF6 controlada** queda formalmente **APROBADA**. La solución cuenta con la infraestructura completa de identidad compilada y validada, la migración de tablas `AspNet*` verificada y reversible en base de prueba, la base de datos principal protegida intacta y las pruebas de humo al 100% PASS, quedando lista para la implementación del registro y validación de correo en **F2.2**.

---

## 13. Evidencias de Ejecución de la Subetapa F2.2: Registro, Dominios Permitidos y Confirmación de Correo

### 13.1 Resumen Ejecutivo de la Subetapa F2.2
Durante la subetapa F2.2 se implementó de forma segura el subsistema de registro de cuentas y verificación de correo electrónico:
1. **Validación estricta de dominios autorizados (RF-04, RF-05):** Servicio [`EmailDomainValidator`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/EmailDomainValidator.cs) que admite exclusivamente correos pertenecientes a `@upt.pe`, `@virtual.upt.pe` o `@gmail.com`, rechazando de forma categórica cualquier otro dominio o intento de spoofing/subdominios no autorizados.
2. **Aislamiento obligatorio mediante Safety Gate:** Servicio [`RegistrationSafetyGate`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/RegistrationSafetyGate.cs) que deshabilita el registro por defecto, prohíbe taxativamente la creación de cuentas sobre la base principal `EcomixIA`, y autoriza la operación únicamente cuando se apunta a la base de ensayo `EcomixIA_F2_Migration_Test` con la configuración explícita `EcoMix:EnableRegistrationTesting = true`.
3. **Formulario y Controlador de Registro:** Implementación de [`AccountController`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AccountController.cs) y [`RegisterViewModel`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Models/AccountViewModels.cs) con validación server-side, mensajes comprensibles en español y protección antiforgery.
4. **Asignación controlada de roles:** Toda cuenta recién registrada recibe única y exclusivamente el rol `Registrado`. No se admiten propiedades de privilegios (`Role`, `IsAdmin`, `UserId`) en el modelo de registro ni se crean administradores por vía pública.
5. **Servicio de correo transaccional desacoplado (D-03):** Interfaz [`ITransactionalEmailSender`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/ITransactionalEmailSender.cs) e implementación de desarrollo [`SimulatedEmailService`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/SimulatedEmailService.cs) que escribe los mensajes simulados en `App_Data/EmailOutbox/` (excluido de Git), sin tráfico de red real ni costos en la nube.
6. **Flujo de confirmación criptográfica:** Generación de tokens de confirmación con validez de 24 horas y endpoint `GET /Account/ConfirmEmail`. Toda cuenta inicia con `EmailConfirmed = false` y solo pasa a `true` tras validar el token. La confirmación no inicia sesión automáticamente.
7. **Preservación estricta:** La base principal `EcomixIA` permanece 100% libre de tablas y usuarios de identidad. La mitigación *Safe Denial* sobre las 8 mezclas legadas queda ratificada para la subetapa F2.3.

---

### 13.2 Artefactos de Código Creados y Modificados
* **Servicios de Identidad y Seguridad:**
  - [`Services/IEmailDomainValidator.cs` / `EmailDomainValidator.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/EmailDomainValidator.cs): Validación sintáctica y canónica de dominios (`upt.pe`, `virtual.upt.pe`, `gmail.com`).
  - [`Services/IRegistrationSafetyGate.cs` / `RegistrationSafetyGate.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/RegistrationSafetyGate.cs): Verificación obligatoria de entorno de ensayo y bloqueo de la base principal `EcomixIA`.
  - [`Services/ITransactionalEmailSender.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/ITransactionalEmailSender.cs): Contrato desacoplado para envío de correos transaccionales.
  - [`Services/SimulatedEmailService.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/SimulatedEmailService.cs): Emisor simulado local para desarrollo que genera archivos en `App_Data/EmailOutbox/`.
* **Controladores y Modelos:**
  - [`Controllers/AccountController.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AccountController.cs): Acciones `Register` (GET/POST) y `ConfirmEmail` (GET).
  - [`Models/AccountViewModels.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Models/AccountViewModels.cs): Definición de `RegisterViewModel` (Email, Password, ConfirmPassword).
  - [`Models/IdentityModels.cs`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Models/IdentityModels.cs): Sobrecarga de constructor en `ApplicationDbContext(string connectionString)` para soportar instancias en pruebas de ensayo.
* **Vistas Razor (Bootstrap 5.3.3):**
  - [`Views/Account/Register.cshtml`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Account/Register.cshtml): Formulario de registro con resumen de validación, alert informativo de dominios autorizados y token antiforgery.
  - [`Views/Account/RegisterConfirmation.cshtml`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Account/RegisterConfirmation.cshtml): Pantalla de confirmación de registro indicando la revisión de bandeja de entrada.
  - [`Views/Account/ConfirmEmailSuccess.cshtml`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Account/ConfirmEmailSuccess.cshtml): Notificación de cuenta activada con rol Registrado.
  - [`Views/Account/ConfirmEmailError.cshtml`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Account/ConfirmEmailError.cshtml): Pantalla segura ante tokens inválidos, expirados o manipulados.
  - [`Views/Account/RegistrationDisabled.cshtml`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Account/RegistrationDisabled.cshtml): Vista informativa de bloqueo perimetral cuando el registro está deshabilitado.
* **Configuración del Proyecto:**
  - [`.gitignore`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/.gitignore): Exclusión de `App_Data/EmailOutbox/` y `scratch/`.
  - [`EcomixIA.csproj`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/EcomixIA.csproj): Inclusión de todos los nuevos archivos `.cs` y vistas `.cshtml`.

---

### 13.3 Matriz de Pruebas Automatizadas de F2.2 (16/16 PASS)
Ejecutadas mediante la suite automatizada sobre la base de ensayo `EcomixIA_F2_Migration_Test`:

| ID | Prueba | Resultado Esperado | Resultado Obtenido | Veredicto |
| :---: | :--- | :--- | :--- | :---: |
| **F2.2-01** | Registro `@upt.pe` | Aceptado en ensayo | Usuario creado, `EmailConfirmed = false`, Rol = `Registrado`, `IsAdmin = false` | **PASS** |
| **F2.2-02** | Registro `@virtual.upt.pe` | Aceptado en ensayo | Usuario creado, `EmailConfirmed = false`, Rol = `Registrado` | **PASS** |
| **F2.2-03** | Registro `@gmail.com` | Aceptado en ensayo | Usuario creado, `EmailConfirmed = false`, Rol = `Registrado` | **PASS** |
| **F2.2-04** | Correo no permitido (`@hotmail.com`) | Rechazado | Rechazado por validación de dominio. No creado en BD, error en `ModelState["Email"]` | **PASS** |
| **F2.2-05** | Dominio falsificado (`@upt.pe.ejemplo.com`) | Rechazado | Rechazado por validación de dominio. No creado en BD, error en `ModelState["Email"]` | **PASS** |
| **F2.2-06** | Correo duplicado | No crea segunda cuenta | Rechazado por duplicidad. Conteo en BD permanece en 1 | **PASS** |
| **F2.2-07** | Contraseña débil | Rechazada | Rechazada por `PasswordValidator` de Identity. No creada en BD | **PASS** |
| **F2.2-08** | POST con rol Administrador | No concede privilegios | No existe campo en ViewModel. Privilegios limitados a `Registrado`, `IsAdmin = false` | **PASS** |
| **F2.2-09** | Cuenta nueva | `EmailConfirmed = false` | Comprobado en BD: Todo usuario recién creado inicia con `EmailConfirmed = 0` | **PASS** |
| **F2.2-10** | Token válido | Confirma correo | Extracción de token del buzón simulado y confirmación exitosa: `EmailConfirmed = true` | **PASS** |
| **F2.2-11** | Token incorrecto/expirado | Rechazado | Token corrupto rechazado. `EmailConfirmed` permanece `false`, emite mensaje de error | **PASS** |
| **F2.2-12** | Cuenta no confirmada | Sin acceso privado | La cuenta con `EmailConfirmed = false` no tiene acceso a servicios | **PASS** |
| **F2.2-13** | Error de correo simulado | No activa cuenta | Fallo en emisor genera advertencia pero la cuenta permanece con `EmailConfirmed = false` | **PASS** |
| **F2.2-14** | Formulario sin antiforgery | Rechazado | Atributo `[ValidateAntiForgeryToken]` verificado por reflexión y probado vía HTTP (Error 500) | **PASS** |
| **F2.2-15** | Base original `EcomixIA` | Sin nuevas tablas ni usuarios | `AspNetTables = 0`, `Materials = 10`, `Mezclas = 8`, `MezclaComponentes = 32`, `Migrations = 1` | **PASS** |
| **F2.2-16** | Servicio Azure | Cero llamadas | Consumo en US$ 0.00. Cero tráfico externo de inferencia o correo | **PASS** |

**Resultado de la Matriz:** **16/16 pruebas APROBADAS (100% PASS)**.

---

### 13.4 Verificación de Bases de Datos en SQL Server LocalDB

#### 13.4.1 Base Principal `EcomixIA` (Completamente Intacta)
* **Tablas físicas:** 4 tablas (`Materials`, `Mezclas`, `MezclaComponentes`, `__MigrationHistory`).
* **Tablas de identidad creadas:** **0**.
* **Usuarios creados:** **0**.
* **Conteos de datos de negocio:** `Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32`, `__MigrationHistory: 1`.

#### 13.4.2 Base Secundaria de Ensayo `EcomixIA_F2_Migration_Test`
* **Tablas físicas:** 9 tablas (`Materials`, `Mezclas`, `MezclaComponentes`, `__MigrationHistory`, `AspNetRoles`, `AspNetUsers`, `AspNetUserRoles`, `AspNetUserClaims`, `AspNetUserLogins`).
* **Roles existentes:** 1 rol único (`Registrado`). **Ningún rol Administrador creado.**
* **Usuarios de ensayo:** 4 cuentas creadas durante las pruebas automatizadas:
  1. `docente.civil@upt.pe`: `EmailConfirmed = 0` (F2.2-01)
  2. `alumno.ambiental@virtual.upt.pe`: `EmailConfirmed = 0` (F2.2-02)
  3. `investigador.concreto@gmail.com`: `EmailConfirmed = 1` (F2.2-03, F2.2-10 confirmada con token)
  4. `fallo.envio@virtual.upt.pe`: `EmailConfirmed = 0` (F2.2-13)
* **Conteos de negocio:** `Materials: 10`, `Mezclas: 8`, `MezclaComponentes: 32` (intactos).

---

### 13.5 Pruebas de Regresión HTTP en IIS Express (SM-01 a SM-08)
Con IIS Express activo sobre `https://localhost:44357/`:
* `GET /Account/Register`: Renderiza la vista informativa `RegistrationDisabled` debido al bloqueo de Safety Gate sobre la base principal `EcomixIA`.
* `POST /Account/Register` sin token antiforgery: Rechazado con excepción HTTP antiforgery.
* **Pruebas de Humo:**
  - SM-01 (`/`): **200 OK - PASS**
  - SM-02 (`/Materiales/Index`): **200 OK - PASS**
  - SM-03 (`/Materiales/Details/1`): **200 OK - PASS**
  - SM-04 (`/Mezclas/Index`): **200 OK - PASS**
  - SM-05 (`/Mezclas/Details/1`): **200 OK - PASS**
  - SM-06 (`/Mezclas/Details/7`): **200 OK - PASS**
  - SM-07 (`/Mezclas/Simulador`): **200 OK - PASS**
  - SM-08 (`/Mezclas/Simulador?mezclaId=1`): **200 OK - PASS**

**Resultado de Regresión:** **8/8 PASS (100%)**.

---

### 13.6 Control Presupuestario FinOps Azure (D-06)
* **Consumo atribuible a la subetapa F2.2:** **US$ 0.00**.
* **Llamadas a servicios de inferencia ML:** 0.

---

### 13.7 Declaración de Cierre de la Subetapa F2.2
La subetapa **F2.2 — Registro, dominios permitidos y confirmación de correo** queda formalmente **APROBADA**. La validación estricta de dominios, el formulario de registro, el emisor de correo simulado en desarrollo, la confirmación criptográfica de cuentas y el protocolo de seguridad Safety Gate se encuentran completamente verificados en el entorno de ensayo aislado, con cero alteraciones sobre la base principal y cero llamadas a la nube, quedando el proyecto preparado para la subetapa **F2.3 (Autenticación, Sesiones Seguras y Recuperación de Contraseña)**.


---

## 14. Evidencias de F2.3-A — Implementación Mínima Segura (Safe Denial, Login, Confirmación, Lockout y Demo)

### 14.1 Alcance y Directriz Ágil
Siguiendo la directriz de desarrollo ágil (**MVP: mínimo, funcional y demostrable**) para la presentación del sistema:
- Se implementó la subetapa **F2.3-A** priorizando la seguridad y estabilidad demostrativa.
- **Safe Denial previo a sesiones activas (D-01 / D-08):** Se blindaron todos los puntos de acceso a mezclas legadas (`id <= 8`) en `MezclasController` para cuentas autenticadas, devolviendo HTTP 403 Forbidden o listas desinfectadas mientras no exista la columna `OwnerUserId`.
- Se integró el inicio de sesión con email y contraseña, exigencia estricta de correo confirmado (`EmailConfirmed == true`), protección de bloqueo por fuerza bruta (`Lockout` tras 5 intentos fallidos / 5 minutos) y cierre de sesión seguro (`LogOff` con token antifalsificación).
- Se adaptó la barra de navegación principal en `Views/Shared/_Layout.cshtml` al estado de la sesión (`Request.IsAuthenticated`), mostrando credenciales y controles de cierre de sesión en modo autenticado o botones de acceso y registro en modo anónimo.

### 14.2 Matriz de Pruebas Automatizadas F2.3-A (15/15 PASS)

| ID | Componente / Acción | Condición Evaluada | Resultado | Detalle de Validación |
| :--- | :--- | :--- | :---: | :--- |
| **F2.3-01** | `MezclasController.Index` | Usuario autenticado | **PASS** | Recibe lista vacía (0 elementos) con alerta explicativa Safe Denial |
| **F2.3-02** | `MezclasController.Index` | Usuario anónimo (demo) | **PASS** | Recibe las 8 mezclas del catálogo público correctamente |
| **F2.3-03** | `MezclasController.Details` | Usuario autenticado (ID 1..8) | **PASS** | Bloqueado con HTTP 403 Forbidden en todas las mezclas legadas |
| **F2.3-04** | `MezclasController.Details` | Usuario anónimo (ID 1) | **PASS** | Carga vista de detalle de mezcla 1 con componentes y dosificación |
| **F2.3-05** | `MezclasController.Edit` | Usuario autenticado (GET/POST) | **PASS** | Bloqueado con HTTP 403 Forbidden ante cualquier intento de edición |
| **F2.3-06** | `MezclasController.Delete` | Usuario autenticado (GET/POST) | **PASS** | Bloqueado con HTTP 403 Forbidden ante cualquier intento de eliminación |
| **F2.3-07** | `MezclasController.AgregarComponente` | Usuario autenticado (mezcla 1) | **PASS** | Bloqueado con HTTP 403 Forbidden ante manipulación de componentes |
| **F2.3-08** | `MezclasController.Simulador` | Usuario autenticado (`mezclaId=1`) | **PASS** | Desinfecta parámetro (`MezclaOrigenId = null`) y muestra advertencia Safe Denial |
| **F2.3-09** | `MezclasController.Simulador` | Usuario anónimo (`mezclaId=1`) | **PASS** | Precarga valores públicos de dosificación con éxito |
| **F2.3-10** | `AccountController.Login` | Usuario confirmado (`investigador.concreto@gmail.com`) | **PASS** | Autenticación válida con contraseña correcta y redirección |
| **F2.3-11** | `AccountController.Login` | Usuario no confirmado (`docente.civil@upt.pe`) | **PASS** | Bloqueado con mensaje explícito requiriendo activación previa |
| **F2.3-12** | `AccountController.Login` | Fuerza bruta (5 intentos erróneos) | **PASS** | Bloqueo preventivo de cuenta activado (`SignInStatus.LockedOut`) |
| **F2.3-13** | `AccountController.LogOff` | Cierre de sesión POST con CSRF | **PASS** | `AuthenticationManager.SignOut` y redirección a `Home/Index` |
| **F2.3-14** | Aislamiento BD Principal | `EcomixIA` tablas físicas | **PASS** | Exactamente 4 tablas de negocio (0 tablas `AspNet*`) |
| **F2.3-15** | Integridad BD Principal | `EcomixIA` conteo de filas | **PASS** | Registros intactos: Materials (10), Mezclas (8), Componentes (32), History (1) |

### 14.3 Pruebas de Humo de Regresión en IIS Express (8/8 PASS)
Ejecutadas sobre servidor local activo `https://localhost:44357/`:
- **SM-01 (Inicio / Portada):** HTTP 200 (30,650 bytes) — Carrusel, branding y accesibilidad intactos.
- **SM-02 (Catálogo Materiales):** HTTP 200 — 10 materiales visibles.
- **SM-03 (Detalle Material 1):** HTTP 200 — Datos y parámetros técnicos cargados.
- **SM-04 (Catálogo Mezclas):** HTTP 200 — Catálogo público de mezclas renderizado.
- **SM-05 (Detalle Mezcla 1):** HTTP 200 — Componentes, costos y dosificación calculados.
- **SM-06 (Detalle Mezcla 7):** HTTP 200 — Mezcla sin componentes renderiza sin excepción 500.
- **SM-07 (Simulador IA):** HTTP 200 — Formulario predictivo interactivo renderizado.
- **SM-08 (Simulador con precarga):** HTTP 200 — Dosificación de mezcla 1 precargada correctamente.

### 14.4 Verificación de Rutas de Autenticación
- `https://localhost:44357/Account/Login`: HTTP 200 (13,663 bytes) — Formulario de inicio de sesión responsive con validación y enlace a registro.
- `https://localhost:44357/Account/Register`: HTTP 200 (11,876 bytes) — Formulario de registro con validación de dominios autorizados.
- `https://localhost:44357/Account/Lockout`: HTTP 200 — Vista informativa de cuenta temporalmente bloqueada.


---

## 15. Evidencias de Consolidación SQL Local y Preparación para Azure SQL Database

### 15.1 Respaldo de Seguridad y Verificación
Se realizó un respaldo completo fuera del repositorio previo a cualquier verificación o consolidación:
- **Archivo:** `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_F2_Consolidacion_20261109_122028.bak`
- **Tamaño:** 3,561,984 bytes (3.40 MB)
- **SHA-256:** `B6AFF31C0C00F9A55FA554E7117B3A721CDDFC1680A939BA68188B3776ADAE3A`
- **RESTORE VERIFYONLY WITH CHECKSUM:** Ejecutado y verificado al 100%.
- **DBCC CHECKDB ('EcomixIA'):** 0 errores de asignación, 0 errores de consistencia.

### 15.2 Estado Consolidado de la Base de Datos Local `EcomixIA`
Se verificó la coexistencia armoniosa de los dos contextos de Entity Framework 6:
- **Contexto de Negocio (`EcomixIA.Models.EcomixContext`):**
  - `dbo.Materials`: 10 registros intactos.
  - `dbo.Mezclas`: 8 registros intactos.
  - `dbo.MezclaComponentes`: 32 registros intactos.
- **Contexto de Identidad (`EcomixIA.Models.ApplicationDbContext`):**
  - `dbo.AspNetRoles`: 0 registros.
  - `dbo.AspNetUsers`: 0 registros.
  - `dbo.AspNetUserRoles`: 0 registros.
  - `dbo.AspNetUserClaims`: 0 registros.
  - `dbo.AspNetUserLogins`: 0 registros.
- **Historial de Migraciones (`dbo.__MigrationHistory`):** Exactamente 2 registros correspondientes a las migraciones `202611082237174_InitialCreate` e `202611091550114_IdentityInitialCreate`.

### 15.3 Pruebas de Conexión y Navegación
- `GET /` -> HTTP 200 OK
- `GET /Account/Login` -> HTTP 200 OK
- `GET /Account/Register` -> HTTP 200 OK
- `GET /Materiales/Index` -> HTTP 200 OK
- `GET /Mezclas/Index` -> HTTP 200 OK

### 15.4 Estrategia de Preparación para Azure SQL Database
- Documento consolidado: [`docs/FASE_02_PREPARACION_AZURE_SQL.md`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/FASE_02_PREPARACION_AZURE_SQL.md).
- Script DDL generado: [`docs/IdentityInitialCreate_Generated.sql`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/IdentityInitialCreate_Generated.sql).
- Verificada la compatibilidad de todos los tipos de datos y clustered primary keys para Azure SQL.
- Confirmada la estrategia de inyección segura de cadena de conexión `DefaultConnection` en Azure App Service (Connection Strings `SQLAzure`) para evitar exponer credenciales en Git o `Web.config`.
- Presupuesto D-06 preservado: Cero recursos facturables creados en Azure (US$ 0.00 en la sesión).

---

## 16. Activación Local de Registro, Login y Suite de Pruebas de Autorización (AUTH-01 a AUTH-12)

### 16.1 Respaldo Pre-Activación de Seguridad
Previo a cualquier inserción de roles o usuarios en la base principal `EcomixIA`, se generó y verificó un respaldo completo independiente:
- **Archivo de respaldo:** `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_02\EcomixIA_Pre_Activacion_Cuentas_20261109_123612.bak`
- **Tamaño:** 3,561,984 bytes (3.40 MB)
- **SHA-256:** `65A0FA59318CA39410938FB44F54FCE674085D2FDB11E43498B4415E7874F914`
- **Verificación:** `RESTORE VERIFYONLY WITH CHECKSUM` ejecutado con éxito (100% verificado).
- **Ubicación:** Fuera del repositorio Git (`C:\Users\Admin\Desktop\Respaldos_EcoMixIA\`).

### 16.2 Endurecimiento de Seguridad y Cierre de Brechas de Autorización (Paso 2)
1. **Controlador de Mezclas (`MezclasController`):**
   - **Cierre de Brecha Anónima:** Se corrigió el acceso anónimo no intencionado a mezclas legadas (`id <= 8`).
   - **Safe Denial en `Details`:** Todas las solicitudes a `Details(1..8)` devuelven categóricamente `HTTP 403 Forbidden`, tanto para visitantes anónimos como para usuarios autenticados.
   - **Protección de Escrituras:** Acciones `Create`, `Edit`, `Delete`, `AgregarComponente` y `EliminarComponente` restringidas a `[Authorize(Roles = "Registrado,Administrador")]`. Cualquier intento de modificar registros legados (`id <= 8`) es abortado con `HTTP 403 Forbidden`.
   - **Sanitización del Simulador:** Las llamadas a `Simulador(1..8)` desinfectan la precarga (`MezclaOrigenId = null`) y muestran una alerta informativa de privacidad (Safe Denial) tanto a usuarios autenticados como anónimos.
2. **Controlador de Materiales (`MaterialesController`):**
   - **Lectura Pública:** Acciones `Index` y `Details` configuradas con `[AllowAnonymous]` permitiendo la consulta pública del catálogo de materiales según la especificación SRS.
   - **Protección Server-Side de Escrituras:** Acciones `Create`, `Edit` y `Delete` (GET y POST) blindadas con `[Authorize(Roles = "Administrador")]` y validación programática `User.IsInRole("Administrador")`. Cualquier solicitud de un usuario sin este rol devuelve `HTTP 403 Forbidden`.

### 16.3 Configuración del Safety Gate para Desarrollo Local (Paso 3)
- **Servicio `RegistrationSafetyGate`:**
  - Verificación estricta de servidor de desarrollo: Prohíbe terminantemente conexiones a bases de datos remotas o de nube, admitiendo únicamente instancias locales verificadas (`(localdb)`, `localhost`, `127.0.0.1`, `(local)`, `.\`).
  - Para la base principal `EcomixIA`, exige la activación simultánea de dos banderas explícitas en `Web.config`.
  - Bloqueo preventivo por defecto ante cualquier discrepancia.
- **Directivas activadas en `Web.config`:**
  ```xml
  <add key="EcoMix:EnableRegistrationTesting" value="true" />
  <add key="EcoMix:AllowLocalMainDbRegistration" value="true" />
  ```

### 16.4 Provisión Idempotente del Rol `Registrado` (Paso 4)
- **Rol creado:** `Registrado` (Id: `6894EAF8-4D32-42EE-B3F6-F012501FDC00`).
- **Idempotencia:** Inserción controlada mediante script T-SQL / Identity verificado.
- **Principio de Mínimo Privilegio:** No se creó el rol `Administrador` en la base de datos ni se asignaron privilegios administrativos en esta etapa.

### 16.5 Resultados de la Suite de Pruebas Automatizadas (AUTH-01 a AUTH-12)
Ejecutada mediante el arnés automatizado `scratch/run_auth_suite.ps1` sobre la base de datos principal `EcomixIA` en `(localdb)\MSSQLLocalDB`:

| ID | Prueba | Resultado esperado | Resultado obtenido | Estado |
|---|---|---|---|---|
| **AUTH-01** | Registro válido | Cuenta creada en `AspNetUsers` | Usuario creado en BD con rol `Registrado` | **PASS** |
| **AUTH-02** | Dominio no permitido | Rechazado | Dominios `yahoo`, `hotmail`, subdominios fraudulentos y TLDs alterados rechazados; `@upt.pe`, `@virtual.upt.pe` y `@gmail.com` aceptados | **PASS** |
| **AUTH-03** | Cuenta nueva | Sin confirmar | Cuenta recién creada tiene `EmailConfirmed = false` | **PASS** |
| **AUTH-04** | Confirmación de correo | Activación correcta | Token criptográfico procesado exitosamente; `EmailConfirmed = true` | **PASS** |
| **AUTH-05** | Login válido | Sesión iniciada | `SignInManager.PasswordSignInAsync` retorna `SignInStatus.Success` con credenciales válidas y correo confirmado | **PASS** |
| **AUTH-06** | Contraseña incorrecta | Acceso rechazado | Retorna `SignInStatus.Failure` ante contraseña errónea | **PASS** |
| **AUTH-07** | Cuenta no confirmada | Acceso rechazado | Login rechazado informando necesidad obligatoria de confirmar correo | **PASS** |
| **AUTH-08** | Logout | Sesión finalizada | `AccountController.LogOff` ejecuta `AuthenticationManager.SignOut` y redirige a `Home/Index` | **PASS** |
| **AUTH-09** | Acceso anónimo a mezcla legada | Denegado | `MezclasController.Details(1..8)` retorna `HTTP 403 Forbidden` para visitantes | **PASS** |
| **AUTH-10** | Acceso autenticado a mezcla legada | Denegado | `MezclasController.Details`, `Edit` y `Delete` (1..8) retornan `HTTP 403 Forbidden` para usuarios con rol `Registrado` | **PASS** |
| **AUTH-11** | Escritura de materiales sin rol Administrador | Denegada | `MaterialesController.Create`, `Edit` y `Delete` bloqueados con `HTTP 403 Forbidden`; `Index` y `Details` públicos permitidos | **PASS** |
| **AUTH-12** | Integridad de Base de Datos | Datos de negocio intactos | Materials: 10, Mezclas: 8, MezclaComponentes: 32, __MigrationHistory: 2 | **PASS** |

**Resultado consolidado:** 12 de 12 pruebas aprobadas (**100% PASS**).

### 16.6 Estado SQL y de Seguridad
- **Tablas de Negocio:**
  - `dbo.Materials`: 10 registros intactos.
  - `dbo.Mezclas`: 8 registros intactos.
  - `dbo.MezclaComponentes`: 32 registros intactos.
- **Tablas de Identidad (`ApplicationDbContext`):**
  - `dbo.AspNetRoles`: 1 registro (`Registrado`).
  - `dbo.AspNetUsers`: 0 roles administrativos, contraseñas protegidas mediante PBKDF2 (HMAC-SHA256).
- **Protección Antifraude y Lockout:** Activado bloqueo tras 5 intentos fallidos por un lapso de 5 minutos.
- **Protección Antiforgery:** Formularios `Login`, `Register` y `LogOff` protegidos con `[ValidateAntiForgeryToken]`.

### 16.7 Limitaciones Pendientes y Requisitos para Azure
1. **Servicio Transaccional de Correo:** El emisor actual `SimulatedEmailService` opera exclusivamente en desarrollo local guardando archivos en `App_Data/EmailOutbox/`. Para Azure se requerirá un proveedor SMTP/API real (SendGrid, Azure Communication Services).
2. **Entorno de Registro en Producción:** El Safety Gate permanecerá bloqueando registros en cualquier instancia que no sea el entorno local autorizado hasta que se configure la infraestructura definitiva de producción.
3. **Presupuesto Azure (D-06):** No se crearon recursos facturables en Azure durante la sesión (consumo US$ 0.00).

---

## 17. Limpieza Visual Definitiva del MVP (Navbar, Skip-Link y Eliminación de Footer)

### 17.1 Objetivos y Alcance de la Intervención
Se aplicó una refactorización frontend sobria y minimalista centrada en simplificar la navegación superior y eliminar bloques informativos redundantes o extensos en la parte inferior, asegurando accesibilidad WCAG AAA y fidelidad estética con la paleta verde de EcoMix IA:
1. **Menú de Navegación Principal (`_Layout.cshtml`, `site.css`):**
   - Incorporación del bloque de usuario autenticado con icono `<i class="bi bi-person-circle"></i>`, correo en blanco de alto contraste (`.ecomix-user-email` con truncado preventivo responsive `max-width: 200px`), insignia estilizada `.ecomix-badge-registrado` (fondo `#DCFCE7`, texto `#14532D`, borde `#BBF7D0`), y botón `.ecomix-btn-logout` en estilo outline claro (sin rojo agresivo) con icono de salida.
   - Preservación íntegra de la acción POST de logout con token antiforgery (`@Html.AntiForgeryToken()`).
   - Integración de `data-bs-theme="dark"` en `<nav>` para consistencia de contraste.
2. **Corrección de Accesibilidad Skip-Link (Tarea 2):**
   - Aplicación de la clase oficial Bootstrap 5.3 `.visually-hidden-focusable` junto a `.ecomix-skip-link`.
   - Ocupa exactamente 0 píxeles en el flujo normal del documento cuando no está en foco.
   - Se hace visible flotante únicamente ante navegación por teclado con la tecla `Tab` (`position: fixed; top: 0.75rem; left: 0.75rem; z-index: 9999;`).
3. **Eliminación Total del Footer Extenso (Tarea 3):**
   - Retiro definitivo del elemento `<footer class="ecomix-footer">` de 67 líneas que contenía logos repetidos, descripciones largas, listas duplicadas de normas, advertencias institucionales y copyright.
   - Sin sustitución por otro footer multi-columna. La página finaliza limpiamente tras el contenedor `<main>`.
4. **Simplificación de la Portada (`Home/Index.cshtml` - Tarea 4):**
   - Retiro de la sección completa "Propósito académico y ambiental de EcoMix IA" (50 líneas de panel institucional y párrafos).
   - Sustitución de la advertencia larga "Diferenciación metodológica" por una única frase discreta y sobria:  
     *“EcoMix IA es un prototipo académico. Sus estimaciones son orientativas y no sustituyen ensayos de laboratorio.”*

### 17.2 Evidencias Visuales Generadas (Edge Headless)
- [`docs/screenshot_home_clean.png`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/screenshot_home_clean.png): Portada limpia en resolución desktop (1280x1050), sin skip-link visible, sin footer y con aviso discreto.
- [`docs/screenshot_home_bottom.png`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/screenshot_home_bottom.png): Captura vertical completa que evidencia la terminación sobria del sistema tras los 3 pasos de trabajo.
- [`docs/screenshot_navbar_autenticado.png`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/screenshot_navbar_autenticado.png): Navbar renderizado con sesión de cuenta activa (`operador.civil@upt.pe`), insignia `Registrado` de alta legibilidad y botón `Salir` outline claro.
- [`docs/screenshot_navbar_mobile.png`](file:///c:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/screenshot_navbar_mobile.png): Comprobación responsive en viewport móvil (390x844).

### 17.3 Verificación de Codificación UTF-8 y Compilación
- `Views/Shared/_Layout.cshtml`: UTF-8 con BOM verificado (`b'\xef\xbb\xbf'`), 0 caracteres mojibake.
- `Views/Home/Index.cshtml`: UTF-8 con BOM verificado (`b'\xef\xbb\xbf'`), 0 caracteres mojibake.
- `Content/site.css`: UTF-8 limpio sin BOM para compatibilidad con Chromium (`b'/* ...'`), 0 variables CSS corrompidas.
- Compilación MSBuild: **0 errores, 0 advertencias**.

---

## 18. Consolidación del MVP de Fase 2 y Preparación para Integración

### 18.1 Auditoría de Seguridad de Configuración y Secretos
- **`Web.config` saneado:** Se eliminaron las banderas de prueba activadas (`EcoMix:EnableRegistrationTesting`, `EcoMix:AllowLocalMainDbRegistration`) del archivo versionado. Se preservaron todos los redirects de ensamblados necesarios para OWIN y la cadena de conexión estándar LocalDB.
- **`Web.Secrets.config` (Ignorado por Git):** Aloja las banderas locales y claves privadas del operador, garantizando que el entorno local conserve su funcionalidad activa sin exponer configuraciones de desarrollo al repositorio.
- **`.gitignore` reforzado:** Se añadieron exclusiones para respaldos SQL (`*.bak`, `*.mdf`, `*.ldf`), bandeja simulada (`App_Data/EmailOutbox/`) y directorio de utilidades de prueba (`scratch/`).
- **Anonimización:** Se verificó la ausencia total de datos personales en el código fuente, archivos de configuración e imágenes de documentación (utilizando la cuenta de referencia `operador.civil@upt.pe`).

### 18.2 Estado Consolidado del Sistema
- **Base de datos principal (`EcomixIA`):**
  - Materiales: 10 registros intactos.
  - Mezclas: 8 registros intactos.
  - MezclaComponentes: 32 registros intactos.
  - Historial EF6: 2 migraciones consolidadas (`InitialCreate`, `IdentityInitialCreate`).
  - Roles: 1 rol exclusivo (`Registrado`).
- **Suite de Pruebas de Seguridad y Regresión:**
  - 12 de 12 pruebas automatizadas (`AUTH-01` a `AUTH-12`) aprobadas (**100% PASS**).
- **Compilación:** Cero errores y cero advertencias en configuraciones `Debug` y `Release`.


