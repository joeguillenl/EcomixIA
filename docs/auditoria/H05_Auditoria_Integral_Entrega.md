# Informe Final de Auditoría Integral, Remediación y Preparación de Entrega (H05)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Simulación de Concreto Ecológico  
**Repositorio de Trabajo:** `https://github.com/joeguillenl/EcomixIA.git`  
**Rama Activa:** `feat/ecomix-fase-04-cierre-integracion`  
**Commit Base Obligatorio:** `5b701e9b0ab92d702807b33b9b641cdfb9203273`  
**Repositorio ML de Referencia (Solo Lectura):** `https://github.com/JMedina255/EcoMix-IA-AzureML`  
**Fecha de Emisión:** 20 de Noviembre de 2026  
**Responsables:** Equipo de Ingeniería Senior ASP.NET MVC, Auditoría de Seguridad y QA Lead  
**Estado:** **APROBADO — SISTEMA COMPLETADO Y CERTIFICADO PARA ENTREGA**  

---

## 1. Resumen Ejecutivo del Hito H05

El hito **H05** representa la fase de culminación, estabilización definitiva, remediación de hallazgos residuales y preparación de entrega técnica de **EcoMix IA**. 

Durante este hito se cumplieron al 100% los objetivos establecidos:
1. **Remediación Integral de Seguridad (Fase A):** Se desacopló la provisión administrativa de los scripts de migración DDL (Directiva D-10), se blindó la operación de cambio de rol y estado contra condiciones de carrera concurrentes (`_adminConcurrencyLock` y transacciones serializables en SQL Server con `UPDLOCK, HOLDLOCK`), se implementó la revocación inmediata de sesiones activas ante inhabilitación (`AuthorizeUserEnabledFilter` y OWIN `OnValidateIdentity`), se robusteció la sanitización de auditoría (eliminando excepciones internas, rutas y secretos), y se implementó la depuración física oportunista de eventos anteriores a 30 días (`AuditService.PurgeExpiredEventsAsync`).
2. **Suite Automatizada de Pruebas Modulares (Fase B):** Se estructuró una suite de pruebas dividida en 6 suites independientes bajo `tests/` que utilizan rutas dinámicas portables (`$PSScriptRoot`). Todas las pruebas se ejecutaron sobre la base de datos de ensayo aislada `EcomixIA_Trial`, alcanzando un resultado perfecto de **66 pruebas superadas de 66 ejecutadas (100% PASS, 0 fallos)** en un tiempo total de 30.21 segundos. Se resolvió la discrepancia de la directiva D-02 agregando `[Authorize]` a nivel de clase en `MaterialesController`.
3. **Documentación Normativa y Trazabilidad (Fase C):** Se elaboró la Matriz Maestra de Trazabilidad `docs/auditoria/Matriz_Trazabilidad_H05.md` auditando 95 especificaciones (55 RF, 30 RNF, 10 D), se publicaron las revisiones normativas `SRS_v1.3_Revision_H05.md` y `SAD_v1.2_Revision_H05.md` con diagramas Mermaid actualizados, y se incorporó el descargo explícito de responsabilidad técnica (el modelo `VotingEnsemble` es una herramienta de estimación referencial que no sustituye los ensayos destructivos de probetas ASTM C39 / NTP 339.034 del RNE E.060).
4. **Preparación de Entrega y Verificación en Limpio (Fase D):** Se elaboraron la Guía de Instalación desde cero (`docs/entrega/Guia_Instalacion_Entorno_Limpio.md`), la Auditoría de Costos de Azure (`docs/entrega/Auditoria_Costos_Azure.md`) que certifica un consumo acumulado de **~$3.50 USD de los $20.00 USD aprobados (17.5%)**, y el Guion de Demostración Final (`docs/entrega/Guion_Demostracion_Final.md`) para la sustentación académica y técnica.
5. **Evidencias Visuales y Certificación (Fase E):** Se generaron las 10 capturas de pantalla requeridas en `docs/evidencias-h05/` utilizando Microsoft Edge headless y peticiones autenticadas contra IIS Express. La solución compila de forma limpia en configuraciones `Debug` y `Release` con MSBuild 17 (0 errores, 0 advertencias).

---

## 2. Remediaciones de Seguridad y Robustez Implementadas (Fase A)

