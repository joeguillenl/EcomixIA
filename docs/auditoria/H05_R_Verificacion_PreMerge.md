# Informe de Auditoría y Verificación Pre-Merge — H05-R

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Simulación de Concreto Ecológico  
**Hito:** H05-R — Correcciones Finales y Preparación de Pull Request  
**Fecha de Ejecución:** 20 de Noviembre de 2026  
**Rama Base (Target):** `master` (`ad28180a4eb3508054d9037052f749150ebaebcf` en `origin/master`)  
**Rama de Origen H05:** `feat/ecomix-fase-04-cierre-integracion` (`b48772eef3e9efbc07be3292d244b5f78c98f536`)  
**Nueva Rama de Integración (Head):** `fix/ecomix-h05-premerge`  
**Veredicto Final:** **APTO PARA MERGE**  

---

## 1. Resumen Ejecutivo y Hallazgos Subsanados

Durante la auditoría de control pre-merge sobre el entregable H05, se identificaron y remediaron satisfactoriamente las siguientes discrepancias:

| ID | Área / Archivo | Hallazgo Detectado | Solución Técnica Implementada en H05-R | Estado |
|---|---|---|---|:---:|
| **H05R-01** | `H05_manual_admin_provisioning.sql` | Sintaxis incorrecta en bloque de control transaccional (`TRY` en vez de `BEGIN TRY`). | Reestructuración a `BEGIN TRY ... BEGIN TRANSACTION ... COMMIT ... END TRY BEGIN CATCH ... ROLLBACK ... END CATCH`. | **Subsanado** |
| **H05R-02** | `H05_manual_admin_provisioning.sql` y `tools/Provision-Administrator.ps1` | Falta de control estricto sobre administradores preexistentes (RF-52 / RF-53). La rutina de bootstrap inicial permitía ser invocada repetidamente o tras retirar roles administrativos. | Exclusión mutua transaccional con `sp_getapplock` ('EcoMix_Admin_Bootstrap_Lock'); comprobación mandatoria de cualquier administrador preexistente (activo o inhabilitado); comprobación persistente en `AuditEvents` (`HistoricalBootstrapCount > 0`) impidiendo repetir bootstrap tras retiro de roles; procedimiento de recuperación de emergencia separado explícitamente autorizado (`-AllowRecovery` / `@IsRecovery = 1`) auditado como `AdminEmergencyRecovery`. | **Subsanado** |
| **H05R-03** | `tests/Run_All_Tests.ps1` | Presencia de rutas absolutas locales (`C:\Users\Admin\...`), falta de propagación de `TargetDatabase` y ausencia de validación estricta de base de datos de ensayo autorizada. | Resolución dinámica de rutas mediante `[System.IO.Path]::GetTempPath()`, propagación mandatoria de `$env:TARGET_DATABASE` a todas las suites y procesos auxiliares, lista blanca estricta (`EcomixIA_Trial`, `EcomixIA_Test`), prohibición estricta de `EcomixIA` principal, verificación de código de salida de `sqlcmd` con bandera `-b`, y validación obligatoria de resumen con `passed > 0` y `failed == 0`. | **Subsanado** |
| **H05R-04** | Pipeline MVC y Pruebas E2E | Cobertura orientada a invocación directa de controladores, sin validar ejecución en servidor real de cookies OWIN, anti-falsificación (CSRF), concurrencia ni revocación inmediata de sesión ante inhabilitación. | Implementación de **Suite 07: Real HTTP Pipeline con IIS Express** en puerto 58085 con base aislada: 1) GET anónimo a `/Materiales` redirige con 302 a Login; 2) Login real emite cookie `.AspNet.ApplicationCookie` y accede con 200 a ruta protegida; 3) POST administrativo sin CSRF rechazado con HTTP 500 sin mutación en base de datos; 4) POST administrativo con CSRF válido aceptado y muta estado; 5) Intento IDOR a receta ajena rechazado con HTTP 403; 6) Revocación inmediata de sesión activa de usuario inhabilitado redirigiendo con HTTP 302 a `/Account/Login?disabled=1`. | **Subsanado** |
| **H05R-05** | `Auditoria_Costos_Azure.md` | Declaración de consumo de US$3.50 USD sin aclarar su naturaleza estimada ni el estado de verificación con Azure Cost Management. | Reconciliación presupuestal: se especificó explícitamente que los US$3.50 representan una estimación técnica preliminar y se registró formalmente el estado de **Verificación Externa Pendiente** ante la falta de credenciales de portal. Consumo en H05/H05-R ratificado en **$0.00 USD**. Renumeración de RF-46 (consumo acumulado), RF-47 (restricción por límite de saldo) y RF-48 (alertas US$10/15/18 y procedimiento de detención). | **Subsanado** |
| **H05R-06** | `Matriz_Trazabilidad_H05.md` | Se marcaban como «Implementado» requisitos que dependen de infraestructura cloud de terceros, precisión de snapshots indicada como (18,4) y atribución incorrecta a Chart.js. | Reclasificación rigurosa en **Implementado (Local)** (88 ítems) e **Integración Externa Pendiente** (7 ítems); corrección de precisión real a `decimal(18,6)` en `CostoPorKgGuardado` y `Co2PorKgGuardado`; atribución precisa a **SVG nativo** accesible (sin Chart.js); diferenciación clara entre pruebas sintéticas/unitarias y HTTP real. | **Subsanado** |

