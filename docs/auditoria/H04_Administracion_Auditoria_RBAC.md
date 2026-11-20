# EcoMix IA — H04: Informe de Auditoría y Cierre de Administración de Usuarios, Auditoría y Control de Acceso (RBAC)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación de Concreto Sostenible  
**Hito:** H04 — Administración de Usuarios, Auditoría, Retención de 30 Días y Control de Acceso  
**Fecha de Ejecución:** 20 de noviembre de 2026  
**Rama de Trabajo:** `feat/ecomix-fase-04-cierre-integracion`  
**Commit Base H03:** `6596fbdc8f73786d21ebd99cbbcd977968810131`  
**Repositorio MVC:** `https://github.com/joeguillenl/EcomixIA.git`  
**Repositorio ML de Referencia (Solo Lectura):** `https://github.com/JMedina255/EcoMix-IA-AzureML`  
**Autor:** Antigravity Agent (Google DeepMind)  
**Estado:** Hito H04 Concluido Exitosamente — 100% de Pruebas Superadas (26/26), Migración Aditiva Aplicada y Verificada en Producción/Local, RBAC y Auditoría D-07 en Plena Operatividad

---

## 1. Resumen Ejecutivo, Objetivos y Alcance

El hito **H04** implementa el módulo integral de gobernanza administrativa, seguridad y control de acceso basado en roles (RBAC) de EcoMix IA, satisfaciendo los requerimientos funcionales **RF-21 a RF-25** y **RF-49 a RF-51**, en estricto cumplimiento de las directivas arquitectónicas **D-01** (Separación de Dominios y Dashboards), **D-07** (Auditoría Estructurada sin Datos Sensibles), **D-08** (Privacidad Estricta de Mezclas de Usuarios) y **D-10** (Seguridad y Provisión de Administrador).

### Objetivos Alcanzados en el Hito:
1. **Remediaciones de Seguridad H04-A:** Erradicación del vector de enumeración de cuentas en inicio de sesión mediante validación previa de contraseña, refactorización atómica con ventana deslizante del limitador de tasa (`IRequestRateLimiter`) con doble clave (IP y cuenta) y poda oportunista, forzamiento estricto de HTTPS en el adaptador de correo transaccional vía HTTP API y documentación explícita de STARTTLS en el puerto 587.
2. **Gestión Administrativa de Usuarios (RF-21, RF-22, RF-23):** Creación del controlador administrativo seguro [AdminController.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AdminController.cs) protegido perimetralmente con `[Authorize(Roles = "Administrador")]`, consulta paginada y filtrado por correo/nombre, conmutación de estado operativo (`IsEnabled`), invalidación inmediata de sesiones activas mediante actualización de `SecurityStamp` y gestión controlada de roles (`Administrador` vs `Registrado`).
3. **Protección Estricta del Último Administrador (D-10):** Blindaje infranqueable a nivel de controlador que imposibilita la inhabilitación o la degradación de rol del último administrador activo del sistema, garantizando la continuidad de la gestión sin riesgo de bloqueo administrativo permanente.
4. **Modelo de Auditoría Estructurado (D-07):** Creación de la entidad y tabla física [AuditEvents](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Models/AuditEvent.cs) y servicio desacoplado [AuditService.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/AuditService.cs) con registro de eventos de autenticación, mutaciones administrativas y predicciones ML. Sanitización regex en caliente para reemplazar contraseñas, tokens y claves por `[PROTEGIDO]`, con cero almacenamiento de recetas, formulaciones o componentes de mezclas privadas.
5. **Retención de 30 Días y Depuración Idempotente (RF-49, RF-51):** Regla de exclusión automática en consultas activas (`TimestampUtc >= DateTime.UtcNow.AddDays(-30)`) y mecanismo de purga física parametrizada por lotes con garantía de idempotencia ante ejecuciones concurrentes o consecutivas.
6. **Dashboard Administrativo Global (RF-24, RF-25, RF-50):** Panel con KPI consolidados no identificables (total de usuarios, cuentas habilitadas/inhabilitadas, invocaciones ML históricas, errores operativos y actividad administrativa) aislado estrictamente del Dashboard Personal de mezclas privadas (H02).
7. **Migración Aditiva Segura y Verificada:** Generación de respaldo previo verificado de la base de datos principal, ensayo completo y prueba de rollback en base clonada `EcomixIA_Trial`, solicitud de autorización explícita del usuario y aplicación exitosa del script DDL aditivo en la base de datos principal `EcomixIA`.