### A1. Desacoplamiento de la Provisión Administrativa (Directiva D-10)
- **Diagnóstico H04:** El script `H04_add_audit_and_user_enabled.sql` contenía una sentencia de asignación automática hardcoded que promovía al usuario `joamedina@upt.pe` a `Administrador` durante la ejecución de la migración DDL.
- **Remediación Aplicada:**
  - Se eliminó dicha sentencia de `Migrations/Scripts/H04_add_audit_and_user_enabled.sql`, dejando la migración estrictamente declarativa.
  - Se desarrolló la rutina de provisión independiente `tools/Provision-Administrator.ps1` y su script complementario `Migrations/Scripts/H05_manual_admin_provisioning.sql`.
  - El script exige confirmación explícita (o flag `-Force`), valida precondiciones mandatorias (existencia del usuario, correo confirmado `EmailConfirmed = 1`, cuenta habilitada `IsEnabled = 1`), actualiza el `SecurityStamp` para invalidar sesiones previas y emite un evento estructurado en `dbo.AuditEvents` sin exponer contraseñas ni tokens.

### A2. Protección Concurrente del Último Administrador (H05-A2 / D-10)
- **Diagnóstico H04:** La verificación de administradores activos en `AdminController.ToggleUserStatus` y `ChangeUserRole` se realizaba en dos pasos desacoplados (conteo no bloqueante seguido de mutación), siendo vulnerable a condiciones de carrera concurrentes (Time-of-Check to Time-of-Use) si dos peticiones simultáneas intentaban degradar o deshabilitar al último administrador.
- **Remediación Aplicada:**
  - Se introdujo `private static readonly SemaphoreSlim _adminConcurrencyLock = new SemaphoreSlim(1, 1);` para serializar peticiones concurrentes dentro del mismo proceso IIS.
  - Se encapsuló la evaluación y modificación dentro de una transacción serializable en SQL Server (`DbContext.Database.BeginTransaction(IsolationLevel.Serializable)`).
  - El conteo bloqueante se ejecuta mediante:
    ```sql
    SELECT COUNT(*) 
    FROM dbo.AspNetUsers u WITH (UPDLOCK, HOLDLOCK)
    INNER JOIN dbo.AspNetUserRoles ur WITH (UPDLOCK, HOLDLOCK) ON u.Id = ur.UserId
    WHERE ur.RoleId = @AdminRoleId AND u.IsEnabled = 1;
    ```
  - Se valida el resultado de `IdentityResult.Succeeded` en todas las operaciones del `UserManager`, ejecutando rollback transaccional ante cualquier fallo.

### A3. Canal de Revocación Inmediata de Sesiones Inhabilitadas (H05-A3)
- **Diagnóstico H04:** Aunque OWIN Katana valida el `SecurityStamp` periódicamente, existe una ventana de retraso (intervalo de revalidación de 1 a 30 minutos) donde un usuario inhabilitado por el administrador podía continuar navegando si su cookie ya estaba emitida.
- **Remediación Aplicada:**
  - Se creó el filtro de autorización global `AuthorizeUserEnabledFilter` ([AuthorizeUserEnabledFilter.cs](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Services/AuthorizeUserEnabledFilter.cs)), registrado en `Global.asax.cs`.
  - El filtro intercepta cada solicitud autenticada, verifica `appUser.IsEnabled` y, si la cuenta fue inhabilitada, revoca de inmediato la cookie de sesión (`SignOut(ApplicationCookie)`) y redirige a `/Account/Login?disabled=1`.
  - La vista `Views/Account/Login.cshtml` presenta un banner de advertencia específico alertando al usuario sobre el bloqueo administrativo.
  - En `App_Start/Startup.Auth.cs`, se configuró `OnValidateIdentity` con intervalo de 1 minuto para forzar la revalidación criptográfica del `SecurityStamp`.

### A4. Sanitización Estricta y Privacidad en Auditoría (H05-A4 / D-07 / D-08)
- **Diagnóstico H04:** En `MezclasController.cs`, la captura de excepciones incluía `ex.Message` directamente en la vista y en la columna `Details` de `AuditEvents`, con el riesgo potencial de filtrar rutas del servidor, cadenas de conexión o URLs internas de microservicios.
- **Remediación Aplicada:**
  - Se robusteció `AuditService.SanitizeDetails` mediante expresiones regulares multi-fase que erradican contraseñas, tokens, ApiKeys, Bearer tokens, cadenas de conexión SQL completas, rutas locales (`[RUTA_PROTEGIDA]`) y trazas de pila (`[STACK_PROTEGIDO]`).
  - En `MezclasController.SimularAsync` y `SimularAjax`, se reemplazó el volcado crudo de excepciones por códigos técnicos controlados (`ML_CLIENT_REJECTED`, `ML_SERVICE_UNAVAILABLE`) y mensajes amigables al usuario.
  - Se certificó que los eventos de simulación ML registran únicamente metadata técnica agregada: latencia en milisegundos, estado HTTP, modelo invocado y código de resultado, sin almacenar jamás formulaciones, masas, dosificaciones privadas ni identificadores de mezclas de terceros.

