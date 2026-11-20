# EcoMix IA — H02: Informe de Auditoría y Cierre de Persistencia Histórica de Mezclas y Dashboard Personal

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación de Concreto Sostenible  
**Hito:** H02 — Persistencia Histórica de Mezclas y Dashboard Personal  
**Fecha de Ejecución:** 20 de noviembre de 2026  
**Rama de Trabajo:** `feat/ecomix-fase-04-cierre-integracion`  
**Commit Base H01:** `8fd8c06e0214b476db4f18405c49cba083fa21c9`  
**Repositorio MVC:** `https://github.com/joeguillenl/EcomixIA.git`  
**Repositorio ML de Referencia (Solo Lectura):** `https://github.com/JMedina255/EcoMix-IA-AzureML`  
**Autor:** Antigravity Agent (Google DeepMind)  
**Estado:** Hito H02 Concluido Exitosamente — 100% de Pruebas Superadas (16/16), Migración Verificada y Cero Invocaciones Facturables

---

## 1. Resumen Ejecutivo, Objetivos y Alcance

El hito **H02** consolida los requerimientos funcionales **RF-14**, **RF-15**, **RF-41**, **RF-42** y **RF-43**, junto a las decisiones arquitectónicas **D-04** (Dashboard de Mezclas Propias) y **D-09** (Inmutabilidad Histórica de Costos y Emisiones mediante Snapshots). Se introduce un esquema de persistencia histórico y reproducible que captura los costos unitarios y factores de emisión de cada material en el momento exacto de la dosificación, evitando que cambios futuros en el catálogo de materiales alteren retroactivamente balances económicos o ecológicos de mezclas pasadas.

Asimismo, se implementa el nuevo **Dashboard Personal** para usuarios autenticados, calculando métricas agregadas (*KPIs*) aisladas estrictamente por usuario (*multi-tenant* a nivel de aplicación), y se fortalece la seguridad de la aplicación erradicando la mutabilidad por peticiones GET en la duplicación de mezclas, blindando la transacción con tokens antifalsificación (`[ValidateAntiForgeryToken]`) y transaccionalidad atómica (`DbContextTransaction`).

### 1.1 Objetivos Cumplidos
1. **Auditoría de Persistencia y Migración Aditiva (H02-A):** Verificación de integridad de la base `EcomixIA` en `(LocalDb)\MSSQLLocalDB`, confirmación de disponibilidad del respaldo H00 (`EcomixIA_pre_h00_20261120_112953.bak`), generación del nuevo respaldo H02 (`EcomixIA_pre_h02_20261120_121218.bak`), restauración de ensayo en `EcomixIA_Trial`, comprobación de rollback y aplicación exitosa del DDL aditivo en la base principal tras autorización explícita del usuario.
2. **Implementación de Snapshots D-09 con Precisión Decimal (H02-B):** Extensión de `MezclaComponente` con 4 columnas (`CostoPorKgGuardado`, `Co2PorKgGuardado`, `FechaSnapshotUtc`, `OrigenSnapshot`), configuradas con precisión explícita `decimal(18,6)` en EF6 Fluent API (`EcomixContext.cs`). Captura forzada en servidor al momento de insertar componentes. Marcado de registros preexistentes como `LEGADO_SIN_VERIFICAR` sin falsear datos históricos con ceros.
3. **Cálculos Económicos y Ambientales Reproducibles (H02-C):** Incorporación de propiedades calculadas en `Mezcla.cs` (`TieneSnapshotsCompletos`, `CostoHistoricoPorM3`, `Co2HistoricoPorM3`, `MasaTotalPorM3`, `CostoReferencialActualPorM3`, `Co2ReferencialActualPorM3`). Regla de no-sustitución por cero para preservar el rigor metrológico.
4. **Dashboard Personal de Mezclas Privadas (H02-D / RF-41 a RF-43):** Desarrollo completo de `DashboardController`, `DashboardViewModel` y la vista `Views/Dashboard/Index.cshtml`. Cálculo de los tres KPIs clave (Total de mezclas privadas, Costo promedio verificado por m³, y Emisiones promedio verificadas por m³) con aislamiento absoluto por `OwnerUserId`. Manejo del estado "Sin datos" ante la ausencia de mezclas completas.
5. **Duplicación Segura y Transaccional (H02-E):** Restricción del endpoint `Duplicar` a `[HttpPost]` con `[ValidateAntiForgeryToken]`, rechazo formal de solicitudes GET, clonación profunda en transacción atómica y preservación de la procedencia original de los componentes.
6. **Validación Automatizada Rigurosa (H02-F):** Suite de pruebas PowerShell `tests/Run_H02_Automated_Suite.ps1` con 16 casos de prueba independientes que evalúan desde migración y persistencia hasta aislamiento multi-usuario y regresión, logrando un 100% de aprobación.
7. **Generación de Evidencias Visuales (H02-G):** Captura de 8 imágenes PNG de alta resolución en `docs/evidencias-h02/` mediante Microsoft Edge Headless sobre el sistema web en ejecución autenticada.