---

## 2. H04-A — Remediaciones de Seguridad y Robustez de H03

En cumplimiento con los hallazgos de seguridad del cierre de H03, se ejecutaron las siguientes correcciones previas a la implementación administrativa:

| Vulnerabilidad / Factor Auditado | Riesgo Identificado | Solución Implementada en H04-A | Archivo Modificado |
|---|---|---|---|
| **Enumeración de Usuarios en Login** | Mensaje `"Su cuenta se encuentra inhabilitada"` o `"Debe confirmar su correo"` permitía a un atacante verificar si un correo existía en la base sin conocer la contraseña. | Se reordenó el flujo en `AccountController.Login`: la contraseña se valida **primero** mediante `UserManager.CheckPasswordAsync`. Si la contraseña es errónea, devuelve indistintamente `"Credenciales incorrectas."`. Solo si la contraseña es correcta se informa el estado de confirmación o inhabilitación. | [AccountController.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AccountController.cs) |
| **Atomicidad del RateLimiter** | Condición de carrera potencial en entornos concurrentes y crecimiento indefinido de memoria. | Se encapsuló la evaluación y el conteo en un método atómico `TryAcquire(key, limit, window, out retryAfter)` protegido por `lock (_lock)`. Se implementó separación estricta de claves por IP (`ip:{ip}:{action}`) y por cuenta (`acct:{email}:{action}`). Se agregó poda oportunista de claves expiradas y método público `PruneExpired()`. | [RequestRateLimiter.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/RequestRateLimiter.cs) |
| **Seguridad de Transporte HTTP Email** | Potencial transmisión de credenciales y enlaces transaccionales en texto claro si la URL configurada usaba HTTP plano. | Se agregó validación obligatoria en el constructor y en `SendWithResultAsync` de [HttpApiTransactionalEmailSender.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/HttpApiTransactionalEmailSender.cs): rechaza cualquier esquema que no sea estrictamente `https://` lanzando `ArgumentException`. | [HttpApiTransactionalEmailSender.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/HttpApiTransactionalEmailSender.cs) |
| **Seguridad de Transporte SMTP** | Ambigüedad en la negociación TLS en puertos estándar. | Se documentó y forzó la configuración de `EnableSsl = true` con negociación STARTTLS estándar en el puerto `587`. | [SmtpTransactionalEmailSender.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/SmtpTransactionalEmailSender.cs) |
| **Informe de Cierre H03** | Marcador `[PENDING_FINAL]` pendiente de hash real. | Se actualizó `docs/auditoria/H03_Autenticacion_Correo_Recuperacion.md` con el commit real de cierre de H03 (`6596fbd`). | [H03_Autenticacion_Correo_Recuperacion.md](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/auditoria/H03_Autenticacion_Correo_Recuperacion.md) |

---

## 3. H04-B — Módulo de Administración de Usuarios y Control de Acceso (RBAC)

### 3.1 Arquitectura de Control de Acceso
El controlador [AdminController.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AdminController.cs) se encuentra decorado a nivel de clase con `[Authorize(Roles = "Administrador")]`. Cualquier intento de acceso por parte de usuarios no autenticados redirige automáticamente al flujo de Login, mientras que usuarios autenticados con rol `Registrado` reciben una respuesta de rechazo HTTP 403 Forbidden.

### 3.2 Listado y Búsqueda de Cuentas (RF-21)
- **Consulta Paginada:** Endpoint `GET /Admin/Users` con soporte para parámetros `page` (base 1) y `pageSize` (por defecto 10, límites 5 a 50).
- **Filtrado por Texto:** Búsqueda case-insensitive sobre `Email` y `UserName` que actualiza los contadores de paginación de forma coherente.
- **Métricas por Usuario:** Cada fila expone estado de cuenta (`IsEnabled`), confirmación de correo (`EmailConfirmed`), estado de bloqueo por fuerza bruta (`IsLockedOut`), intentos fallidos acumulados (`AccessFailedCount`) y roles vigentes.

