# EcoMix IA — Plan de Fase 0: línea base, respaldo y verificación

**Versión:** 1.0 — Plan listo para ejecutar, **no ejecutado**  
**Fecha de elaboración:** 08/11/2026 (America/Lima)  
**Referencias:** `FD03_EPIS_SRS_EcoMixIA_v1.2.md`, `SAD_EcoMixIA_v1.1.md`  
**Repositorio web:** `https://github.com/joeguillenl/EcomixIA`  
**Rama de referencia reportada:** `feat/integration-fastapi-service`, commit remoto observado `5495f92`. Verificar nuevamente antes de operar.  
**BD local comprobada por el equipo:** `(localdb)\MSSQLLocalDB`, base `EcomixIA`.

> **Alcance estricto:** F0 es de diagnóstico, conservación y evidencia. No implementa la autenticación, no ejecuta la provisión D-10, no modifica tablas, no despliega recursos, no ejecuta scripts destructivos ni fusiona ramas. Las siguientes acciones requieren al equipo en el entorno local.

## 1. Objetivo y criterio de inicio

**Objetivo:** fijar un punto de partida reproducible y proteger la BD local y el trabajo Git antes de F1 (portal público). Las fases posteriores utilizarán los requisitos/arquitectura acordados: mezclas privadas; catálogo global editable solo por Admin; dashboard sencillo; snapshots históricos; logs 30 días; límite acumulado Azure US$20; cuenta admin de mantenimiento.

**Prerrequisitos reportados:** Visual Studio 2022 con proyecto ASP.NET MVC 5 ejecutándose, SQL Server 2019 LocalDB disponible en SSMS y `DatosEjemplo.sql` aplicado. **Los resultados deben verificarse y registrarse de nuevo**; no inferir un backup anterior ni un historial de costos verificado.

## 2. Checklist de ejecución local

### F0.1 — Git: estado real y preservación

Ejecutar en PowerShell **dentro de la carpeta del repositorio web** (no en el repo ML):

```powershell
git remote -v
git branch --show-current
git status --short
git log -1 --format="%h %ci %s"
git fetch origin
git rev-list --left-right --count origin/feat/integration-fastapi-service...HEAD
git diff --stat
git diff -- Web.config
```

**Seguridad:** la última instrucción puede mostrar datos de conexión local; **no** compartir claves ni connection strings con contraseñas. La modificación local de `Web.config` para `(LocalDb)\MSSQLLocalDB` es esperable: **no sobrescribirla ni perderla**. Confirmar que `Web.Secrets.config` está ignorado, sin imprimir su contenido ni agregarlo a Git.

- [ ] Anotar rama, commit, remoto, commits adelante/atrás y archivos modificados.
- [ ] Si el árbol no está limpio, identificar y preservar cambios locales (por ejemplo, conexión LocalDB) antes de abrir rama; **no** ejecutar `reset --hard`, `clean -fd` ni `checkout --force`.
- [ ] Una vez preservados los cambios y tras verificar no se pisa trabajo ajeno, crear una rama de preparación desde la rama actual: `git switch -c chore/ecomix-fase-00-linea-base` (nombre propuesto; si ya existe, revisar en lugar de recrear).
- [ ] No hacer `push` ni `merge` por el simple hecho de preparar F0; documentar decisiones con el equipo.

### F0.2 — Base de datos: inventario **solo lectura**

En SSMS, conectar a `(localdb)\MSSQLLocalDB` y ejecutar:

```sql
USE EcomixIA;
GO
SELECT DB_NAME() AS BaseActual, @@SERVERNAME AS Instancia;
SELECT 'Materials' AS Tabla, COUNT(*) AS Filas FROM dbo.Materials
UNION ALL SELECT 'Mezclas', COUNT(*) FROM dbo.Mezclas
UNION ALL SELECT 'MezclaComponentes', COUNT(*) FROM dbo.MezclaComponentes;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;
SELECT Id, Nombre FROM dbo.Mezclas ORDER BY Id;
```