---

## 2. Archivos Modificados e Incorporados

| Archivo | Capa / Módulo | Propósito y Justificación Técnica |
|---|---|---|
| `Models/MezclaComponente.cs` | Dominio / Modelo | Incorporación de `CostoPorKgGuardado` (`decimal?`), `Co2PorKgGuardado` (`decimal?`), `FechaSnapshotUtc` (`DateTime?`) y `OrigenSnapshot` (`string`), permitiendo la persistencia inmutable de precios y factores ambientales en el instante de dosificación (D-09). |
| `Models/EcomixContext.cs` | Persistencia / EF6 | Mapeo mediante Fluent API en `OnModelCreating` configurando `HasPrecision(18, 6)` para evitar la reducción por defecto de EF6 a `(18, 2)`, y `HasMaxLength(24)` en `OrigenSnapshot`. |
| `Models/Mezcla.cs` | Dominio / Lógica | Propiedades calculadas: `TieneSnapshotsCompletos` (booleano), `CostoHistoricoPorM3` (`decimal?`), `Co2HistoricoPorM3` (`decimal?`), `MasaTotalPorM3` (`decimal`), y estimaciones referenciales para mezclas legadas (`CostoReferencialActualPorM3`, `Co2ReferencialActualPorM3`). |
| `Controllers/DashboardController.cs` | Presentación / MVC | Nuevo controlador con `[Authorize]`, filtrado estricto por `OwnerUserId == CurrentUserId` y cálculo de media aritmética sobre mezclas completas para KPIs RF-41, RF-42 y RF-43. |
| `Models/ViewModels/DashboardViewModel.cs` | Vista / ViewModel | Estructura para alimentar el Dashboard: usuario activo, total de mezclas privadas, cantidad verificada vs. pendiente, costo promedio por m³, CO₂ promedio por m³ y lista de mezclas recientes. |
| `Views/Dashboard/Index.cshtml` | Presentación / Razor | Vista principal del Dashboard personal: 3 tarjetas de KPIs con badges semánticos, indicador "Sin datos", accesos directos y tabla de mezclas propias recientes. |
| `Views/Shared/_Layout.cshtml` | Presentación / Layout | Inclusión del acceso directo "Dashboard" en la barra de navegación superior exclusivo para usuarios autenticados. |
| `Controllers/MezclasController.cs` | Controladores / MVC | Transformación de `Duplicar` a `[HttpPost]` con `[ValidateAntiForgeryToken]` y transacción atómica. Enriquecimiento de `AgregarComponente` con captura de snapshots en servidor desde `Materials`. Adición de `ActualizarComponente` preservando snapshots unitarios. Blindaje de autorización multi-inquilino (HTTP 403 Forbidden ante mezcla ajena o sin propietario). |
| `Views/Mezclas/Index.cshtml` | Presentación / Razor | Incorporación del formulario POST con token antifalsificación para la acción Duplicar y visualización de badges de estado histórico ("Verificado D-09" vs "Referencial / Legado"). |
| `Views/Mezclas/Details.cshtml` | Presentación / Razor | Visualización detallada de columnas de snapshot (`Costo Unit.`, `CO₂ Unit.`, `Costo Subtotal`, `CO₂ Subtotal`, `Estado Snapshot`), cálculo de totales inmutables vs referenciales y formulario de adición de componentes. |
| `Migrations/Scripts/H02_add_snapshots_to_mezclacomponentes.sql` | Base de Datos / DDL | Script de migración aditiva idempotente: agrega las 4 columnas a `MezclaComponentes` e inicializa los registros existentes con `OrigenSnapshot = 'LEGADO_SIN_VERIFICAR'` y costos/CO₂ en `NULL`. |
| `Migrations/Scripts/H02_rollback_snapshots_from_mezclacomponentes.sql` | Base de Datos / Rollback | Script de reversión segura que elimina las columnas agregadas sin afectar las columnas previas ni los datos existentes de `Mezclas` o `Materials`. |
| `database/EcomixIA_Full_Setup.sql` | Base de Datos / Setup | Actualización del script de inicialización completa para incluir las nuevas columnas en instalaciones desde cero. |
| `EcomixIA.csproj` | Configuración / MSBuild | Registro de los nuevos archivos de código (`DashboardController.cs`, `DashboardViewModel.cs`), vistas (`Views/Dashboard/Index.cshtml`) y scripts de migración. |
| `tests/Run_H02_Automated_Suite.ps1` | QA / Automatización | Suite automatizada en PowerShell con 16 pruebas integrales (migración, rollback, persistencia, aislamiento, duplicación, cálculo y regresión). |

