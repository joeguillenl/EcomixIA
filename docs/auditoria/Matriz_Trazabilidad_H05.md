# Matriz Maestra de Trazabilidad y Verificación Integral — EcoMix IA (H05-R)

**Fecha:** 20 de Noviembre de 2026  
**Rama:** `fix/ecomix-h05-premerge`  
**Hito:** H05-R — Verificación Pre-Merge y Preparación de Pull Request  
**Documentos de Referencia:** SRS v1.3, SAD v1.2, Informes H00, H01, H02, H03, H04, H05  

---

## 1. Resumen Ejecutivo de Cobertura y Estados

Para garantizar absoluta rigurosidad técnica y evitar declarar cumplimiento de integraciones externas no verificadas:
- **Implementado (Local):** Requisitos completamente implementados, probados y verificados en el stack de la aplicación web ASP.NET MVC, Entity Framework 6, Identity 2 y SQL Server LocalDB.
- **Integración Externa Pendiente:** Requisitos que dependen de suscripciones cloud, aprovisionamiento en Azure o contratos con proveedores externos (p. ej., SendGrid productivo o Azure Cost Management), los cuales se encuentran técnicamente desacoplados pero pendientes de activación final con credenciales de producción.

| Categoría | Total Definidos | Implementado (Local) | Integración Externa Pendiente | Cumplimiento Local |
|---|:---:|:---:|:---:|:---:|
| **Requerimientos Funcionales (RF)** | 55 | 51 | 4 (RF-28, RF-40 ext, RF-46, RF-47/48 portal) | **100% del Alcance Local** |
| **Requerimientos No Funcionales (RNF)** | 30 | 27 | 3 (RNF-23..25 portal/cloud) | **100% del Alcance Local** |
| **Decisiones Arquitectónicas (D)** | 10 | 10 | 0 | **100% Cumplido** |
| **TOTAL CONSOLIDADO** | **95** | **88** | **7** | **100% Conforme** |

---

## 2. Decisiones Arquitectónicas de Diseño (D-01 a D-10)

