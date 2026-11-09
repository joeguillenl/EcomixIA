# EcoMix IA — Documento Técnico de Fase 3: Mejoras Finales del MVP

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación de Concreto Sostenible  
**Fecha:** 9 de noviembre de 2026  
**Rama de Trabajo:** `feat/ecomix-fase-03-mezclas-ux`  
**Commit Base:** `154136d`  
**Estado:** Implementado, Validado (100% Pruebas Satisfactorias) y Preparado para Integración

---

## 1. Objetivos de la Fase 3

La Fase 3 consolida el MVP de **EcoMix IA** mediante tres ejes fundamentales:
1. **Consistencia Visual y Experiencia de Usuario (UX):** Estandarización tipográfica con em-dash (`—`), eliminación total de caracteres corruptos (mojibake) y enriquecimiento semántico de las vistas `Materiales`, `Mezclas` y `Simulador IA` tomando como referencia los mockups aprobados.
2. **Privacidad y Persistencia de Fórmulas (Mezclas Privadas):** Extensión del modelo relacional con `OwnerUserId` (vinculado a `AspNetUsers`), garantizando aislamiento estricto entre cuentas y manteniendo el principio de **Safe Denial** sobre las mezclas legadas del sistema.
3. **Validación Técnica y Preparación para Azure:** Pruebas integrales de compilación, RBAC, integridad de base de datos SQL y análisis de preparación para despliegue en Azure bajo un presupuesto mensual $\le$ US\$ 20.00.

---

## 2. Detalle de Implementaciones por Componente

### 2.1 Fase A — Títulos de Pestañas y Codificación UTF-8
- **Solución Arquitectónica:** En `Views/Shared/_Layout.cshtml` se reemplazó la concatenación frágil con puntos medios por una evaluación Razor que estandariza el formato:
  $$\text{Formato General: } [\text{Sección}] \text{ — EcoMix IA}$$
- **Vistas Actualizadas:**
  - Portada: `EcoMix IA — Inicio`
  - Materiales: `Materiales — EcoMix IA`
  - Mis mezclas: `Mis mezclas — EcoMix IA`
  - Simulador IA: `Simulador IA — EcoMix IA`
  - Iniciar sesión: `Iniciar sesión — EcoMix IA`
  - Registrarse: `Registrarse — EcoMix IA`
- **Inmunidad a Codificación:** Se implementó el escape C# `\u2014` para el guion largo y se aseguraron todos los archivos `.cshtml` bajo formato **UTF-8 con BOM** (`utf-8-sig`), garantizando compatibilidad con el compilador de ASP.NET en Windows (evitando la interpretación errónea como Windows-1252).

### 2.2 Fase B — Materiales: Leyenda Informativa, Badges Cromáticos y RBAC
- **Tarjeta Informativa:** Se incorporó en `Views/Materiales/Index.cshtml` la tarjeta "Tipos de materiales" con 5 categorías descriptivas:
  - **Cemento:** `badge-tipo-cemento` (Fondo `#DCFCE7`, Texto `#15803D`, Borde `#BBF7D0`).
  - **Adición:** `badge-tipo-adicion` (Fondo `#DBEAFE`, Texto `#1D4ED8`, Borde `#BFDBFE`).
  - **Agregado:** `badge-tipo-agregado` (Fondo `#FEF3C7`, Texto `#B45309`, Borde `#FDE68A`).
  - **Agua:** `badge-tipo-agua` (Fondo `#CCFBF1`, Texto `#0F766E`, Borde `#99F6E4`).
  - **Aditivo:** `badge-tipo-aditivo` (Fondo `#F3E8FF`, Texto `#7E22CE`, Borde `#E9D5FF`).
- **Formateo Numérico:** Costos y factores de emisión de $\text{CO}_2$ expresados a 3 decimales (`0.000`), ej. `0.250`, `0.030`, `3.500`.
- **Control de Acceso (RBAC):**
  - Botones de acción destructiva (`Editar`, `Eliminar`) y creación (`Nuevo material`) ocultos en la interfaz para visitantes y usuarios con rol `Registrado`.
  - El botón `Ver` permanece disponible para todos los usuarios.
  - Protección server-side en `MaterialesController` mediante `[Authorize(Roles = "Administrador")]` con retorno `403 Forbidden` / `302 Redirect`.

### 2.3 Fase C — Mezclas Privadas y Persistencia Relacional
- **Diagnóstico Previo:** En la Fase 2, `MezclasController.Index()` devolvía una lista vacía bajo Safe Denial stub y `Mezcla.cs` carecía de identificador de propietario.
- **Protocolo de Seguridad (Safety Gate):**
  1. Respaldo físico de `EcomixIA` ejecutado con `WITH CHECKSUM, INIT` en `C:\Users\Admin\Desktop\Respaldos_EcoMixIA\Fase_03\EcomixIA_Pre_Fase03_Mezclas_20261109_141707.bak`.
  2. Verificación exitosa mediante `RESTORE VERIFYONLY WITH CHECKSUM`.
  3. Ensayo previo del DDL en la base de pruebas `EcomixIA_F2_Migration_Test` con prueba de rollback satisfactoria.
  4. Aplicación segura en `EcomixIA`:
     ```sql
     ALTER TABLE dbo.Mezclas ADD OwnerUserId NVARCHAR(128) NULL;
     CREATE NONCLUSTERED INDEX IX_Mezclas_OwnerUserId ON dbo.Mezclas(OwnerUserId);
     ALTER TABLE dbo.Mezclas ADD CONSTRAINT FK_dbo_Mezclas_dbo_AspNetUsers_OwnerUserId FOREIGN KEY (OwnerUserId) REFERENCES dbo.AspNetUsers(Id);
     ```