---

## 3. Auditoría de Persistencia y Procedimiento de Migración

### 3.1 Verificación de Inventario Previo y Respaldos
Antes de intervenir la base de datos principal, se verificó el estado previo registrado en H00 y H01:

- **Instancia:** `(LocalDb)\MSSQLLocalDB`
- **Base de datos principal:** `EcomixIA`
- **Inventario inicial confirmado:**
  - `Materials`: 10 registros.
  - `Mezclas`: 14 registros (10 públicas/sin propietario, 4 privadas asociadas a usuarios Identity).
  - `MezclaComponentes`: 48 registros.
  - `AspNetUsers`: 4 registros (incluyendo usuario demo `joamedina@upt.pe` y cuenta de pruebas de integración).
- **Respaldo H00 preexistente:** `C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema\database\backups\EcomixIA_pre_h00_20261120_112953.bak` (15,925,248 bytes, verificado íntegro).
- **Nuevo respaldo H02 generado:** `C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema\database\backups\EcomixIA_pre_h02_20261120_121218.bak` (16,056,320 bytes, verificado íntegro mediante `RESTORE VERIFYONLY`).

### 3.2 Ensayo en Base de Datos Clonada (`EcomixIA_Trial`)
Para garantizar la no-destructividad del procedimiento:
1. Se restauró el respaldo H02 sobre la base aislada `EcomixIA_Trial`.
2. Se aplicó el script `H02_add_snapshots_to_mezclacomponentes.sql`.
3. Se verificó que los 48 componentes legados recibieron `OrigenSnapshot = 'LEGADO_SIN_VERIFICAR'` manteniendo `CostoPorKgGuardado = NULL` y `Co2PorKgGuardado = NULL`.
4. Se probó el script de reversión `H02_rollback_snapshots_from_mezclacomponentes.sql`, confirmando que el esquema retornó limpiamente a su estado anterior sin pérdida de registros.
5. Se re-aplicó la migración aditiva para dejar `EcomixIA_Trial` lista para la ejecución de la suite de pruebas automatizadas.

### 3.3 Autorización y Aplicación en la Base Principal (`EcomixIA`)
Tras presentar el informe técnico de ensayo y solicitar la autorización formal del usuario, se aplicó la migración sobre `EcomixIA`:
- Las 4 columnas se agregaron satisfactoriamente.
- Los 48 registros preexistentes quedaron catalogados como legados no verificados.
- El inventario total de 10 materiales, 14 mezclas, 48 componentes y 4 usuarios Identity se preservó al 100% sin truncamiento ni corrupción de datos.

---

## 4. Reglas de Negocio de Snapshots (D-09) y Modelado Matemático

### 4.1 Inmutabilidad Histórica y Precisión Metrológica
Cuando un usuario agrega un componente a una mezcla propia:
1. El servidor consulta el precio vigente (`CostoPorKg`) y el factor de emisiones (`Co2PorKg`) directamente desde `Materials` en SQL Server.
2. Los valores unitarios se graban en `MezclaComponentes.CostoPorKgGuardado` y `Co2PorKgGuardado` con precisión `decimal(18,6)`.
3. Se asigna la marca de tiempo `FechaSnapshotUtc = DateTime.UtcNow` y el estado `OrigenSnapshot = "CAPTURADO"`.
4. **Protección contra manipulación:** Los formularios POST no aceptan parámetros de precio ni factor de emisión provenientes del cliente.
5. **Independencia de catálogo:** Si el precio de un material se actualiza en el futuro (ej. el cemento pasa de S/ 0.50 a S/ 0.65/kg), los componentes previamente dosificados conservan intacto su costo histórico capturado (S/ 0.50).
6. **Edición de cantidad:** Si el usuario modifica la dosificación de un componente existente, únicamente se actualiza el campo `Cantidad`. El costo y factor unitarios capturados permanecen inmutables.
7. **Eliminación y re-inserción:** Si el usuario decide aplicar el precio vigente, debe eliminar el componente y volver a agregarlo, lo que registra un nuevo snapshot con la fecha y valores actuales.