### A5. Depuración Física Oportunista y Retención de 30 Días (H05-A5 / D-07)
- **Diagnóstico H04:** La exclusión de eventos mayores a 30 días operaba a nivel lógico en las consultas, pero los registros físicos permanecían indefinidamente en la base de datos salvo purga manual.
- **Remediación Aplicada:**
  - En `Services/AuditService.cs`, se implementó `TriggerOpportunisticPurge`, que activa de forma asíncrona y no bloqueante la eliminación física por lotes de 500 registros (`DELETE TOP (500) WHERE TimestampUtc < @cutoff`) cuando ha transcurrido al menos 1 hora desde la última ejecución.
  - La purga está protegida por `_purgeSemaphore` para evitar contención en la base de datos.
  - La consulta está optimizada por el índice no agrupado `IX_AuditEvents_TimestampUtc`.
  - Se verificó que la purga es idempotente y jamás altera tablas de usuarios, mezclas, componentes ni snapshots históricos.

---

## 3. Resultados de la Suite Automatizada de Pruebas (Fase B)

La verificación se ejecutó mediante el orquestador maestro `tests/Run_All_Tests.ps1`, el cual restaura la base de datos de ensayo `EcomixIA_Trial` antes y después de la suite, garantizando aislamiento total sin afectar la base principal `EcomixIA`.

### 3.1 Resumen Consolidado de Ejecución

```
================================================================================
  RESUMEN EJECUTIVO CONSOLIDADO DE PRUEBAS H05
================================================================================
  [PASS] Suite 01: Unit & Domain             |  23 PASS |  0 FAIL |  1.17 s
  [PASS] Suite 02: Integration EF6 & SQL     |   9 PASS |  0 FAIL |  2.85 s
  [PASS] Suite 03: HTTP & Authorization      |   8 PASS |  0 FAIL |  4.34 s
  [PASS] Suite 04: FastAPI Contract Mocks    |  10 PASS |  0 FAIL |  2.76 s
  [PASS] Suite 05: Security & Concurrency    |   9 PASS |  0 FAIL | 13.38 s
  [PASS] Suite 06: Full Regression H01-H04   |   7 PASS |  0 FAIL |  4.10 s
--------------------------------------------------------------------------------
  TOTAL: 66 PASS / 0 FAIL (100% SATISFACTORIO) | Tiempo Total: 30.21 s
================================================================================
```

### 3.2 Detalle de Cobertura por Suite Modular

| Suite | Script | Casos Clave Verificados | Resultado |
|---|---|---|:---:|
| **Suite 01** | `01_Unit_Domain_Tests.ps1` | Serialización DTOs ML, `ProblemDetailsDto`, validador de dominios `@upt.pe` / `@gmail.com` (D-03), complejidad de contraseñas Identity, limitador atómico `RequestRateLimiter` sliding window, sanitizador regex de auditoría y servicio de correo simulado. | **23/23 PASS** |
| **Suite 02** | `02_Integration_EF6_Sql_Tests.ps1` | Existencia de las 10 tablas del modelo, columnas de snapshot en `MezclaComponentes` (H02), índice `IX_AuditEvents_TimestampUtc`, exclusión estricta de eventos >30 días en `GetActiveEvents` (29d vs 31d), y depuración física idempotente por lotes (`PurgeExpiredEventsAsync`). | **9/9 PASS** |
| **Suite 03** | `03_Http_Authorization_Tests.ps1` | Directiva D-02: `MaterialesController` protegido con `[Authorize]` a nivel de clase (anónimos redirigidos a login), RBAC en catálogo (CRUD exclusivo admin con HTTP 403 para registrados), RBAC en `AdminController`, intercepción de cuentas inhabilitadas por `AuthorizeUserEnabledFilter` y bloqueo de cuentas no confirmadas. | **8/8 PASS** |
| **Suite 04** | `04_FastApi_Contract_Mock_Tests.ps1` | `EcoMixMlClientService` con `MockHttpMessageHandler`: respuesta 200 OK con `Strength28dMpa`, respuesta 422 Unprocessable Entity con `ProblemDetailsDto`, respuesta 503 Service Unavailable, enmascaramiento seguro en `MezclasController.Simulador` y `SimularAjax`, y registro de auditoría con metadata técnica exclusiva (sin ingredientes). | **10/10 PASS** |
| **Suite 05** | `05_Security_Concurrency_Tests.ps1` | Concurrencia: Ataque simultáneo de 4 procesos paralelos intentando degradar/inhabilitar al último admin bloqueado con éxito (al menos 1 admin activo permanente), registro de auditoría `BlockDisableLastAdmin`, ráfaga masiva de 25 peticiones sobre el rate limiter (5 permitidas, 20 bloqueadas), regeneración de `SecurityStamp`, y prueba de provisión manual (`tools/Provision-Administrator.ps1`) con precondiciones y reversión. | **9/9 PASS** |
| **Suite 06** | `06_Full_Regression_H01_H04.ps1` | Paridad matemática de métricas de sostenibilidad de Mezcla 1 (costo S/ 174.15, CO2 299.78 kg), inmutabilidad de snapshots tras alteración del catálogo, KPIs del dashboard personal (`DashboardController.Index`), aislamiento de recetas privadas entre usuarios, ciclo de confirmación/token de identidad, y estadísticas globales del dashboard administrativo. | **7/7 PASS** |