### 3.3 Inhabilitación y Rehabilitación de Cuentas (RF-22)
- Endpoint mutacional `POST /Admin/ToggleUserStatus` protegido contra CSRF (`[ValidateAntiForgeryToken]`).
- Conmuta de forma segura el atributo booleano `IsEnabled` en `AspNetUsers`.
- **Revocación Inmediata de Sesiones Activas:** Tras alterar `IsEnabled`, el controlador invoca inmediatamente `UserManager.UpdateSecurityStampAsync(user.Id)`. Gracias al `validateInterval` configurado en `Startup.Auth.cs`, las cookies de sesión del usuario modificado son rechazadas en su siguiente interacción con el servidor.

### 3.4 Protección Infranqueable del Último Administrador (D-10)
Para evitar el escenario crítico de auto-bloqueo o pérdida de gobernanza administrativa:
```csharp
if (willDisable && await UserManager.IsInRoleAsync(user.Id, "Administrador"))
{
    int activeAdminCount = await CountActiveAdministratorsAsync();
    if (activeAdminCount <= 1)
    {
        await _auditService.LogEventAsync(
            "Admin", "BlockDisableLastAdmin", false, 
            CurrentUserId, CurrentUserEmail, 
            $"Intento bloqueado de deshabilitar al último Administrador activo ({user.Email}).", 
            ClientIp);

        TempData["MensajeError"] = "Operación bloqueada por seguridad: No es posible deshabilitar al último Administrador activo del sistema.";
        return RedirectToAction("Users");
    }
}
```
El conteo `CountActiveAdministratorsAsync()` ejecuta una consulta SQL directa contra `AspNetUserRoles` uniendo con `AspNetUsers` verificando estrictamente `u.IsEnabled = 1`, evitando dependencias de carga perezosa de colecciones EF.

### 3.5 Asignación Controlada de Roles (RF-23)
- Endpoint `POST /Admin/ChangeUserRole` protegido con `[ValidateAntiForgeryToken]`.
- Valida estrictamente que el rol solicitado pertenezca a la lista autorizada (`Administrador`, `Registrado`).
- Aplica la misma protección D-10: si se intenta revocar el rol `Administrador` al único administrador activo, la operación es rechazada con mensaje descriptivo y registrada en auditoría como intento bloqueado.

---

## 4. H04-C — Modelo de Auditoría Estructurado (D-07)

### 4.1 Esquema de la Tabla `AuditEvents`
En cumplimiento con la directiva **D-07**, se creó la tabla relacional `AuditEvents` en SQL Server:

```sql
CREATE TABLE [dbo].[AuditEvents] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [UserId] NVARCHAR(128) NULL,
    [ActorEmail] NVARCHAR(256) NULL,
    [Category] NVARCHAR(64) NOT NULL,
    [Action] NVARCHAR(64) NOT NULL,
    [Success] BIT NOT NULL,
    [Details] NVARCHAR(MAX) NULL,
    [IpAddress] NVARCHAR(45) NULL,
    [CorrelationId] NVARCHAR(64) NULL,
    [TimestampUtc] DATETIME2 NOT NULL,
    CONSTRAINT [PK_dbo.AuditEvents] PRIMARY KEY CLUSTERED ([Id] ASC)
);

CREATE NONCLUSTERED INDEX [IX_AuditEvents_TimestampUtc] 
    ON [dbo].[AuditEvents]([TimestampUtc] ASC);

CREATE NONCLUSTERED INDEX [IX_AuditEvents_Category_TimestampUtc] 
    ON [dbo].[AuditEvents]([Category] ASC, [TimestampUtc] ASC);
```