- [ ] Registrar conteos reales, tablas e identificadores básicos de las seis mezclas semilla (si siguen siendo seis).
- [ ] Comparar con `DatosEjemplo.sql` para verificar si son **plantillas de demostración**; no adjudicarles un propietario sin evidencia.
- [ ] Guardar evidencia sin correos personales, secretos ni información privada.

### F0.3 — Copia de seguridad y restauración de ensayo

1. Crear un directorio de respaldos **fuera del repositorio** (con permisos restringidos y espacio suficiente).
2. Utilizar **SSMS → EcomixIA → Tareas → Copia de seguridad...**, tipo **Completa**, destino en el directorio externo, con nombre fechado (ejemplo: `EcomixIA_F0_YYYYMMDD.bak`). Verificar permisos de escritura de LocalDB y no sobrescribir backups previos.
3. Ejecutar `RESTORE VERIFYONLY` sobre el archivo generado (comprobar legibilidad, pero **no equivale a restauración ensayada**).
4. En la misma instancia o una de prueba, **restaurar en una nueva BD**, por ejemplo `EcomixIA_F0_Verificacion`, adaptando archivos MDF/LDF con SSMS según las rutas físicas reales. **No** restaurar sobre `EcomixIA` ni usar `WITH REPLACE` sobre la BD productiva/local de trabajo.
5. Consultar conteos de `Materials`, `Mezclas` y `MezclaComponentes` en esa nueva BD y compararlos con el inventario del paso F0.2.
6. Registrar fecha, nombre del backup, verificación, conteos y cualquier incidente. Conservar la copia verificada con acceso restringido; la eliminación de la BD de prueba, si se necesita, requiere confirmación explícita.

- [ ] Backup creado.
- [ ] `RESTORE VERIFYONLY` correcto.
- [ ] Restauración de ensayo a BD **distinta** completada.
- [ ] Conteos del ensayo coincidentes.

### F0.4 — Línea base funcional sin cambios de aplicación

- [ ] Abrir `EcomixIA.sln` en Visual Studio 2022, restaurar NuGet si corresponde, compilar/recompilar.
- [ ] Iniciar con IIS Express y comprobar que `/` carga con la BD correcta.
- [ ] Abrir `Materiales/Index` y comprobar listado del catálogo (sin cambiar materiales).
- [ ] Abrir `Mezclas/Index` y el detalle de una mezcla demostrativa (sin editarla).
- [ ] Abrir `Mezclas/Simulador`; comprobar que carga. Una predicción real **solo** si existe credencial ML válida y el equipo acepta usar su API; no publicar la clave ni asumir conectividad de Azure.
- [ ] Registrar compilación, pantallas y errores reales con capturas **sin datos secretos**.
- [ ] No crear Admin: Identity 2 aún es una propuesta de F2, no funcionalidad presente en la línea base.

### F0.5 — Costos Azure (D-06), sin crear recursos

- [ ] Entrar al portal de Azure → **Cost Management + Billing** → seleccionar la suscripción estudiantil correcta.
- [ ] Inventariar recursos existentes de EcoMix IA: Azure ML, workspace, almacenamiento, Container Apps FastAPI, logs/monitoring y recursos relacionados; registrar región/SKU/estado.
- [ ] Obtener **consumo real acumulado** atribuible al proyecto y crédito restante, con **fecha de corte**, contemplando costes aún no reflejados si aplican.
- [ ] Evaluar si la publicación posterior de App Service Windows y Azure SQL realmente dispone de plan gratis/elegible para **esta suscripción**. No crearlos ahora.
- [ ] Calcular margen: `20 USD - consumo acumulado de crédito atribuible al proyecto`, sin estimar como saldo verificado un importe no consultado.
- [ ] Documentar umbrales de aviso US$10, 15, 18 y el procedimiento manual de contención. Las alertas no son un bloqueo automático de facturación.

**Prohibido en F0:** contratar SKU de pago, reactivar cómputo caro, publicar Azure SQL, crear App Service, desplegar FastAPI nuevo o enviar credenciales a capturas/documentos.