---

## 4. Auditoría de Documentación y Trazabilidad (Fase C)

### 4.1 Entregables Documentales Producidos
1. **Matriz Maestra de Trazabilidad (`docs/auditoria/Matriz_Trazabilidad_H05.md`):**
   - Evalúa 95 especificaciones normativas del proyecto: 55 Requerimientos Funcionales, 30 Requerimientos No Funcionales y 10 Decisiones Arquitectónicas.
   - Certifica un cumplimiento del **100% de los ítems aplicables al alcance del sistema**.
2. **Revisión Normativa SRS v1.3 (`docs/revisiones/SRS_v1.3_Revision_H05.md`):**
   - Formaliza las directivas D-02, D-07 y D-10.
   - Incorpora diagramas Mermaid de la máquina de estados del usuario y del flujo de simulación con contingencias.
   - Establece formalmente el **Descargo de Responsabilidad Estructural y Normativa**:
     > *"El modelo VotingEnsemble integrado en EcoMix IA constituye exclusivamente una herramienta de estimación referencial basada en datos experimentales. Bajo ninguna circunstancia sus resultados constituyen una certificación estructural ni reemplazan los ensayos destructivos de rotura de probetas normalizados según ASTM C39 / NTP 339.034 ni las especificaciones del Reglamento Nacional de Edificaciones (Norma Técnica E.060 Concreto Armado)."*
3. **Revisión de Arquitectura SAD v1.2 (`docs/revisiones/SAD_v1.2_Revision_H05.md`):**
   - Documenta el patrón de bloqueo híbrido `SemaphoreSlim` + SQL `WITH (UPDLOCK, HOLDLOCK)`.
   - Incorpora diagramas de componentes y de secuencia de provisión administrativa y revocación de sesión.
   - Detalla la estrategia de retención física de 30 días en `AuditEvents`.

---

## 5. Auditoría de Preparación de Entrega (Fase D)

1. **Guía de Instalación en Entorno Limpio (`docs/entrega/Guia_Instalacion_Entorno_Limpio.md`):**
   - Guía paso a paso reproducible desde `git clone` que documenta requisitos previos, restauración de paquetes NuGet, compilación con MSBuild, creación y migración DDL de SQL Server, provisión del primer administrador, ejecución de pruebas y arranque en IIS Express (`https://localhost:44357/`).
2. **Auditoría de Costos de Azure (`docs/entrega/Auditoria_Costos_Azure.md`):**
   - Certifica que el proyecto ha operado bajo una rigurosa disciplina financiera, consumiendo únicamente **~$3.50 USD de los $20.00 USD aprobados (17.5% del crédito)**.
   - Describe la configuración del microservicio en Azure Container Apps con escalado a cero (`minReplicas = 0`, `idleTimeout = 300 s`) y detalla el procedimiento operativo de contingencia ante los umbrales de $10, $15 y $18 USD.
3. **Guion de Demostración Final (`docs/entrega/Guion_Demostracion_Final.md`):**
   - Guion estructurado en 8 escenarios paso a paso para la sustentación final ante jurados y evaluadores, con cuentas de prueba preconfiguradas, datos de entrada del simulador, demostración de snapshots inmutables, aislamiento del dashboard, panel de administración con protección del último admin y ejecución en vivo de las 66 pruebas automatizadas.

---

## 6. Catálogo de Evidencias Visuales Generadas (Fase E)