---

## 2. Evidencias de Ejecución y Pruebas de Regresión

### 2.1 Compilación de la Solución
Ambas configuraciones fueron compiladas limpiamente mediante MSBuild 17 sin advertencias ni errores:
- **Debug:** `MSBuild.exe EcomixIA.sln /p:Configuration=Debug /t:Rebuild` -> `0 Errores`, `0 Advertencias`.
- **Release:** `MSBuild.exe EcomixIA.sln /p:Configuration=Release /t:Rebuild` -> `0 Errores`, `0 Advertencias`.

### 2.2 Resultados Consolidados de la Suite de Pruebas
La suite de pruebas automatizadas modular y endurecida (`tests/Run_All_Tests.ps1`) se ejecutó independientemente sobre las dos bases de datos aisladas autorizadas (`EcomixIA_Trial` y `EcomixIA_Test`), garantizando idéntico comportamiento e inalterabilidad absoluta de la base principal `EcomixIA`:

```text
================================================================================
  ECOMIX IA — MASTER AUTOMATED TEST SUITE (H05-R: VERIFICACIÓN PRE-MERGE)
================================================================================
  [PASS] Suite 01: Unit & Domain                |  23 PASS |  0 FAIL |  1.68 s
  [PASS] Suite 02: Integration EF6 & SQL        |   9 PASS |  0 FAIL |  4.67 s
  [PASS] Suite 03: HTTP & Authorization Pipeline |  10 PASS |  0 FAIL |  3.12 s
  [PASS] Suite 04: FastAPI Contract Mocks       |  10 PASS |  0 FAIL |  2.95 s
  [PASS] Suite 05: Security & Concurrency       |  14 PASS |  0 FAIL | 22.54 s
  [PASS] Suite 06: Full Regression H01-H04      |   7 PASS |  0 FAIL |  3.87 s
  [PASS] Suite 07: Real HTTP Pipeline (IIS Express) |   7 PASS |  0 FAIL |  5.55 s
--------------------------------------------------------------------------------
  TOTAL: 80 PASS / 0 FAIL | Tiempo Total: 46.49 s (EcomixIA_Trial) / 48.12 s (EcomixIA_Test)
================================================================================
```

Evidencia estructurada exportada: [`tests/Test_Results_H05_Summary.json`](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/tests/Test_Results_H05_Summary.json).

### 2.3 Detalle de Nuevas Validaciones Incorporadas en H05-R
1. **Validación Concurrente con Dos Administradores Activos (Suite 05.2):**  
   Se preparó la base de ensayo con dos administradores activos (`joamedina@upt.pe` y `joamedina2@upt.pe`). Se lanzaron dos procesos PowerShell concurrentes ejecutando solicitudes simultáneas de cambio de rol hacia `Registrado`.  
   *Resultado:* La exclusión mutua mediante `SemaphoreSlim(1,1)` y la transacción serializable con `WITH (UPDLOCK, HOLDLOCK)` permitieron exactamente una degradación y bloquearon la segunda con el evento `BlockDemoteLastAdmin`, garantizando que la base de datos conservó exactamente 1 administrador activo.