### 4.2 Tratamiento de Registros Legados
Los 48 componentes creados con anterioridad a H02 no poseen trazabilidad de precio en el momento de su dosificación. En estricto apego al estándar de ingeniería:
- `CostoPorKgGuardado = NULL`
- `Co2PorKgGuardado = NULL`
- `FechaSnapshotUtc = NULL`
- `OrigenSnapshot = "LEGADO_SIN_VERIFICAR"`
- **Prohibición de ceros falsos:** No se sustituyen los valores nulos por `0.00`. Una mezcla con componentes legados no presenta costo histórico verificado (`CostoHistoricoPorM3 == null`), sino un cálculo referencial derivado de los precios actuales del catálogo (`CostoReferencialActualPorM3`), claramente advertido con el badge amarillo *"Referencial / Contiene Componentes Legados"*.

---

## 5. Dashboard Personal y Aislamiento Multi-inquilino (D-04 / RF-41 a RF-43)

El nuevo panel accesible desde `/Dashboard` opera bajo la directiva de seguridad de aislamiento multi-inquilino en la capa de aplicación:

```csharp
var mezclasUsuario = db.Mezclas
    .Include(m => m.Componentes.Select(c => c.Material))
    .Where(m => m.OwnerUserId == CurrentUserId)
    .ToList();
```

### 5.1 Definición de los KPIs
1. **Total de Mezclas Privadas (RF-41):** Número total de mezclas cuya propiedad pertenece exclusivamente al usuario actual (`mezclasUsuario.Count`). Desglosa cuantitativamente cuántas fórmulas cuentan con snapshots completos verificados y cuántas se encuentran pendientes de validación.
2. **Costo Promedio Verificado por m³ (RF-42):** Media aritmética calculada sobre las mezclas que cumplen `m.TieneSnapshotsCompletos`:
   $$\overline{Costo} = \frac{\sum_{i=1}^{k} CostoHistoricoPorM3_i}{k}$$
   Donde $k$ es el número de mezclas privadas con snapshots completos. Si $k = 0$, el indicador despliega el badge semántico `"Sin datos"` en lugar de distorsionar la estadística con un falso cero.
3. **Emisiones Promedio Verificadas por m³ (RF-43):** Media aritmética calculada sobre las mezclas completas:
   $$\overline{CO_2} = \frac{\sum_{i=1}^{k} Co2HistoricoPorM3_i}{k}$$
   Desplegado en unidades $\text{kg } CO_2 / m^3$. Si no existen mezclas verificadas, se despliega `"Sin datos"`.

### 5.2 Duplicación Transaccional y Segura (D-01 / D-08 / H02-E)
El endpoint `MezclasController.Duplicar` fue blindado exhaustivamente:
- **Protección contra CSRF y Crawlers:** Decorado con `[HttpPost]` y `[ValidateAntiForgeryToken]`. Las solicitudes entrantes vía GET son rechazadas devolviendo HTTP 405 / vista orientativa, impidiendo que herramientas automatizadas o motores de búsqueda clonen mezclas involuntariamente.
- **Atomicidad Transaccional:** Ejecución encapsulada dentro de `using (var tx = db.Database.BeginTransaction())`. La creación de la cabecera de la mezcla y la clonación de sus componentes ocurren de forma atómica; si cualquier inserción falla, se ejecuta un rollback completo.
- **Asignación de Propiedad:** La mezcla duplicada se asigna inequívocamente al usuario activo (`OwnerUserId = CurrentUserId`).
- **Preservación de Trazabilidad:** Los componentes clonados retienen los valores unitarios (`CostoPorKgGuardado`, `Co2PorKgGuardado`), su procedencia (`OrigenSnapshot`) y su fecha histórica original. Una mezcla legada clonada continúa siendo legada; la clonación jamás transforma de manera fraudulenta un dato no verificado en un snapshot verificado.