Se generaron 10 capturas de pantalla de alta resolución en la carpeta `docs/evidencias-h05/`:

| Archivo de Evidencia | Descripción Técnica y Funcional |
|---|---|
| [01_catalogo_protegido_visitante.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/01_catalogo_protegido_visitante.png) | Petición anónima a `/Materiales` redirigida a `/Account/Login?ReturnUrl=%2FMateriales` (Política D-02). |
| [02_catalogo_usuario_registrado.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA Sistema/docs/evidencias-h05/02_catalogo_usuario_registrado.png) | Usuario autenticado con rol `Registrado` consultando el catálogo sin botones de mutación (solo lectura). |
| [03_simulador_inferencia_exitosa.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/03_simulador_inferencia_exitosa.png) | Formulario de simulación de 7 componentes, predicción de resistencia en MPa a 7/28 días y gráfico interactivo mediante SVG nativo. |
| [04_simulador_error_enmascarado.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/04_simulador_error_enmascarado.png) | Alerta comprensible ante dosificación fuera de rango (HTTP 422 ProblemDetails) sin filtrar rutas ni excepciones internas. |
| [05_dashboard_personal_kpis.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/05_dashboard_personal_kpis.png) | Dashboard personal en `/Dashboard` mostrando total de mezclas privadas, costo promedio y emisiones promedio de CO₂ (D-04). |
| [06_admin_gestion_usuarios.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/06_admin_gestion_usuarios.png) | Panel administrativo de usuarios (`/Admin/Users`) con paginación, búsqueda por correo y conmutadores de estado/rol. |
| [07_admin_bloqueo_ultimo_admin.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/07_admin_bloqueo_ultimo_admin.png) | Alerta roja de seguridad bloqueando el intento de inhabilitar al último administrador activo del sistema (D-10). |
| [08_admin_auditoria_retencion_30d.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/08_admin_auditoria_retencion_30d.png) | Pista de auditoría (`/Admin/Audit`) con detalle sanitizado, aviso de retención de 30 días y botón de depuración física. |
| [09_login_cuenta_deshabilitada.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/09_login_cuenta_deshabilitada.png) | Pantalla de inicio de sesión con banner rojo de advertencia ante cuenta inhabilitada administrativamente (`disabled=1`). |
| [10_suite_pruebas_master_100_pass.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h05/10_suite_pruebas_master_100_pass.png) | Certificación gráfica de la consola ejecutando `tests/Run_All_Tests.ps1` con 66/66 PASS (100% éxito en 30.21 s). |

---

## 7. Verificación de Compilación y Estado del Repositorio

1. **Compilación MSBuild 17:**  
   - Perfil `Debug|Any CPU`: Código de salida `0` (0 errores, 0 advertencias).  
   - Perfil `Release|Any CPU`: Código de salida `0` (0 errores, 0 advertencias).
2. **Archivos Protegidos y Buenas Prácticas:**  
   - `Web.Secrets.config` permanece desrastreado e ignorado por Git.  
   - La carpeta `docs/presentacion-canva/` permanece intacta y desrastreada.  
   - El repositorio ML de referencia `https://github.com/JMedina255/EcoMix-IA-AzureML` se mantuvo estrictamente en modo solo lectura.  
   - La rama activa `feat/ecomix-fase-04-cierre-integracion` conserva la historia lineal desde el commit base `5b701e9b0ab92d702807b33b9b641cdfb9203273`.

---

## 8. Certificación y Conclusión Final

El sistema **EcoMix IA** ha culminado satisfactoriamente el hito **H05: Auditoría Integral, Remediación y Preparación de Entrega**.

El software cumple con los más altos estándares de calidad de la ingeniería de software:
- **Seguridad Robusta:** Autenticación institucional, protección contra ataques de fuerza bruta, aislamiento multi-inquilino estricto, protección del último administrador e invalidación forzosa de sesiones.
- **Rigor Matemático y Científico:** Predicción con ensamble de modelos de Machine Learning, cálculo reproducible de costo y huella de carbono mediante snapshots inmutables y descarga explícita de límites normativos.
- **Eficiencia Financiera y Operativa:** Operación local desacoplada con consumo marginal de Azure Container Apps ($3.50 USD de $20.00 USD presupuestados).
- **Calidad Verificable:** Suite automatizada de 66 pruebas con 100% de éxito, documentación completa y reproducible para su despliegue y sustentación.

**Estado del Hito H05:** **CONCLUIDO Y CERTIFICADO PARA ENTREGA FINAL**.