2. **Bootstrap Inicial con Exclusión Mutua `sp_getapplock` y Protección Persistente (Suite 05.5 y 05.6):**  
   - Exclusión mutua a nivel de proceso y transacción utilizando `sp_getapplock` (`Resource = 'EcoMix_Admin_Bootstrap_Lock'`). Dos ejecuciones concurrentes desde cero garantizan que exactamente una aprovisiona al primer administrador y la segunda es rechazada de forma segura.
   - Rechazo mandatorio si existe cualquier administrador previo, incluso si se encuentra deshabilitado (`IsEnabled = 0`).
   - Bloqueo persistente en `AuditEvents` (`HistoricalBootstrapCount > 0`) impidiendo repetir el bootstrap si un operador retira todos los roles administrativos posteriormente.
   - Procedimiento de recuperación administrativa de emergencia separado y expresamente autorizado (`-AllowRecovery` / `@IsRecovery = 1`) auditado distintivamente como `AdminEmergencyRecovery`.
   - Script SQL `H05_manual_admin_provisioning.sql` probado con éxito en bloque `TRY/CATCH` sin errores de sintaxis y validando RF-53.
3. **Pipeline HTTP Real en Servidor Web IIS Express (Suite 07):**  
   Pruebas de extremo a extremo contra servidor real `iisexpress.exe` en puerto 58085 con base aislada:
   - *HTTP 7.1:* Solicitud GET anónima a `/Materiales` interceptada y redirigida con HTTP 302 a `/Account/Login?ReturnUrl=/Materiales`.
   - *HTTP 7.2:* Autenticación real mediante POST a `/Account/Login` con credenciales válidas; retorno de HTTP 302, emisión de cookie `.AspNet.ApplicationCookie` y posterior acceso con HTTP 200 OK a `/Mezclas`.
   - *HTTP 7.3:* Solicitud POST administrativa sin token CSRF rechazada estrictamente con HTTP 500 (`HttpAntiForgeryException`) sin mutación en base de datos.
   - *HTTP 7.4:* Solicitud POST administrativa con token CSRF válido aceptada con HTTP 302 y mutación confirmada del estado `IsEnabled`.
   - *HTTP 7.5:* Intento de acceso directo a receta ajena (`/Mezclas/Details/ID`) rechazado con HTTP 403 (Safe Denial por `OwnerUserId`).
   - *HTTP 7.6:* Revocación inmediata de sesión activa: al inhabilitar una cuenta en base de datos (`IsEnabled = 0`), la siguiente solicitud con cookie activa es interceptada inmediatamente por `AuthorizeUserEnabledFilter` / OWIN `OnValidateIdentity`, revocando la cookie y redirigiendo a `/Account/Login?disabled=1`.

---

## 3. Estado de Servicios Cloud y Correo Transaccional

### 3.1 Conciliación de Costos Azure (Directiva D-06)
- **Gasto en H05 y H05-R:** **$0.00 USD**. Todas las pruebas de integración del contrato ML se ejecutaron contra simuladores desacoplados (`MockHttpMessageHandler`), y la persistencia se realizó exclusivamente en LocalDB.
- **Gasto Histórico Estimado:** **~$3.50 USD** (consumo teórico de almacenamiento en Azure Container Registry SKU Basic durante fases iniciales).
- **Verificación Externa Pendiente:** La consulta del saldo exacto en el portal de Azure y la sincronización con **Azure Cost Management** se encuentra catalogada como **Pendiente de Credenciales**, respetando la restricción de no realizar llamadas a endpoints facturables.
- **Margen de Seguridad:** Sobre el presupuesto máximo autorizado de US$ 20.00, se cuenta con un margen estimado remanente de **US$ 16.50 (82.5%)**.