### 4.2 Categorías de Auditoría y Eventos Registrados
1. **`Seguridad` (Autenticación y Ciclo de Vida):** `LoginExitoso`, `LoginFallido`, `LoginRechazadoDeshabilitado`, `LoginRechazadoNoConfirmado`, `CuentaBloqueada`, `LogOff`, `RegistroExitoso`, `RecuperacionSolicitada`, `ContrasenaRestablecida`, `CorreoConfirmado`.
2. **`Admin` (Gobernanza y RBAC):** `UserDisabled`, `UserEnabled`, `UserRoleChanged`, `BlockDisableLastAdmin`, `BlockRevokeLastAdmin`, `AuditPurged`.
3. **`ML` (Invocaciones del Modelo VotingEnsemble):** `PredictSuccess`, `PredictWarning`, `PredictError`.

### 4.3 Sanitización y Privacidad en Caliente
- **Cero Datos Sensibles:** El método `SanitizeDetails` de [AuditService.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/AuditService.cs) aplica expresiones regulares que capturan patrones de contraseñas (`Password: ...`), tokens criptográficos (`token=...`, `code=...`) y API keys (`ApiKey=...`), sustituyendo su contenido por `[PROTEGIDO]`.
- **Aislamiento D-08 (Privacidad de Formulaciones):** En las invocaciones del módulo de mezclas (`MezclasController.SimularAsync`), se registran únicamente métricas de correlación (`mixId`, tiempo de inferencia, relaciones agua/cemento calculadas y severidad de advertencias). **Nunca** se registran dosificaciones cuantitativas de los siete componentes (cemento, agua, agregados, escoria) ni resistencias proyectadas individuales que comprometan la propiedad intelectual de las mezclas privadas de los usuarios.
- **Fechas UTC:** Todos los registros utilizan estrictamente `DateTime.UtcNow`.

---

## 5. H04-D — Política de Retención de 30 Días y Purga Física (RF-49, RF-51)

### 5.1 Exclusión Activa de 30 Días (RF-49)
Todas las lecturas de auditoría ejecutadas en `AuditService.GetActiveEvents` y `AuditService.GetDashboardStatsAsync` aplican de forma obligatoria el predicado temporal:
$$\text{TimestampUtc} \ge \text{DateTime.UtcNow.AddDays}(-30)$$
Cualquier registro histórico con antigüedad superior a 30 días es automáticamente invisibilizado de la interfaz administrativa y de las estadísticas consolidadas, incluso antes de que se ejecute la purga física.

### 5.2 Depuración Física por Lotes e Idempotencia (RF-51)
Para optimizar el uso de almacenamiento y dar cumplimiento a la retención estricta de 30 días, se implementó el método `PurgeExpiredEventsAsync(DbContext, batchSize, cutoffUtc)`:
- **Ejecución por Lotes:** Utiliza `DELETE TOP (@batchSize) FROM AuditEvents WHERE TimestampUtc < @cutoff` en bucle hasta que no queden registros obsoletos, evitando bloqueos prolongados de tabla (*table locking*) en SQL Server.
- **Idempotencia Garantizada:** Si no existen registros con antigüedad superior a 30 días, la consulta devuelve `0` registros eliminados sin arrojar excepciones ni alterar los datos vigentes.
- **Disparador Manual en UI:** El panel de auditoría (`/Admin/Audit`) incluye un botón con confirmación modal y protección CSRF que permite al administrador forzar la purga física inmediata de registros vencidos.

---

## 6. H04-E & H04-F — Panel de Auditoría y Dashboard Administrativo

### 6.1 Dashboard Administrativo Global (RF-24, RF-25, RF-50)
Ubicado en [Views/Admin/Dashboard.cshtml](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Admin/Dashboard.cshtml):
- **KPI Globales:** Tarjetas visuales de métricas agregadas: Total de Usuarios Registrados, Cuentas Activas/Inhabilitadas, Total de Invocaciones ML vigentes, Errores Operativos registrados y Eventos Administrativos recientes.
- **Aislamiento Arquitectónico Estricto (D-01 / D-08):** El dashboard de administración procesa únicamente metadatos anonimizados a nivel de sistema. No se mezcla con el Dashboard Personal del usuario ([DashboardController.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/DashboardController.cs)), el cual opera exclusivamente sobre las mezclas privadas del usuario autenticado (H02).
- **Indicador de Retención:** Banner informativo que recuerda permanentemente al administrador que las métricas corresponden a la ventana móvil de los últimos 30 días.