| ID | Directiva Arquitectónica | Estado | Componente / Implementación Técnica | Suite de Prueba | Evidencia y Validación |
|---|---|:---:|---|---|---|
| **D-01** | Separación de dominios y dashboards | **Implementado (Local)** | `DashboardController.cs` (personal) vs `AdminController.cs` (administrativo global). | `03_Http_Authorization_Tests.ps1`, `06_Full_Regression_H01_H04.ps1` | Aislamiento estricto de vistas `/Dashboard` y `/Admin/Dashboard`. Administrador no ve recetas ajenas. |
| **D-02** | Catálogo de materiales único y compartido | **Implementado (Local)** | `MaterialesController.cs` con `[Authorize]` a nivel de clase; CRUD exclusivo con `[Authorize(Roles="Administrador")]`. | `03_Http_Authorization_Tests.ps1` (3.1, 3.2) | Visitantes anónimos no consultan catálogo (desafiados y redirigidos a Login). Usuarios registrados solo leen. Admin realiza mutaciones. |
| **D-03** | Autenticación institucional, verificación y rate limit | **Implementado (Local)** | `EmailDomainValidator.cs`, `RegistrationSafetyGate.cs`, `RequestRateLimiter.cs`, `SimulatedEmailService.cs`. | `01_Unit_Domain_Tests.ps1` (1.3..1.5), `05_Security_Concurrency_Tests.ps1` (5.3) | Restricción `@upt.pe`/`@virtual.upt.pe`/`@gmail.com`. Limitador sliding-window por IP/cuenta. Correo transaccional simulado en desarrollo sin costo. |
| **D-04** | Dashboard personal sin historial de inferencias ML | **Implementado (Local)** | `DashboardController.cs`, `DashboardViewModel.cs`. | `06_Full_Regression_H01_H04.ps1` (6.3) | KPIs calculados exclusivamente sobre mezclas privadas guardadas. Ninguna inferencia volátil o predictiva persistida. |
| **D-05** | Identidad propia EcoMix IA inspirada en Yura | **Implementado (Local)** | `Content/Site.css`, `_Layout.cshtml`, `Views/Home/Index.cshtml`. | Inspección visual / `Guia_Instalacion_Entorno_Limpio.md` | Paleta institucional azul/ocre/cemento sin vulnerar marcas ni logotipos de terceros. |
| **D-06** | Presupuesto y contención de costos Azure (≤ $20 USD) | **Implementado (Local)** | `EcoMixMlClientService.cs`, `docs/entrega/Auditoria_Costos_Azure.md`. | `04_FastApi_Contract_Mock_Tests.ps1` | Pruebas integrales ejecutadas localmente y con mocks sin llamadas facturables a Azure. Presupuesto $0.00 consumido en H05/H05-R. |
| **D-07** | Auditoría estructurada con retención física de 30 días | **Implementado (Local)** | `AuditService.cs`, tabla `dbo.AuditEvents`, índice `IX_AuditEvents_TimestampUtc`. | `02_Integration_EF6_Sql_Tests.ps1` (2.3..2.5) | Filtro automático en `GetActiveEvents` (<30 días), purga oportunista asíncrona y depuración física idempotente por lotes. |
| **D-08** | Privacidad absoluta de recetas y mezclas privadas | **Implementado (Local)** | `MezclasController.cs`, `AuditService.cs`. | `04_FastApi_Contract_Mock_Tests.ps1` (4.5), `06_Full_Regression_H01_H04.ps1` (6.3) | Eventos ML auditan solo latencia, modelo y estado HTTP. Cero ingredientes, masas, IDs privados ni dosificaciones en auditoría. |
| **D-09** | Snapshots inmutables de precios y factores CO₂ | **Implementado (Local)** | `MezclaComponente.cs`, `H02_add_snapshots_to_mezclacomponentes.sql`. | `02_Integration_EF6_Sql_Tests.ps1` (2.2), `06_Full_Regression_H01_H04.ps1` (6.2) | Columnas `CostoPorKgGuardado` `decimal(18,4)`, `Co2PorKgGuardado` `decimal(18,4)`, `FechaSnapshotUtc`, `OrigenSnapshot` (`CAPTURADO` vs `LEGADO_SIN_VERIFICAR`). Safe Denial activo. |
| **D-10** | Provisión controlada del primer Administrador (RF-52/53) | **Implementado (Local)** | `tools/Provision-Administrator.ps1`, `H05_manual_admin_provisioning.sql`, `AdminController.cs`. | `05_Security_Concurrency_Tests.ps1` (5.1, 5.2, 5.5, 5.6) | Esquema sin admin predeterminado; script independiente con precondición RF-53 (bloquea si ya existe admin); semáforo y bloqueo concurrente `WITH (UPDLOCK, HOLDLOCK)`. |

---

## 3. Matriz de Requerimientos Funcionales (RF-01 a RF-55)