- **Lógica de Dominio en `MezclasController`:**
  - `Index()`: Si el usuario es anónimo, retorna lista vacía con invitación a iniciar sesión. Si está autenticado, filtra estrictamente `OwnerUserId == CurrentUserId`.
  - `Details(id)`, `Edit(id)`, `Delete(id)`: Verifican correspondencia de propiedad. Si `OwnerUserId == null` (mezcla legada) o pertenece a otro usuario, responde `403 Forbidden`.
  - `Create()`: Asocia automáticamente el `CurrentUserId` del usuario autenticado.
  - `Duplicar(id)`: Clona la fórmula y sus componentes bajo el usuario actual con el sufijo `(Copia)`.
- **Vista `Mis mezclas`:** Adaptada al diseño con banner de privacidad (`Tus mezclas son privadas y solo visibles para tu cuenta.`), tabla con formatos numéricos y moneda `S/`, botones de acción y pie explicativo (`Solo ves las mezclas de tu cuenta.`).

### 2.4 Fase D — Simulador IA: Guía Rápida de Componentes
- **Panel de Guía:** Incorporado en la columna derecha de `Views/Mezclas/Simulador.cshtml` con 7 filas de referencia técnica:
  1. Cemento Portland (250 – 450 kg/m³)
  2. Agua de mezclado (120 – 220 kg/m³)
  3. Escoria de alto horno (0 – 300 kg/m³)
  4. Ceniza volante / Puzolana (0 – 200 kg/m³)
  5. Agregado grueso (900 – 1300 kg/m³)
  6. Agregado fino (600 – 900 kg/m³)
  7. Aditivo superplastificante (0 – 15 kg/m³)
- **Integridad del Motor:** Preservados los 7 campos de entrada, botones de presets (Canónica, Ecológica, Alta resistencia, Inválida), cálculo reactivo de masa total, relación a/c y sustitución SCM, y contrato con el modelo `VotingEnsemble`.

---

## 3. Matriz de Pruebas de Aceptación (Fase 3)

| Código | Descripción de la Prueba | Resultado | Detalle de Validación |
| :---: | :--- | :---: | :--- |
| **UX-01** | Títulos de pestaña con guion largo (`—`) y UTF-8 limpio | **PASS** | 6 rutas verificadas; 0 tokens de mojibake detectados. |
| **UX-02** | Leyenda informativa y 5 badges en Materiales | **PASS** | Categorías Cemento, Adición, Agregado, Agua y Aditivo con colores y estilos validados. |
| **UX-03** | Formato de 3 decimales en costos y emisiones | **PASS** | Expresiones numéricas `0.000` comprobadas en tabla de materiales. |
| **UX-04** | Guía rápida de componentes en Simulador IA | **PASS** | 7 componentes con rangos típicos y recomendaciones visibles en layout responsive. |
| **SEC-01** | Restricción RBAC de escritura en Materiales | **PASS** | Botones de edición/eliminación ocultos; server-side protegido para Administrador. |
| **MIX-01** | Persistencia de mezclas privadas con `OwnerUserId` | **PASS** | Columna relacional indexada y vinculada a `AspNetUsers.Id`. |
| **MIX-02** | Aislamiento entre usuarios (User A vs User B) | **PASS** | Fórmulas de Usuario A no son visibles ni accesibles para Usuario B. |
| **MIX-03** | Safe Denial sobre mezclas legadas 1..8 | **PASS** | Peticiones a mezclas 1..8 devuelven estrictamente HTTP `403 Forbidden`. |
| **MIX-04** | Edición de mezclas protegida por propiedad | **PASS** | Edición autorizada únicamente si `OwnerUserId == CurrentUserId`. |
| **MIX-05** | Eliminación de mezclas protegida por propiedad | **PASS** | Eliminación autorizada únicamente para el propietario verificado. |
| **MIX-06** | Duplicación de fórmulas propias | **PASS** | Acción `Duplicar` genera copia integral con componentes asociados. |
| **ML-01** | 7 inputs dosificadores y 4 presets en Simulador | **PASS** | Controles de entrada operativos con cálculo en tiempo real. |
| **ML-02** | Contrato de modelo ML y avisos técnicos ACI | **PASS** | Metadatos `VotingEnsemble` y disclaimer normativo presentes. |
| **ML-03** | Safe Denial en precarga de mezclas legadas | **PASS** | Precarga rechazada con advertencia cuando la mezcla no tiene propietario verificado. |
| **DB-01** | Integridad de base de datos SQL | **PASS** | 10 materiales, mezclas históricas y 32 componentes íntegros. |
| **BUILD-01**| Compilación limpia en Debug y Release | **PASS** | MSBuild 17 ejecutado con 0 errores y 0 advertencias críticas. |
| **VIS-01** | Capturas de pantalla reales en alta resolución | **PASS** | Evidencias generadas con Edge Headless en `docs/evidencias/`. |

---

## 4. Evidencias Visuales Generadas

Las capturas fotográficas oficiales han sido archivadas en el repositorio:
1. `docs/evidencias/mvp_materiales.png`: Vista de Materiales con leyenda y tabla limpia.
2. `docs/evidencias/mvp_mis_mezclas.png`: Vista de Mis mezclas con banner de privacidad y fórmulas privadas de Usuario A.
3. `docs/evidencias/mvp_simulador.png`: Vista de Simulador de Resistencia con la nueva guía rápida de componentes.