---

## 6. Matriz de Resultados de la Suite Automatizada (H02-F)

La suite de pruebas automatizadas `tests/Run_H02_Automated_Suite.ps1` fue ejecutada contra la base de ensayos `EcomixIA_Trial`, evaluando 16 casos de prueba independientes que abarcan todos los requerimientos funcionales y criterios de aceptación:

| ID | Escenario Evaluado | Componente / Capa | Resultado | Observaciones y Aserciones |
|:--:|---|---|:--:|---|
| **T01** | Integridad de columnas DDL H02 | Base de Datos / Esquema | **PASS** | Columnas `CostoPorKgGuardado`, `Co2PorKgGuardado`, `FechaSnapshotUtc` y `OrigenSnapshot` verificadas en `INFORMATION_SCHEMA.COLUMNS`. |
| **T02** | Inicialización de datos legados | Migración / DML | **PASS** | 48 componentes legados verificados con `OrigenSnapshot = 'LEGADO_SIN_VERIFICAR'` y costos/CO₂ en `NULL`. |
| **T03** | Ensayo de Rollback del esquema | Base de Datos / Reversión | **PASS** | El script de rollback elimina las columnas agregadas sin dañar las columnas originales ni los datos preexistentes. |
| **T04** | Captura automática de snapshot en inserción | Lógica de Negocio / EF6 | **PASS** | Al insertar un componente nuevo, se extrae el costo y CO₂ vigente de `Materials`, asignando `OrigenSnapshot = 'CAPTURADO'`. |
| **T05** | Inmutabilidad de snapshot ante cambio de catálogo | Dominio / Integridad | **PASS** | Al cambiar el precio de un material en catálogo de S/ 0.50 a S/ 0.99, el snapshot previamente guardado se mantiene inalterable en S/ 0.50. |
| **T06** | Preservación de snapshots unitarios en edición | Controladores / Lógica | **PASS** | Al modificar la cantidad de 350 kg a 400 kg, `CostoPorKgGuardado` y `Co2PorKgGuardado` no sufren alteración. |
| **T07** | Captura de precio vigente tras eliminar y reinsertar | Dominio / Ciclo de Vida | **PASS** | Al remover y re-insertar el componente con el catálogo modificado, se captura el nuevo precio vigente (S/ 0.99). |
| **T08** | Bloqueo de mutación en mezclas sin propietario | Seguridad / Autorización | **PASS** | Intentar agregar o modificar componentes en mezclas del catálogo público (sin owner) retorna HTTP 403 Forbidden. |
| **T09** | Bloqueo de mutación en mezclas ajenas | Seguridad / Multi-tenant | **PASS** | Usuario B intentando modificar componentes de una mezcla de Usuario A es rechazado con HTTP 403 Forbidden. |
| **T10** | Requerimiento de POST y token en Duplicar | Seguridad / HTTP | **PASS** | Invocación GET a `/Mezclas/Duplicar/1` es rechazada. Invocación POST sin token es interceptada por el filtro antifalsificación. |
| **T11** | Duplicación transaccional con preservación de snapshot | Lógica / Transacciones | **PASS** | La duplicación crea una mezcla privada para el usuario autenticado preservando exactamente los snapshots originales. |
| **T12** | Cálculo exacto de Costo y CO₂ en mezclas completas | Dominio / Matemáticas | **PASS** | `TieneSnapshotsCompletos = true`, costo y emisiones por m³ calculados con precisión matemática de 6 decimales. |
| **T13** | Propiedades nulas en mezclas legadas | Dominio / Integridad | **PASS** | Mezcla con componentes legados devuelve `TieneSnapshotsCompletos = false`, `CostoHistorico = null` y valores referenciales activos. |
| **T14** | Aislamiento de KPIs del Dashboard por usuario | Dashboard / Consultas | **PASS** | Usuario A no observa mezclas ni métricas de Usuario B; filtrado estricto por `OwnerUserId`. |
| **T15** | Cálculo de media aritmética en Dashboard (RF-42/43) | Dashboard / Métricas | **PASS** | Promedios de costo y CO₂ corresponden exactamente a la media aritmética de mezclas completas verificadas. |
| **T16** | Estado "Sin datos" en Dashboard sin mezclas completas | Dashboard / UX | **PASS** | Usuario que sólo posee mezclas legadas o vacías visualiza el badge `"Sin datos"` sin promedios fraudulentos en cero. |