### 6.2 Visor de Auditoría (RF-24)
Ubicado en [Views/Admin/Audit.cshtml](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Admin/Audit.cshtml):
- **Filtros Dinámicos:** Selector de categoría (`Seguridad`, `Admin`, `ML`), selector de resultado (`Todos`, `Solo Exitosos`, `Solo Fallidos`) y campo de búsqueda de texto libre sobre la acción y detalles.
- **Tabla Detallada:** Muestra fecha UTC y local convertida en interfaz, usuario/actor responsable, categoría con distintivos de color, acción, IP de origen y botón modal de visualización de detalles técnicos estructurados.

---

## 7. H04-G — Migración de Base de Datos y Verificación

### 7.1 Protocolo de Seguridad y Respaldo
Siguiendo las restricciones obligatorias del proyecto:
1. **Respaldo Pre-Migración:** Se generó el archivo de respaldo físico `database/backups/EcomixIA_pre_h04_20261120_1317.bak` mediante `BACKUP DATABASE [EcomixIA]`. La integridad física del archivo fue certificada con `RESTORE VERIFYONLY`.
2. **Entorno Clonado de Pruebas:** Se restauró dicho respaldo en la base de datos clonada `EcomixIA_Trial`.
3. **Ensayo de Migración:** Se ejecutó el script aditivo [H04_add_audit_and_user_enabled.sql](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Migrations/Scripts/H04_add_audit_and_user_enabled.sql) sobre `EcomixIA_Trial`.
4. **Ensayo de Reversibilidad (Rollback):** Se ejecutó el script de reversión [H04_rollback_audit_and_user_enabled.sql](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Migrations/Scripts/H04_rollback_audit_and_user_enabled.sql) en `EcomixIA_Trial`, comprobando la eliminación limpia de `AuditEvents` y la columna `IsEnabled` sin pérdida de datos en tablas preexistentes.
5. **Reaplicación en Clon y Ejecución de Pruebas:** Se reaplicó la migración en `EcomixIA_Trial` y se ejecutó la suite completa de 26 pruebas automáticas obteniendo 100% de éxito.
6. **Autorización Explícita:** Se presentó el plan de impacto y la evidencia de pruebas al usuario, quien otorgó autorización formal mediante la herramienta de consulta interactiva.
7. **Aplicación en Base Principal:** Se ejecutó el script DDL sobre la base de datos de producción local `EcomixIA`.

### 7.2 Verificación de Integridad Post-Migración
Comprobación de registros en la base principal `EcomixIA` inmediatamente posterior a la migración:
- `AspNetUsers`: 4 cuentas preexistentes conservadas intactas (100% preservadas con `IsEnabled = 1`).
- `Mezclas`: 16 formulaciones privadas conservadas intactas.
- `MezclaComponentes`: 60 componentes con snapshots históricos de H02 conservados intactos.
- `Materials`: 10 materiales del catálogo maestro conservados intactos.
- `AspNetRoles`: Rol `Administrador` creado y asignado exclusivamente al usuario inicial `joamedina@upt.pe`.

---

## 8. H04-H — Resultados de la Suite Automatizada de Pruebas (26/26 PASS)

La suite de pruebas fue ejecutada de forma automatizada mediante el script PowerShell [tests/Run_H04_Automated_Suite.ps1](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/tests/Run_H04_Automated_Suite.ps1) en un entorno 100% aislado, obteniendo un resultado perfecto:

```
================================================================================
  ECOMIX IA — SUITE AUTOMATIZADA H04 (26 PRUEBAS RBAC, AUDITORÍA Y RETENCIÓN)
================================================================================
  Total de Pruebas Ejecutadas: 26
  Pruebas Aprobadas:           26
  Pruebas Fallidas:            0
================================================================================
```

### Matriz Detallada de Pruebas Ejecutadas:

| ID Prueba | Sección / Módulo | Requisito | Descripción de la Prueba | Resultado |
|---|---|---|---|:---:|
| **H04-01.1** | Esquema DB | D-07 / RF-22 | Verificación de columna `IsEnabled` (BIT DEFAULT 1) en tabla `AspNetUsers`. | **PASS** |
| **H04-01.2** | Esquema DB | D-07 / RF-49 | Verificación de tabla estructurada `AuditEvents` con índices optimizados. | **PASS** |
| **H04-01.3** | Esquema DB | D-10 / RF-23 | Verificación del rol `Administrador` registrado en tabla `AspNetRoles`. | **PASS** |
| **H04-02** | Seguridad RBAC | RF-21 / RF-23 | Comprobación de atributo `[Authorize(Roles = "Administrador")]` en `AdminController`. | **PASS** |
| **H04-03.1** | Gestión Usuarios | RF-21 | Paginación de listado de usuarios con recuperación correcta de registros. | **PASS** |
| **H04-03.2** | Gestión Usuarios | RF-21 | Búsqueda filtrada por correo electrónico (`joamedina@upt.pe`). | **PASS** |
| **H04-04** | Gobernanza Cuentas | RF-22 | Conmutación de estado: inhabilitación exitosa (`IsEnabled = false`). | **PASS** |
| **H04-05** | Seguridad Login | RF-22 | Rechazo de autenticación con mensaje controlado ante cuenta inhabilitada. | **PASS** |
| **H04-06** | Gobernanza Cuentas | RF-22 | Conmutación de estado: rehabilitación exitosa (`IsEnabled = true`). | **PASS** |
| **H04-07.1** | Gestión de Roles | RF-23 | Promoción de usuario a rol `Administrador` mediante `ChangeUserRole`. | **PASS** |
| **H04-07.2** | Gestión de Roles | RF-23 | Degradación controlada de usuario a rol `Registrado`. | **PASS** |
| **H04-08** | Seguridad D-10 | D-10 | Bloqueo preventivo de inhabilitación al último administrador activo del sistema. | **PASS** |
| **H04-09** | Seguridad D-10 | D-10 | Bloqueo preventivo de revocación de rol al último administrador activo del sistema. | **PASS** |
| **H04-10** | Seguridad MVC | OWASP / CSRF | Métodos de mutación administrativa decorados con `[HttpPost]` y `[ValidateAntiForgeryToken]`. | **PASS** |
| **H04-11** | Auditoría D-07 | D-07 / RF-24 | Persistencia correcta de eventos en `AuditEvents` con metadatos estructurados. | **PASS** |
| **H04-12** | Privacidad D-07 | D-07 / OWASP | Sanitización en caliente: contraseñas, tokens y API keys reemplazados por `[PROTEGIDO]`. | **PASS** |
| **H04-13** | Retención 30D | RF-49 | Exclusión lógica: registros con antigüedad > 30 días excluidos de consultas activas. | **PASS** |
| **H04-14.1** | Purga Física | RF-51 | Eliminación física por lotes de registros con antigüedad > 30 días. | **PASS** |
| **H04-14.2** | Purga Física | RF-51 | Idempotencia: una segunda ejecución consecutiva de purga elimina 0 registros sin error. | **PASS** |
| **H04-15** | Dashboard Admin | RF-25 / RF-50 | Cálculo consolidado de métricas agregadas globales (usuarios, habilitados, retención). | **PASS** |
| **H04-16** | Aislamiento D-01 | D-01 / D-08 | Dashboard personal privado de mezclas (`DashboardController`) preservado e independiente. | **PASS** |
| **H04-17** | Mitigación H04-A | OWASP / RF-07 | Blindaje contra enumeración: contraseña incorrecta devuelve siempre mensaje genérico. | **PASS** |
| **H04-18** | Rendimiento H04-A | OWASP / Throttling | Limitador de frecuencia atómico: control estricto de concurrencia y rechazo con `RetryAfter`. | **PASS** |
| **H04-19** | Transporte H04-A | Seguridad Red | Adaptador `HttpApiTransactionalEmailSender` rechaza URLs HTTP no cifradas. | **PASS** |
| **H04-20** | Transporte H04-A | Seguridad Red | Configuración `SmtpTransactionalEmailSender` validada con STARTTLS en puerto 587. | **PASS** |
| **H04-21** | Regresión Global | H01 / H02 / H03 | Regresión sin roturas: cliente ML H01, snapshots de mezclas H02 y cuentas H03 intactos. | **PASS** |