### F0.6 — Documentación y puerta de calidad

- [ ] Incorporar las versiones `FD03_EPIS_SRS_EcoMixIA_v1.2.md`, `SAD_EcoMixIA_v1.1.md` y este plan dentro de `docs/` (tras verificar que no sobrescriben archivos de otros integrantes).
- [ ] Registrar tabla de decisiones: **D-01, D-02, D-04, D-05, D-06, D-07, D-08, D-09, D-10 aprobadas; D-03 provisional**.
- [ ] Registrar resultados de los apartados anteriores en `docs/FASE_00_EVIDENCIAS.md` (nuevo, si el equipo lo aprueba) y guardar imágenes en carpeta `docs/evidencias/fase-00/`.
- [ ] Revisar cambios `git diff --check` y `git status`; no incluir backups `.bak`, archivos `.mdf`, secretos ni credenciales.
- [ ] Preparar commit documental pequeño y solicitud de revisión del compañero antes del push/merge. No modificar `master` sin acuerdo.

## 3. Matriz de entrega F0

| Evidencia | Condición de aceptación |
|---|---|
| E-F0-01 Git | Rama, SHA, cambios locales y estado remoto registrados; configuración local protegida |
| E-F0-02 Inventario SQL | Tablas, conteos, mezcla semilla y procedencia comprobadas |
| E-F0-03 Backup | Archivo fuera de Git, con `VERIFYONLY` y prueba de restauración en BD distinta |
| E-F0-04 Smoke MVC | Build, Home, Materiales, Mezclas y Simulador comprobados sin cambiar datos |
| E-F0-05 Azure | Inventario y gasto real con fecha y margen ante límite US$20; sin nuevos cargos |
| E-F0-06 Docs | SRS/SAD y decisiones archivados; sin secretos, sin cambios de lógica |

**Criterio de salida:** todas las evidencias anteriores revisadas por el equipo. Si falta alguna, F0 queda **en curso**, no cerrada.

## 4. Después de F0: orden de desarrollo

- **F1 — Portal público (local):** página de bienvenida, carrusel con tres imágenes autorizadas, navbar por estado, responsive; sin exponer vistas privadas ni cambiar BD.
- **F2 — Identidad y autorización:** Identity 2 + OWIN, registro por dominios permitidos, confirmación D-03, roles, seguridad de rutas; **D-10** primera provisión Admin manual.
- **F3 — Mezclas y catálogo:** privacidad por usuario y componentes, plantillas de demo verificadas, precio/factor CO₂ congelados al guardado, dashboard básico, catálogo solo Admin para escritura.
- **F4 — Simulador:** mini gráfico 7/28d, advertencias y textos de interpretación; no persistir predicciones.
- **F5 — Administración:** usuarios, estadísticas agregadas, logs sanitizados y depuración por 30 días.
- **F6 — Azure:** solo tras pruebas locales y verificación de consumo y elegibilidad dentro del techo US$20.

## 5. Decisiones y dependencias residuales

- **D-03 (provisional):** escoger un proveedor de correo, confirmar remitente autorizado, cuota gratuita, entregabilidad y mecanismos de seguridad. **No bloquea F0 ni F1 local**, pero impide cerrar F2 de producción sin verificación real.
- **D-10:** no solicitar todavía correo ni contraseña real para un Administrador. Es información sensible que se configurará **solo en el entorno del operador** cuando F2 lo necesite.
- **Mezclas históricas:** datos de ejemplo existentes no tienen procedencia de precios antiguos; D-09 exige distinguir `LEGADO_SIN_VERIFICAR` antes de presentarlos como snapshots auténticos.
- **Futuro despliegue:** confirmar costos reales y elegibilidad Azure; ningún plan gratuito o presupuesto debe tratarse como garantizado sin revisión de la suscripción.

**Estado de esta entrega:** plan F0 elaborado, documentos preparados; **ninguna acción ha sido ejecutada en el repositorio, SSMS o Azure del usuario desde este documento**.