**Tasa de Aprobación:** **100% (16 de 16 pruebas superadas)**  
**Tiempo de ejecución:** 12.4 segundos  
**Entorno de ejecución:** Windows PowerShell 5.1 / SQL Server LocalDB (`(LocalDb)\MSSQLLocalDB`)

---

## 7. Catálogo de Evidencias Visuales (H02-G)

Las 8 capturas de pantalla de alta resolución requeridas fueron generadas en `docs/evidencias-h02/` mediante Microsoft Edge Headless sobre el sistema web ASP.NET MVC 5 en ejecución activa:

| Archivo de Evidencia | Resolución | Tamaño | Descripción Técnica de la Vista |
|---|:---:|:---:|---|
| [01_dashboard_desktop.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/01_dashboard_desktop.png) | 1280 × 1080 | 187,553 bytes | **Dashboard Personal en Escritorio:** Visualización de las 3 tarjetas de KPIs principales (Total mezclas, Costo promedio verificado y Emisiones promedio verificadas), accesos directos al simulador/catálogo y tabla de mezclas privadas recientes. |
| [02_dashboard_mobile.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/02_dashboard_mobile.png) | 390 × 844 | 66,619 bytes | **Dashboard Personal en Dispositivo Móvil:** Comportamiento responsive optimizado en viewport de iPhone 12/13/14, adaptando las tarjetas de KPIs en cuadrícula vertical fluida y tabla con desplazamiento horizontal accesible. |
| [03_listado_mezclas_indicadores.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/03_listado_mezclas_indicadores.png) | 1280 × 1080 | 144,913 bytes | **Catálogo de Mezclas con Indicadores Históricos:** Despliegue de mezclas públicas y privadas, diferenciando claramente las mezclas con snapshots verificados mediante badges verdes y las legadas mediante badges grises, junto al botón de duplicación segura por POST. |
| [04_detalle_mezcla_completa.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/04_detalle_mezcla_completa.png) | 1280 × 1150 | 224,553 bytes | **Detalle de Mezcla con Snapshots Completos (D-09):** Tarjetas superiores indicando "Snapshot Verificado (D-09)", tabla de componentes con columnas unitarias de costo y CO₂, subtotales y estado individual "Capturado" con fecha y trazabilidad. |
| [05_detalle_mezcla_legada.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/05_detalle_mezcla_legada.png) | 1280 × 1100 | 35,941 bytes | **Detalle de Mezcla Legada Preexistente:** Cabecera con advertencia de componentes legados no verificados, costo histórico nulo desplegando valor referencial actual y columnas de snapshot unitario con guiones "—". |
| [06_captura_nuevo_componente.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/06_captura_nuevo_componente.png) | 1280 × 1150 | 224,580 bytes | **Dosificación de Componente en Servidor:** Formulario interactivo para seleccionar material y cantidad, demostrando la captura automática en backend de los valores de `Materials` sin permitir manipulación en el cliente. |
| [07_duplicacion_mezcla_post.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/07_duplicacion_mezcla_post.png) | 1280 × 1080 | 171,798 bytes | **Confirmación de Duplicación Segura por POST:** Redirección exitosa al catálogo desplegando el banner flash verde: *"Mezcla duplicada exitosamente como copia privada"*, mostrando la nueva mezcla asignada al usuario autenticado. |
| [08_rechazo_autorizacion_403.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/evidencias-h02/08_rechazo_autorizacion_403.png) | 1280 × 800 | 35,621 bytes | **Bloqueo de Seguridad HTTP 403 Forbidden:** Pantalla de acceso denegado generada ante el intento de mutar componentes en mezclas del catálogo público o mezclas de otros usuarios (D-01 / D-08). |

---

## 8. Resultados de Compilación

La solución `EcomixIA.sln` se compiló exhaustivamente con **MSBuild 17.14.18 (Visual Studio 2022 Community)** en ambos perfiles:

- **Configuración Debug (Any CPU):**
  - Compilación exitosa: `0 Errores`, `0 Advertencias`.
  - Ensamblado generado: `bin\EcomixIA.dll` (sincronizado con referencias de EF6 y ASP.NET MVC 5).
- **Configuración Release (Any CPU):**
  - Compilación exitosa: `0 Errores`, `0 Advertencias`.
  - Salida limpia lista para empaquetado y despliegue.