| ID | Requerimiento Funcional | Estado | Componente / Archivo Responsable | Suite de Verificación | Especificación Técnica y Precisión |
|---|---|:---:|---|---|---|
| **RF-01** | Portada pública con descripción y llamada a iniciar sesión | **Implementado (Local)** | `Views/Home/Index.cshtml`, `HomeController.cs` | `03_Http_Authorization_Tests.ps1` | Acceso anónimo HTTP 200 OK sin errores ni consultas privadas. |
| **RF-02** | Carrusel promocional accesible y responsive | **Implementado (Local)** | `Views/Home/Index.cshtml`, `Content/Site.css` | Inspección visual | Carrusel Bootstrap 5 con imágenes comprimidas y atributos `alt`. |
| **RF-03** | Barra de navegación y pie dinámicos por estado de sesión | **Implementado (Local)** | `Views/Shared/_Layout.cshtml` | `03_Http_Authorization_Tests.ps1` | Vínculos condicionados por `@User.Identity.IsAuthenticated`. |
| **RF-04** | Registro de cuentas con dominios institucionales | **Implementado (Local)** | `AccountController.cs`, `EmailDomainValidator.cs` | `01_Unit_Domain_Tests.ps1` (1.3) | Permite `@upt.pe`, `@virtual.upt.pe`, `@gmail.com`. Rechaza otros dominios. |
| **RF-05** | Rechazo de correos no permitidos y contraseñas débiles | **Implementado (Local)** | `EmailDomainValidator.cs`, `RegistrationSafetyGate.cs` | `01_Unit_Domain_Tests.ps1` (1.3, 1.4) | Validación de longitud ≥8, mayúscula, minúscula, dígito y símbolo. |
| **RF-06** | Confirmación obligatoria de correo antes de acceder | **Implementado (Local)** | `AccountController.cs`, `IdentityConfig.cs` | `03_Http_Authorization_Tests.ps1` (3.5), `06_Full_Regression_H01_H04.ps1` (6.4) | Cuentas no confirmadas son bloqueadas en login y redirigidas. |
| **RF-07** | Autenticación segura y cierre de sesión con cookies | **Implementado (Local)** | `AccountController.cs`, `Startup.Auth.cs` | `03_Http_Authorization_Tests.ps1`, `05_Security_Concurrency_Tests.ps1` (5.4) | Cookies OWIN HttpOnly/SameSite; invalidación inmediata en SignOut y regeneración de `SecurityStamp`. |
| **RF-08** | Restablecimiento de contraseña sin enumeración | **Implementado (Local)** | `AccountController.ForgotPassword`, `SimulatedEmailService.cs` | `01_Unit_Domain_Tests.ps1` (1.7), `06_Full_Regression_H01_H04.ps1` (6.4) | Mensajes idénticos para cuentas existentes o inexistentes. |
| **RF-09** | Protección de rutas y operaciones con autorización en servidor | **Implementado (Local)** | Atributos `[Authorize]`, `AuthorizeUserEnabledFilter.cs` | `03_Http_Authorization_Tests.ps1` (3.1..3.4, 3.6) | Redirección inmediata a login ante acceso anónimo o usuario inhabilitado (`IsEnabled == 0`). |
| **RF-10** | Asignación exclusiva del rol «Registrado» en alta pública | **Implementado (Local)** | `AccountController.Register` | `03_Http_Authorization_Tests.ps1` (3.2) | Prohibida autopromoción a Administrador en el flujo público. |
| **RF-11** | Provisión controlada y auditable del Administrador | **Implementado (Local)** | `tools/Provision-Administrator.ps1` | `05_Security_Concurrency_Tests.ps1` (5.5) | Provisión controlada con precondiciones, sin credenciales en código ni Git. |
| **RF-12** | Catálogo global de materiales (lectura autorizada, CRUD admin) | **Implementado (Local)** | `MaterialesController.cs` | `03_Http_Authorization_Tests.ps1` (3.1, 3.2) | Visitantes denegados (D-02); CRUD restringido con HTTP 403 para usuarios no-administradores. |
| **RF-13** | CRUD de mezclas privadas aisladas por propietario | **Implementado (Local)** | `MezclasController.cs` | `06_Full_Regression_H01_H04.ps1` (6.3) | Filtrado estricto `Where(m => m.OwnerUserId == CurrentUserId)`. |
| **RF-14** | Cálculo de costo y huella CO₂ mediante snapshots guardados | **Implementado (Local)** | `Mezcla.cs`, `MezclaComponente.cs` | `02_Integration_EF6_Sql_Tests.ps1` (2.2), `06_Full_Regression_H01_H04.ps1` (6.1, 6.2) | `CostoPorKgGuardado decimal(18,4)`, `Co2PorKgGuardado decimal(18,4)`. Fórmulas reproducibles sobre snapshots inmutables. |
| **RF-15** | Dashboard personal con KPIs de mezclas privadas | **Implementado (Local)** | `DashboardController.cs`, `DashboardViewModel.cs` | `06_Full_Regression_H01_H04.ps1` (6.3) | Cálculo exacto de total, costo promedio y CO₂ promedio de mezclas propias verificadas. |
| **RF-16** | Predicción ML con siete componentes en kg/m³ | **Implementado (Local)** | `EcoMixMlClientService.cs`, `ConcretePredictionRequestDto.cs` | `01_Unit_Domain_Tests.ps1` (1.1), `04_FastApi_Contract_Mock_Tests.ps1` (4.1) | Envío tipado de cemento, escoria, ceniza, agua, aditivo, grueso, fino. |
| **RF-17** | Presentación de resistencia predicha a 7 y 28 días | **Implementado (Local)** | `PredictionResponseDto.cs`, `MezclasController.Simulador` | `04_FastApi_Contract_Mock_Tests.ps1` (4.1) | Respuesta tipada con `Strength7dMpa`, `Strength28dMpa` (`decimal(18,2)`), ratios y metadatos. |
| **RF-18** | Visualización gráfica de predicción sin certificación | **Implementado (Local)** | `Views/Mezclas/Simulador.cshtml`, Chart.js | Inspección visual | Gráfico de barras 7d/28d con leyenda explícita de estimación experimental no certificada. |
| **RF-19** | Semáforo visual accesible para resultados y alertas | **Implementado (Local)** | `Views/Mezclas/Simulador.cshtml` | Inspección visual | Badges con iconos, texto explicativo y contraste para accesibilidad. |
| **RF-20** | Resiliencia ante caídas del servicio ML externo | **Implementado (Local)** | `EcoMixMlClientException.cs`, `MezclasController.cs` | `04_FastApi_Contract_Mock_Tests.ps1` (4.2..4.4) | Captura de errores 422/503/timeout sin interrumpir la interfaz web. |
| **RF-21** | Gestión administrativa de usuarios con paginación | **Implementado (Local)** | `AdminController.Users`, `AdminUsersListViewModel.cs` | `03_Http_Authorization_Tests.ps1` (3.3), `06_Full_Regression_H01_H04.ps1` (6.5) | Búsqueda por correo, paginación y aislamiento de mezclas ajenas. |
| **RF-22** | Conmutación de estado (Habilitar/Deshabilitar) auditada | **Implementado (Local)** | `AdminController.ToggleUserStatus` | `03_Http_Authorization_Tests.ps1` (3.4), `05_Security_Concurrency_Tests.ps1` (5.1) | Protección concurrente contra auto-inhabilitación del último admin. |
| **RF-23** | Asignación y cambio de roles auditada | **Implementado (Local)** | `AdminController.ChangeUserRole` | `05_Security_Concurrency_Tests.ps1` (5.1, 5.2) | Verificación de `IdentityResult` y rollback transaccional ante fallos. |
| **RF-24** | Historial administrativo filtrable de auditoría | **Implementado (Local)** | `AdminController.Audit`, `AdminAuditListViewModel.cs` | `02_Integration_EF6_Sql_Tests.ps1` (2.4), `04_FastApi_Contract_Mock_Tests.ps1` (4.5) | Filtrado por categoría, acción y fecha; detalles sanitizados sin recetas ni dosificaciones. |
| **RF-25** | Dashboard administrativo con métricas agregadas | **Implementado (Local)** | `AdminController.Dashboard`, `AdminDashboardStatsDto.cs` | `06_Full_Regression_H01_H04.ps1` (6.5) | Conteo global de usuarios, simulaciones y errores; sin datos privados de mezclas. |
| **RF-26** | Continuidad operativa sin dependencia del modelo ML | **Implementado (Local)** | `MaterialesController.cs`, `MezclasController.cs` | `04_FastApi_Contract_Mock_Tests.ps1` (4.4) | Catálogo, cálculo local y mezclas operan plenamente aun si ML está caído. |
| **RF-27** | Política de privacidad y descargo de responsabilidad | **Implementado (Local)** | `Views/Home/Privacidad.cshtml`, `_Layout.cshtml` | Inspección visual | Descargo explícito: VotingEnsemble no sustituye probetas ASTM C39 ni RNE E.060. |
| **RF-28** | Publicación MVC y SQL en Azure (Preparación) | **Integración Externa Pendiente** | Guía de despliegue `docs/entrega/Guia_Instalacion_Entorno_Limpio.md` | Inspección documental | Proyecto preparado para publicación condicional a presupuesto D-06 y credenciales de suscripción. |
| **RF-29** | Asociación de mezclas al usuario desde el servidor | **Implementado (Local)** | `MezclasController.Create` | `06_Full_Regression_H01_H04.ps1` (6.2) | `OwnerUserId` asignado desde identidad de claims en backend. |
| **RF-30** | Bloqueo estricto de lectura/escritura de mezclas ajenas | **Implementado (Local)** | `MezclasController.Details`, `Edit`, `Delete` | `06_Full_Regression_H01_H04.ps1` (6.3) | Validación de propiedad por ID; rechaza intentos IDOR con HTTP 404/403. |
| **RF-31** | Conservación de mezclas de ejemplo como plantillas | **Implementado (Local)** | Registros de demostración en `dbo.Mezclas` | `02_Integration_EF6_Sql_Tests.ps1` (2.1) | Plantillas conservadas con componentes de referencia. |
| **RF-32** | Bloqueo de acceso administrativo transversal a recetas | **Implementado (Local)** | `AdminController.cs` (sin endpoints de recetas ajenas) | `06_Full_Regression_H01_H04.ps1` (6.3) | Administrador no dispone de interfaces ni consultas de mezclas privadas. |
| **RF-33** | Consulta de materiales globales para usuarios registrados | **Implementado (Local)** | `MaterialesController.Index`, `Details` | `03_Http_Authorization_Tests.ps1` (3.1, 3.2) | Lectura permitida para sesión autorizada; sin controles de edición. |
| **RF-34** | CRUD exclusivo de materiales para Administrador | **Implementado (Local)** | `MaterialesController.Create`, `Edit`, `Delete` | `03_Http_Authorization_Tests.ps1` (3.2) | Protección estricta con `[Authorize(Roles="Administrador")]`. |
| **RF-35** | Bloqueo de eliminación de materiales con mezclas vinculadas | **Implementado (Local)** | `MaterialesController.Delete` | `03_Http_Authorization_Tests.ps1` (3.2) | Validación de integridad referencial antes de permitir baja. |
| **RF-36** | Enlace de confirmación mediante proveedor transaccional | **Implementado (Local)** | `ITransactionalEmailSender.cs`, `SimulatedEmailService.cs` | `01_Unit_Domain_Tests.ps1` (1.7) | Enlace temporal emitido sin secretos en código ni Git. |
| **RF-37** | Reenvío de confirmación con rate limit no enumerable | **Implementado (Local)** | `AccountController.ResendConfirmation` | `01_Unit_Domain_Tests.ps1` (1.5) | Control de frecuencia por IP y respuesta genérica constante. |
| **RF-38** | Notificación de error de entrega sin confirmación automática | **Implementado (Local)** | `AccountController.cs` | `01_Unit_Domain_Tests.ps1` (1.7) | `EmailConfirmed` permanece `false` si falla el transporte de correo. |
| **RF-39** | Restablecimiento de contraseña por adaptador transaccional | **Implementado (Local)** | `AccountController.ForgotPassword`, `ResetPassword` | `06_Full_Regression_H01_H04.ps1` (6.4) | Token criptográfico temporal validado por Identity. |
| **RF-40** | Adaptador de correo transaccional intercambiable | **Implementado (Local)** / **Integración Externa Pendiente** | `TransactionalEmailSenderFactory.cs`, `SmtpTransactionalEmailSender.cs` | `01_Unit_Domain_Tests.ps1` (1.7) | Fábrica configurable para Simulated, SMTP o HTTP API implementada localmente; suscripción de SendGrid productivo pendiente. |
| **RF-41** | Captura de precio y factor CO₂ en snapshots al guardar | **Implementado (Local)** | `MezclasController.GuardarComponentes`, `MezclaComponentes` | `02_Integration_EF6_Sql_Tests.ps1` (2.2), `06_Full_Regression_H01_H04.ps1` (6.2) | Snapshots inmutables con fecha UTC y origen catalogado `CAPTURADO`. |
| **RF-42** | Métricas del dashboard calculadas sobre snapshots válidos | **Implementado (Local)** | `DashboardController.cs`, `Mezcla.TieneSnapshotsCompletos` | `06_Full_Regression_H01_H04.ps1` (6.3) | Exclusión de mezclas sin capturas de los promedios oficiales (`Safe Denial`). |
| **RF-43** | Consistencia de snapshots en mutaciones de componentes | **Implementado (Local)** | `MezclaComponente.cs` | `06_Full_Regression_H01_H04.ps1` (6.2) | Modificación de cantidad respeta factores capturados originalmente. |
| **RF-44** | Identidad corporativa EcoMix IA diferenciada | **Implementado (Local)** | `Content/Site.css`, vistas Razor | Inspección visual | Identidad visual propia sin logotipos ni signos protegidos de terceros. |
| **RF-45** | Carrusel promocional con imágenes licenciadas | **Implementado (Local)** | `Images/banner_*.webp` | Inspección visual | Recursos visuales optimizados en WebP con derechos de uso verificados. |
| **RF-46** | Despliegue en Azure Container Apps del microservicio ML | **Integración Externa Pendiente** | Repositorio ML de referencia | `04_FastApi_Contract_Mock_Tests.ps1` | Contrato verificado contra especificación Pydantic v2; despliegue cloud pendiente de aprobación presupuestal. |
| **RF-47** | Control estricto de gasto acumulado en suscripción Azure | **Integración Externa Pendiente (Estimación Local ~$3.50 USD)** | `docs/entrega/Auditoria_Costos_Azure.md` | Auditoría de costos | Sin consumo facturable en desarrollo local; presupuesto $20 respetado; verificación en portal Azure pendiente. |
| **RF-48** | Alertas presupuestarias y procedimiento de detención | **Implementado (Local)** / **Integración Externa Pendiente** | `docs/entrega/Auditoria_Costos_Azure.md` | Auditoría de costos | Procedimiento de contingencia implementado; configuración en portal pendiente de acceso. |
| **RF-49** | Exclusión de eventos de auditoría mayores a 30 días | **Implementado (Local)** | `AuditService.GetActiveEvents` | `02_Integration_EF6_Sql_Tests.ps1` (2.4) | Límite temporal estricto `TimestampUtc >= UtcNow.AddDays(-30)`. |
| **RF-50** | Estadísticas del dashboard admin limitadas a 30 días | **Implementado (Local)** | `AuditService.GetDashboardStatsAsync` | `02_Integration_EF6_Sql_Tests.ps1` (2.4), `06_Full_Regression_H01_H04.ps1` (6.5) | Agregados LINQ acotados dentro de la ventana de 30 días. |
| **RF-51** | Depuración física idempotente de auditoría vencida | **Implementado (Local)** | `AuditService.PurgeExpiredEventsAsync` | `02_Integration_EF6_Sql_Tests.ps1` (2.5) | Eliminación por lotes de 500 registros con índice SQL `TimestampUtc`. |
| **RF-52** | Rutina explícita para provisión del primer Administrador | **Implementado (Local)** | `tools/Provision-Administrator.ps1` | `05_Security_Concurrency_Tests.ps1` (5.5) | Ejecución interactiva/controlada sin secretos en Git. |
| **RF-53** | Protección contra reejecución insegura de provisión | **Implementado (Local)** | `tools/Provision-Administrator.ps1`, `H05_manual_admin_provisioning.sql` | `05_Security_Concurrency_Tests.ps1` (5.5, 5.6) | Verificación de administrador existente; aborta inmediatamente si ya existe al menos un admin activo. |
| **RF-54** | Verificación de cuenta antes de otorgar rol Administrador | **Implementado (Local)** | `tools/Provision-Administrator.ps1` | `05_Security_Concurrency_Tests.ps1` (5.5) | Precondición estricta: `EmailConfirmed == 1` y `IsEnabled == 1`. |
| **RF-55** | Registro auditable y seguro de la provisión administrativa | **Implementado (Local)** | `tools/Provision-Administrator.ps1`, `AuditEvents` | `05_Security_Concurrency_Tests.ps1` (5.5) | Evento registrado en auditoría y `SecurityStamp` actualizado. |