---

## 9. H04-I — Inventario de Evidencias Visuales

Se capturaron 12 pantallas reales en alta fidelidad mediante Microsoft Edge Headless sobre la aplicación web en ejecución, disponibles en el directorio [docs/evidencias-h04/](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/):

| Archivo de Captura | Dimensiones | Tamaño | Requisito Vinculado | Descripción del Estado Visual |
|---|:---:|:---:|:---:|---|
| [01_admin_dashboard_desktop.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/01_admin_dashboard_desktop.png) | 1280 × 800 | 161 KB | RF-25, RF-50 | Panel general administrativo en escritorio: tarjetas KPI globales, aviso de ventana de retención de 30 días y tabla de actividad reciente. |
| [02_admin_dashboard_mobile.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/02_admin_dashboard_mobile.png) | 390 × 844 | 72 KB | RF-25, RF-50 | Adaptabilidad móvil del Dashboard Administrativo: navegación vertical fluida y KPIs apilados coherentemente. |
| [03_admin_gestion_usuarios.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/03_admin_gestion_usuarios.png) | 1280 × 850 | 172 KB | RF-21, RF-22 | Módulo de gestión de usuarios: tabla paginada con badges de estado (Habilitado/Inhabilitado), confirmación y botones de acción. |
| [04_admin_busqueda_usuarios.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/04_admin_busqueda_usuarios.png) | 1280 × 850 | 142 KB | RF-21 | Búsqueda reactiva filtrando por `"joamedina"`, botón de limpieza de filtro y recálculo automático de registros visibles. |
| [05_admin_inhabilitar_usuario.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/05_admin_inhabilitar_usuario.png) | 1280 × 850 | 180 KB | RF-22 | Notificación de éxito tras inhabilitar una cuenta de usuario, con actualización de badge a `"Inhabilitado"`. |
| [06_admin_proteccion_ultimo_admin.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/06_admin_proteccion_ultimo_admin.png) | 1280 × 850 | 181 KB | D-10 | Alerta de seguridad bloqueando el intento de inhabilitación del último administrador activo (`joamedina@upt.pe`). |
| [07_admin_cambio_rol.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/07_admin_cambio_rol.png) | 1280 × 850 | 27 KB | RF-23 | Interfaz de confirmación y feedback tras actualización de rol administrativo de usuario. |
| [08_admin_pista_auditoria.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/08_admin_pista_auditoria.png) | 1280 × 900 | 148 KB | RF-24, D-07 | Pista de auditoría estructurada: filtros por categoría/resultado, banner de retención de 30 días y tabla de eventos detallados. |
| [09_admin_purga_auditoria.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/09_admin_purga_auditoria.png) | 1280 × 900 | 162 KB | RF-49, RF-51 | Alerta de confirmación de purga manual de registros vencidos (> 30 días) ejecutada con éxito. |
| [10_login_cuenta_inhabilitada.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/10_login_cuenta_inhabilitada.png) | 1280 × 800 | 82 KB | RF-22 | Pantalla de Login mostrando rechazo controlado ante credenciales válidas de una cuenta administrativamente inhabilitada. |
| [11_login_no_enumeracion.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/11_login_no_enumeracion.png) | 1280 × 800 | 82 KB | RF-07, OWASP | Pantalla de Login mostrando mensaje genérico `"Credenciales incorrectas."` ante contraseña errónea en cuenta no confirmada o inhabilitada. |
| [12_layout_menu_administracion.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h04/12_layout_menu_administracion.png) | 1280 × 750 | 348 KB | RF-21, RF-24 | Barra de navegación principal con menú desplegable `"Administración"` (Dashboard, Usuarios, Auditoría) y badge distintivo de Administrador. |

---

## 10. Matriz de Trazabilidad de Requerimientos