---

## 9. Matriz de Cumplimiento SRS v1.2 y SAD v1.1

| Requerimiento / Decisión | Descripción Formal | Estado en H00 | Estado en H02 | Evidencia de Cumplimiento |
|---|---|:---:|:---:|---|
| **RF-14** | Cálculo de costo por m³ de mezcla | Parcial (solo referencial) | **COMPLETO** | Propiedades `CostoHistoricoPorM3` (verificado) y `CostoReferencialActualPorM3` en `Mezcla.cs`; tabla detallada en `Details.cshtml`. |
| **RF-15** | Cálculo de emisiones CO₂ por m³ | Parcial (solo referencial) | **COMPLETO** | Propiedades `Co2HistoricoPorM3` (verificado) y `Co2ReferencialActualPorM3` en `Mezcla.cs`; persistencia de 6 decimales. |
| **RF-41** | Indicador de mezclas privadas en Dashboard | Pendiente | **COMPLETO** | KPI 1 en `Dashboard/Index.cshtml`, contabilizando mezclas privadas con desglose de verificadas vs legadas. |
| **RF-42** | Costo promedio de mezclas privadas | Pendiente | **COMPLETO** | KPI 2 en `Dashboard/Index.cshtml`, media aritmética de mezclas con snapshots verificados; estado "Sin datos" controlado. |
| **RF-43** | Emisiones promedio de mezclas privadas | Pendiente | **COMPLETO** | KPI 3 en `Dashboard/Index.cshtml`, media aritmética de mezclas con snapshots verificados; estado "Sin datos" controlado. |
| **D-04** | Dashboard personal de usuario autenticado | Pendiente | **COMPLETO** | `DashboardController.cs`, `DashboardViewModel.cs`, vista Razor accesible y enlace en navbar `_Layout.cshtml`. |
| **D-09** | Inmutabilidad histórica mediante snapshots | Pendiente | **COMPLETO** | Campos agregados a `MezclaComponentes`, migración SQL, precisión `decimal(18,6)` en EF6 y captura estricta en servidor. |
| **D-01 / D-08** | Aislamiento de mezclas privadas y multi-tenant | Parcial (GET vulnerable) | **COMPLETO** | Bloqueo HTTP 403 ante mutaciones ajenas, endpoint `Duplicar` exclusivo por `POST` con token antifalsificación. |

---

## 10. Trazabilidad Git y Sincronización

- **Rama de trabajo activa:** `feat/ecomix-fase-04-cierre-integracion`
- **Commits registrados y sincronizados con `origin`:**
  - `179ce99`: *H00: Recuperación y auditoría posterior a sincronización*
  - `8fd8c06`: *H01: Cierre técnico de integración ML y mejoras del simulador*
  - `93dc4b4`: `feat(persistencia): implementacion de snapshots D-09, DDL aditivo y precision decimal`
  - `714437e`: `feat(dashboard): dashboard personal D-04, kpis RF-41-43 y suite de pruebas H02`
- **Estado de secretos y archivos protegidos:**
  - `Web.Secrets.config` permanece excluido del índice de Git.
  - Ninguna credencial de conexión ni API Key fue expuesta.
  - El directorio `docs/presentacion-canva/` se conserva íntegro y sin seguimiento de Git.
  - Cero llamadas a APIs de Azure facturables durante todo el ciclo de pruebas.

---

## 11. Recomendaciones Técnicas para H03

1. **Exportación Formal de Reportes (RF-16 / RF-17):**
   - Aprovechar los nuevos snapshots inmutables (`CostoPorKgGuardado`, `Co2PorKgGuardado`, `FechaSnapshotUtc`) para emitir fichas técnicas en PDF de dosificación certificada con validez histórica y firma de procedencia.
2. **Optimización de Dosificación con Restricciones (RF-20 a RF-25):**
   - Integrar la inferencia de resistencia de H01 con los snapshots de costo y CO₂ de H02 para permitir al motor de optimización balancear resistencia esperada vs. presupuesto y huella de carbono.
3. **Mantenimiento de Índices en Base de Datos:**
   - Incorporar un índice no agrupado en `MezclaComponentes(MezclaId, OrigenSnapshot)` si el volumen de componentes supera los 10,000 registros para acelerar el cálculo de agregados en el Dashboard.

---
*Informe elaborado y certificado por Antigravity Agent el 20 de noviembre de 2026.*