### 3.2 Servicio de Correo Transaccional (Directiva D-03 / RF-40)
- **Implementación Local:** Servicio simulado (`SimulatedEmailService`) almacena los correos de confirmación y restablecimiento de contraseña en formato estructurado en `App_Data/EmailOutbox` con costo $0 y sin secretos en el código fuente.
- **Arquitectura de Intercambio:** `TransactionalEmailSenderFactory` permite alternar dinámicamente entre `Simulated`, `Smtp` y `HttpApi` mediante configuración en `Web.config`.
- **Integración Externa:** La suscripción a SendGrid API o SMTP corporativo productivo queda configurada en el diseño pero catalogada como **Pendiente de Activación en Despliegue**.

---

## 4. Matriz de Requisitos y Especificaciones Técnicas

Conforme a la revisión H05-R, se confirmaron las siguientes precisiones:
- **Precisión Decimal:**
  - `CostoPorKgGuardado`: `decimal(18, 6)` (conforme a `H02_add_snapshots_to_mezclacomponentes.sql` y EF6)
  - `Co2PorKgGuardado`: `decimal(18, 6)` (conforme a `H02_add_snapshots_to_mezclacomponentes.sql` y EF6)
  - `ResistenciaMPa`, `RelacionAguaCemento`, `AsentamientoCm`: `decimal(18, 2)`
- **Visualización Gráfica en Simulador (RF-18):**
  - Implementada mediante **SVG nativo** accesible y estilizado, eliminando la dependencia de bibliotecas externas de gráficos (Chart.js), con leyenda explícita de estimación experimental no certificada.
- **Procedencia de Snapshots y Safe Denial (D-09):**
  - Origen `'CAPTURADO'`: Materiales validados desde catálogo vigente; habilitan el cálculo histórico inmutable de costo y CO₂ por m³.
  - Origen `'LEGADO_SIN_VERIFICAR'`: Fórmulas históricas previas; retornan `null` en propiedades históricas inmutables y muestran cálculos referenciales vigentes en la vista.
- **Descargo Estructural:** Se mantiene explícito en todas las interfaces que las estimaciones del modelo VotingEnsemble son orientativas y no reemplazan los ensayos destructivos bajo norma ASTM C39 ni los factores de seguridad del RNE E.060.

---

## 5. Comparación contra la Rama `master`

La comparación directa contra `origin/master` (`ad28180a4eb3508054d9037052f749150ebaebcf`) evidencia:
- **Archivos Modificados:** 10 archivos de código y vistas existentes.
- **Archivos Nuevos:** 30 archivos que corresponden exclusivamente a scripts de migración DDL, filtros globales de seguridad, herramientas de provisión, suite de pruebas automatizadas y documentación técnica.
- **Archivos Ajenos:** Cero. No se incluyeron archivos temporales, binarios de compilación ni secretos de configuración.
- **Total de Inserciones/Supresiones:** +3,341 líneas / -133 líneas.

---

## 6. Procedimiento para Pull Request y Enlace

- **Rama Base:** `master`
- **Rama a Fusionar:** `fix/ecomix-h05-premerge`
- **Hash de Integración:** Verificado tras el último commit en la nueva rama.
- **URL del Repositorio:** `https://github.com/joeguillenl/EcomixIA.git`
- **Enlace de Creación del Pull Request:**  
  `https://github.com/joeguillenl/EcomixIA/compare/master...fix/ecomix-h05-premerge?expand=1`

---

## 7. Veredicto Final

### **APTO PARA MERGE**

**Justificación Técnica:**
1. Todos los hallazgos de seguridad, concurrencia, provisión y sintaxis SQL han sido remediados y probados de manera exhaustiva en una base de datos aislada.
2. La suite automatizada de regresión y pipeline HTTP real alcanzó un resultado de **80/80 pruebas superadas (100% PASS)** en 46.49 segundos (`EcomixIA_Trial`) y 48.12 segundos (`EcomixIA_Test`).
3. Se verificó la no-regresión de las funcionalidades de los hitos H01, H02, H03 y H04.
4. El árbol de Git es completamente limpio, no contiene secretos ni dependencias no autorizadas, y no altera el repositorio de Machine Learning.
5. El Pull Request queda preparado para revisión y aprobación manual sin fusión automática destructiva.