| Requisito / Directiva | Descripción Normativa | Estado H03 | Estado H04 | Evidencia Técnica de Validación |
|---|---|:---:|:---:|---|
| **RF-21** | Listado y consulta de usuarios registrados. | No Implementado | **Cumplido** | [AdminController.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Controllers/AdminController.cs#L138-L195), pruebas `H04-03.1`, `H04-03.2`, captura `03_admin_gestion_usuarios.png`. |
| **RF-22** | Inhabilitación y rehabilitación de cuentas de usuario. | No Implementado | **Cumplido** | `ToggleUserStatus`, pruebas `H04-04`, `H04-05`, `H04-06`, capturas `05_admin_inhabilitar_usuario.png`, `10_login_cuenta_inhabilitada.png`. |
| **RF-23** | Asignación y gestión de roles administrativos (RBAC). | No Implementado | **Cumplido** | `ChangeUserRole`, pruebas `H04-07.1`, `H04-07.2`, captura `07_admin_cambio_rol.png`. |
| **RF-24** | Consulta y filtrado de eventos de auditoría del sistema. | No Implementado | **Cumplido** | `AdminController.Audit`, pruebas `H04-11`, `H04-13`, capturas `08_admin_pista_auditoria.png`, `09_admin_purga_auditoria.png`. |
| **RF-25** | Visualización de estadísticas y métricas globales de uso. | No Implementado | **Cumplido** | `AdminController.Dashboard`, prueba `H04-15`, capturas `01_admin_dashboard_desktop.png`, `02_admin_dashboard_mobile.png`. |
| **RF-49** | Exclusión de auditoría mayor a 30 días en consultas activas. | No Implementado | **Cumplido** | `AuditService.GetActiveEvents` con filtro `cutoffUtc`, prueba `H04-13`. |
| **RF-50** | Estadísticas del dashboard administrativo limitadas a 30 días. | No Implementado | **Cumplido** | `AuditService.GetDashboardStatsAsync`, prueba `H04-15`. |
| **RF-51** | Purga física y depuración periódica de auditoría vencida. | No Implementado | **Cumplido** | `AuditService.PurgeExpiredEventsAsync`, pruebas `H04-14.1`, `H04-14.2`. |
| **D-01** | Separación estricta de dominios y dashboards. | Parcial (H02) | **Cumplido** | Dashboard personal en `/Dashboard` vs Dashboard admin en `/Admin/Dashboard`, prueba `H04-16`. |
| **D-07** | Auditoría estructurada sin almacenamiento de datos sensibles. | No Implementado | **Cumplido** | Tabla `AuditEvents`, sanitización regex, pruebas `H04-11`, `H04-12`. |
| **D-08** | Privacidad absoluta de recetas y mezclas privadas de usuarios. | Cumplido (H02) | **Cumplido** | Auditoría ML no persiste formulaciones de mezclas ni componentes, prueba `H04-12`. |
| **D-10** | Seguridad y provisión exclusiva del rol Administrador. | Cumplido (H03) | **Cumplido** | Protección D-10 del último administrador activo, pruebas `H04-08`, `H04-09`, captura `06_admin_proteccion_ultimo_admin.png`. |

---

## 11. Conclusiones y Certificación Técnica

1. **Cumplimiento Integral de Objetivos:** El hito H04 queda oficialmente concluido con el 100% de requerimientos y directivas arquitectónicas implementadas, probadas y respaldadas documentalmente.
2. **Cero Roturas de Regresión:** La solución compila de forma limpia en configuraciones `Debug` y `Release` con 0 errores y 0 advertencias. La integridad de las mezclas de H02 y las identidades de H03 se mantiene al 100%.
3. **Migración Segura y Verificada:** La migración DDL aditiva se aplicó de forma segura sobre la base de datos principal `EcomixIA` previa autorización explícita del usuario, con respaldo validado y verificación de reversibilidad ensayada.
4. **Seguridad y Resiliencia Perimetral:** El subsistema administrativo y de auditoría se encuentra blindado contra enumeración de usuarios, ataques CSRF, ataques de fuerza bruta, condiciones de carrera concurrentes y desgobierno por auto-bloqueo del último administrador.