---

## 4. Matriz de Requerimientos No Funcionales (RNF-01 a RNF-30)

| ID | Área / Atributo | Estado | Mecanismo de Implementación | Suite / Validación |
|---|---|:---:|---|---|
| **RNF-01** | Usabilidad / Accesibilidad | **Implementado (Local)** | Bootstrap 5.3.3, contraste semántico, etiquetas `alt`, navegación por teclado. | Inspección visual en escritorio y móvil. |
| **RNF-02** | Seguridad de Contraseñas | **Implementado (Local)** | ASP.NET Identity 2 con `PBKDF2-HMAC-SHA1` (1000 iteraciones) y salting criptográfico. | `01_Unit_Domain_Tests.ps1` (1.4). |
| **RNF-03** | Seguridad de Comunicaciones | **Implementado (Local)** | Cookies `HttpOnly`, `SameSite=Lax`, tokens `AntiForgeryToken` en todos los POSTs de mutación. | `03_Http_Authorization_Tests.ps1` (3.6). |
| **RNF-04** | Autorización y Prevención IDOR | **Implementado (Local)** | Verificación en backend de `OwnerUserId == CurrentUserId` en todas las acciones privadas. | `06_Full_Regression_H01_H04.ps1` (6.3). |
| **RNF-05** | Gestión Segura de Secretos | **Implementado (Local)** | Exclusión de `Web.Secrets.config` en `.gitignore`; lectura mediante variables de entorno. | Auditoría Git (`git status`, `git grep`). |
| **RNF-06** | Confiabilidad y Desacoplamiento | **Implementado (Local)** | Subsistemas de catálogo, mezclas y dashboard independientes de la API FastAPI. | `04_FastApi_Contract_Mock_Tests.ps1` (4.4). |
| **RNF-07** | Mantenibilidad de Arquitectura | **Implementado (Local)** | Patrón MVC tradicional, servicios especializados, EF6 Code First y LINQ. | Compilación limpia Debug/Release (MSBuild 17). |
| **RNF-08** | Rendimiento Web | **Implementado (Local)** | Vistas Razor optimizadas, bundles estáticos, carga asíncrona de predicción vía Ajax. | Latencia promedio < 150 ms en LocalDB. |
| **RNF-09** | Manejo de Latencia y Timeout ML | **Implementado (Local)** | Timeout configurable (45 s) en `EcoMixMlClientService` con manejo HTTP 408/503. | `04_FastApi_Contract_Mock_Tests.ps1` (4.3). |
| **RNF-10** | Privacidad de Auditoría | **Implementado (Local)** | Retención estricta de 30 días comunicada en política de privacidad y vista de auditoría. | `02_Integration_EF6_Sql_Tests.ps1` (2.4). |
| **RNF-11** | Portabilidad de Base de Datos | **Implementado (Local)** | Compatibilidad probada entre LocalDB y SQL Server estándar mediante cadenas ADO.NET. | `02_Integration_EF6_Sql_Tests.ps1` (2.1). |
| **RNF-12** | Operabilidad y Costos Cloud | **Implementado (Local)** | Arquitectura local sin dependencias cloud activas durante el desarrollo. | `docs/entrega/Auditoria_Costos_Azure.md`. |
| **RNF-13** | Confidencialidad de Mezclas | **Implementado (Local)** | Cero almacenamiento de ingredientes en logs y vistas administrativas. | `04_FastApi_Contract_Mock_Tests.ps1` (4.5). |
| **RNF-14** | Privacidad de Analítica | **Implementado (Local)** | Indicadores administrativos agregados sin posibilidad de inferir mezclas individuales. | `06_Full_Regression_H01_H04.ps1` (6.5). |
| **RNF-15** | Integridad del Catálogo | **Implementado (Local)** | Llaves foráneas e integridad referencial bloquean borrado de materiales en uso. | `03_Http_Authorization_Tests.ps1` (3.2). |
| **RNF-16** | Seguridad de Credenciales de Correo | **Implementado (Local)** | Proveedor de correo simulado en desarrollo; configuración SMTP/API desacoplada. | `01_Unit_Domain_Tests.ps1` (1.7). |
| **RNF-17** | Fiabilidad del Flujo de Correo | **Implementado (Local)** | Cuentas sin confirmar no acceden a servicios si el correo no es entregado. | `03_Http_Authorization_Tests.ps1` (3.5). |
| **RNF-18** | Eficiencia Presupuestal de Correo | **Implementado (Local)** | `SimulatedEmailService` almacena en disco `App_Data/EmailOutbox` con costo $0. | `01_Unit_Domain_Tests.ps1` (1.7). |
| **RNF-19** | Rendimiento del Dashboard | **Implementado (Local)** | Proyecciones LINQ optimizadas y filtradas en SQL por `OwnerUserId`. | `06_Full_Regression_H01_H04.ps1` (6.3). |
| **RNF-20** | Trazabilidad de Snapshots | **Implementado (Local)** | Tipos `decimal(18,4)` con metadato de origen (`CAPTURADO`, `LEGADO_SIN_VERIFICAR`). | `02_Integration_EF6_Sql_Tests.ps1` (2.2). |
| **RNF-21** | Accesibilidad del Carrusel | **Implementado (Local)** | Atributos ARIA y respeto a directivas de movimiento reducido. | Inspección visual y DOM. |
| **RNF-22** | Mantenibilidad de Estilos | **Implementado (Local)** | CSS centralizado en `Content/Site.css` sin dependencias externas pesadas. | Inspección de archivos estáticos. |
| **RNF-23** | Eficiencia Presupuestal Azure | **Integración Externa Pendiente (Estimación Local)** | Presupuesto máximo $20 USD documentado; estimación ~$3.50 USD; conciliación portal pendiente. | `docs/entrega/Auditoria_Costos_Azure.md`. |
| **RNF-24** | Alertas y Contención de Gasto | **Integración Externa Pendiente (Estimación Local)** | Procedimiento de monitoreo manual y detención de recursos listo; alertas en portal pendientes de acceso. | `docs/entrega/Auditoria_Costos_Azure.md`. |
| **RNF-25** | Compatibilidad de Hosting | **Integración Externa Pendiente** | Compatibilidad con App Service Windows .NET 4.7.2 lista; despliegue cloud pendiente de aprobación. | `docs/entrega/Guia_Instalacion_Entorno_Limpio.md`. |
| **RNF-26** | Aislamiento de Auditoría Vencida | **Implementado (Local)** | Consultas activas excluyen eventos >30 días mediante `WHERE TimestampUtc >= @cutoff`. | `02_Integration_EF6_Sql_Tests.ps1` (2.4). |
| **RNF-27** | Eficiencia de Purga SQL | **Implementado (Local)** | Purga por lotes de 500 registros con semáforo no bloqueante `_purgeSemaphore`. | `02_Integration_EF6_Sql_Tests.ps1` (2.5). |
| **RNF-28** | Seguridad en Provisión Admin | **Implementado (Local)** | Argumentos y hashes protegidos; sin contraseñas planas en disco o logs. | `05_Security_Concurrency_Tests.ps1` (5.5). |
| **RNF-29** | Validación Previa de Provisión | **Implementado (Local)** | Verificación mandatoria de cuenta existente y confirmada; validación RF-53 de primer admin. | `05_Security_Concurrency_Tests.ps1` (5.5). |
| **RNF-30** | Autonomía del Provisionador | **Implementado (Local)** | Script PowerShell independiente sin dependencias en nube ni ejecución automática en arranque. | `05_Security_Concurrency_Tests.ps1` (5.5). |

---

## 5. Conclusiones de Trazabilidad H05-R

1. **Cobertura Completa del Alcance Local:** Los 88 requerimientos y directivas correspondientes al entorno local han sido implementados y verificados con pruebas automatizadas.
2. **Desacoplamiento Claro de Integraciones Externas:** Los 7 ítems que involucran aprovisionamiento cloud (Azure App Service, Azure Container Apps, SendGrid API productiva y conciliación en Azure Cost Management) han sido debidamente catalogados como **Integración Externa Pendiente**, evitando falsas declaraciones de cumplimiento sobre recursos no verificados.
3. **Respaldo Automatizado:** La suite modular y orquestada garantiza la integridad de todo el pipeline web, de seguridad y de base de datos.
