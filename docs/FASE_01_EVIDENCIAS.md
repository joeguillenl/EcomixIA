# EcoMix IA — Evidencias de Ejecución: Fase 1 (Portal Público e Identidad Visual)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Optimización de Mezclas de Concreto Ecológico  
**Repositorio:** `https://github.com/joeguillenl/EcomixIA`  
**Directorio local:** `C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema`  
**Rama activa:** `feat/ecomix-fase-01-portal-publico`  
**Commit base:** `2c9466f8e70eb3745c432328703da9e20601e389` (`2c9466f`)  
**Fecha de registro F1.1:** 09/11/2026 (America/Lima)  
**Fecha de registro F1.2:** 09/11/2026 (America/Lima)  
**Fecha de revisión UTF-8 y preparación F1.3:** 09/11/2026 (America/Lima)  
**Fecha de registro F1.3:** 09/11/2026 (America/Lima)  
**Fecha de registro F1.4:** 09/11/2026 (America/Lima)  
**Fecha de registro F1.5:** 09/11/2026 (America/Lima)  
**Estado general Fase 1:** **FASE 1 COMPLETADA Y APROBADA** (F1.1, F1.2, F1.3, F1.4, F1.5)  

---

## 1. Resumen Ejecutivo de la Subetapa F1.1

La subetapa **F1.1 — Diseño del layout y navegación responsive** tuvo como objetivo modernizar la plantilla maestra (`_Layout.cshtml`) y la hoja de estilos global (`site.css`) del sistema EcoMix IA, estableciendo una identidad visual profesional de ingeniería civil y sostenibilidad, garantizando accesibilidad universal y manteniendo retrocompatibilidad total con las vistas operativas preexistentes.

### Delimitación estricta del alcance en F1.1
* **Archivos modificados:**
  1. `Views/Shared/_Layout.cshtml` (Reestructuración semántica HTML5, navegación responsive, skip-link, alerts TempData y pie de página institucional).
  2. `Content/site.css` (Modularización en 11 secciones, paleta mineral/sostenibilidad, focus states, media queries y preservación de clases legacy).
* **Archivos preservados sin alteración:** Controladores (`HomeController`, `MaterialesController`, `MezclasController`), modelos de datos, vistas específicas (`Views/Home/Index.cshtml`, `Views/Materiales/*`, `Views/Mezclas/*`), cadenas de conexión (`Web.config` local preservado sin commit), migraciones EF6 y base de datos SQL Server LocalDB.
* **Consumo en la nube:** Cero llamadas a servicios de inferencia externos ni recursos Azure, respetando de forma estricta la salvaguarda presupuestaria (D-06).

---

## 2. Criterios de Diseño e Identidad Institucional (D-05)

En estricto cumplimiento de la decisión arquitectural **D-05**, la identidad visual de EcoMix IA se desvincula por completo de signos distintivos, logotipos o tipografías comerciales corporativas de terceros (Cementos Yura S.A.), adoptando en su lugar una estética técnica inspirada en la ingeniería de materiales, la geología del sur del Perú y la sostenibilidad ambiental.

### 2.1 Paleta de Color de Ingeniería
| Muestra | Nombre de Variable | Código HEX | Propósito y Semántica |
| :---: | :--- | :--- | :--- |
| ![#0a1b30](https://placehold.co/15x15/0a1b30/0a1b30.png) | `--ecomix-navy-dark` | `#0a1b30` | Azul marino profundo: Fondo de navbar superior y pie de página institucional. |
| ![#0f2744](https://placehold.co/15x15/0f2744/0f2744.png) | `--ecomix-navy` | `#0f2744` | Azul marino primario: Identidad corporativa, encabezados técnicos y títulos. |
| ![#1b3d68](https://placehold.co/15x15/1b3d68/1b3d68.png) | `--ecomix-navy-light` | `#1b3d68` | Azul marino secundario: Degradados sutiles y bordes de realce. |
| ![#15803d](https://placehold.co/15x15/15803d/15803d.png) | `--ecomix-green` | `#15803d` | Verde sostenibilidad: Botones primarios, enlaces activos y acentos ecológicos. |
| ![#166534](https://placehold.co/15x15/166534/166534.png) | `--ecomix-green-hover` | `#166534` | Verde oscuro: Estados `:hover` y `:active` de botones e interactivos. |
| ![#4ade80](https://placehold.co/15x15/4ade80/4ade80.png) | `--ecomix-green-vibrant` | `#4ade80` | Verde brillante: Acento tipográfico de la marca `IA` e iconos de éxito. |
| ![#0f172a](https://placehold.co/15x15/0f172a/0f172a.png) | `--ecomix-slate-900` | `#0f172a` | Basalto mineral: Tipografía de alta legibilidad y contraste. |
| ![#64748b](https://placehold.co/15x15/64748b/64748b.png) | `--ecomix-slate-500` | `#64748b` | Sílice / cemento: Textos secundarios, metadatos y etiquetas. |
| ![#e2e8f0](https://placehold.co/15x15/e2e8f0/e2e8f0.png) | `--ecomix-border` | `#e2e8f0` | Borde estructural: Separadores de tablas, tarjetas y paneles. |
| ![#f8fafc](https://placehold.co/15x15/f8fafc/f8fafc.png) | `--ecomix-canvas` | `#f8fafc` | Lienzo neutro: Fondo general del cuerpo de la aplicación. |
| ![#d97706](https://placehold.co/15x15/d97706/d97706.png) | `--ecomix-amber` | `#d97706` | Ámbar técnico: Alertas de atención y foco accesible para teclado. |
| ![#dc2626](https://placehold.co/15x15/dc2626/dc2626.png) | `--ecomix-danger` | `#dc2626` | Rojo normativo: Indicadores de error y rechazo de dosificación. |

### 2.2 Tipografía e Iconografía
* **Tipografía principal:** Fuente moderna sans-serif `Inter` mediante Google Fonts (pesos 300 a 800) con fallback nativo seguro del sistema (`system-ui`, `-apple-system`, `Segoe UI`, `Roboto`, `Arial`).
* **Iconografía:** `Bootstrap Icons 1.11.3` cargado vía CDN con etiquetas semánticas (`aria-hidden="true"` para elementos decorativos).

---

## 3. Detalle de Cambios en la Plantilla Maestra (`_Layout.cshtml`) en F1.1

El archivo [Views/Shared/_Layout.cshtml](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Views/Shared/_Layout.cshtml) fue refactorizado íntegramente con los siguientes componentes:

1. **Atributos de idioma y metadatos:**
   - Inclusión de `<html lang="es">`.
   - Etiquetas `<meta name="description">` orientadas a ingeniería y `<meta name="theme-color" content="#0a1b30">`.
2. **Mecanismo de accesibilidad para teclado (Skip Link):**
   - Enlace inicial `<a href="#contenidoPrincipal" class="ecomix-skip-link">Saltar al contenido principal</a>` que permanece oculto fuera de pantalla y se posiciona en el encabezado visible al recibir foco (`:focus-visible`).
3. **Navegación principal superior (`.ecomix-nav`):**
   - Barra fija superior (`sticky-top`) con gradiente marino profundo.
   - Marca oficial `EcoMix IA` con icono de capas (`bi-layers-half`), texto con acento verde esmeralda y badge descriptivo `Concretos Sostenibles`.
   - Botón toggler para pantallas táctiles/móviles con atributos de accesibilidad ARIA (`aria-controls`, `aria-expanded`, `aria-label`).
   - Detección activa de ruta en tiempo de ejecución (`ViewContext.RouteData`) para marcar visualmente el elemento del menú correspondiente.
   - Enlace diferenciado para el **Simulador IA** (`.nav-link-simulator`) con realce visual verde tecnológico.
   - Indicador de estado del prototipo (`.ecomix-mode-pill`) con el texto `Demostración Local`, evitando la inclusión de enlaces de autenticación ficticios antes de la implementación formal en Fase 2 (D-10).
4. **Contenedor principal y sistema de alertas:**
   - `<main id="contenidoPrincipal" class="container my-4 flex-grow-1" role="main">`.
   - Contenedores de alerta para `TempData["Mensaje"]` (éxito) y `TempData["Error"]` (peligro) con iconos vectoriales y botón de cierre nativo Bootstrap.
5. **Pie de página institucional, técnico y ético (D-05):**
   - Identificación académica completa: **Universidad Privada de Tacna (UPT)**, Facultad de Ingeniería, Escuela Profesional de Ingeniería de Sistemas, asignatura Programación Web II (2026).
   - Enlaces de navegación secundaria a todas las secciones activas del sistema.
   - Resumen del marco normativo con descripción verificable del servicio en producción (*Predicción de resistencia mediante modelo ML AutoML VotingEnsemble*).
   - **Nota de descargo formal (D-05):** Texto explícito declarando el propósito de investigación académica, inspiración regional de insumos y ausencia total de vinculación comercial con Cementos Yura S.A.
   - Barra de copyright dinámica con indicación de versión (`v1.1`) y fase de desarrollo (`Fase 1: Portal Público`).

---

## 4. Detalle de Cambios en la Hoja de Estilos (`Content/site.css`) en F1.1

El archivo [Content/site.css](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Content/site.css) fue estructurado en secciones modulares independientes:

* **Sección 1 — Variables CSS globales:** Paleta de colores completa, escala de grises minerales, estados de alerta, variables de retrocompatibilidad y mapeo con `--bs-*`.
* **Sección 2 — Reset y base:** Configuración de `box-sizing`, tipografía suavizada antialiasing, `min-height: 100vh` y layout flexbox vertical con `mt-auto` para asegurar que el footer permanezca pegado al fondo en páginas con poco contenido.
* **Sección 3 — Accesibilidad Skip Link:** Posicionamiento absoluto fuera de vista con transición suave al recibir foco por teclado y borde de alto contraste.
* **Sección 4 — Navegación (`.ecomix-nav`):** Estilos para la barra fija, marca corporativa, toggler con realce de foco, enlaces regulares, enlace destacado del simulador y badge del modo de ejecución.
* **Sección 5 — Alertas del sistema (`.ecomix-alert`):** Tarjetas con bordes sutiles, tipografía legible y paleta armónica.
* **Sección 6 — Encabezados y paneles legacy:** Preservación total de estilos funcionales para `.page-header`, `.panel`, `.panel-body`, `.stat-card`, `.stat-icon`, `.stat-icon.accent`, `.stat-label` y `.stat-value`.
* **Sección 7 — Sección Hero preexistente:** Preservación de la clase `.hero` de la portada actual con degradado naval moderno, círculo decorativo radial y tipografía legible.
* **Sección 8 — Tablas de datos (`.table-panel`):** Cabeceras elegantes con fondo mineral claro, filas con efecto hover, soporte para celdas numéricas alineadas a la derecha (`.num`) y scroll horizontal controlado.
* **Sección 9 — Etiquetas, estados vacíos y formularios:** Clases `.tag`, `.empty-state`, estilos para `.btn-primary`, `.btn-outline-primary`, campos de formulario `.form-control` y etiquetas `.form-label`.
* **Sección 10 — Pie de página profesional (`.ecomix-footer`):** Estilo nocturno de alto contraste, encabezados en mayúsculas, enlaces con efecto subrayado en hover, caja de descargo con borde sutil y línea divisoria inferior.
* **Sección 11 — Reglas responsivas:** Media queries para móviles (`< 768px`), tablets (`768px - 991px`) y monitores de escritorio (`>= 992px`).

---

## 5. Matriz de Verificación Responsive en F1.1

| Dispositivo / Resolución | Elemento Verificado | Comportamiento Observado | Estado |
| :--- | :--- | :--- | :---: |
| **Desktop (1440px)** | Barra de navegación | Marca completa visible con badge, enlaces alineados horizontalmente a la izquierda, pill de estado a la derecha. | Conforme |
| **Desktop (1440px)** | Contenedor principal | Ancho máximo centrado con espaciado vertical armónico (`my-4`). | Conforme |
| **Desktop (1440px)** | Pie de página | Disposición en 3 columnas amplias + caja de descargo institucional de ancho completo + copyright inferior. | Conforme |
| **Tablet (768px - 991px)** | Barra de navegación | Transición adecuada al ancho del viewport sin desbordamientos tipográficos. | Conforme |
| **Tablet (768px - 991px)** | Paneles y estadísticas | Distribución en rejilla de 2 columnas con márgenes legibles. | Conforme |
| **Tablet (768px - 991px)** | Tablas de datos | Visualización completa sin truncamiento forzado de columnas. | Conforme |
| **Mobile (390px)** | Botón hamburguesa | Toggler visible, borde sutil con contraste, activación accesible mediante teclado y toque. | Conforme |
| **Mobile (390px)** | Menú desplegado | Enlaces colapsados verticalmente con área táctil superior a 44px de altura por ítem. | Conforme |
| **Mobile (390px)** | Hero y encabezados | Reducción tipográfica responsive (`1.4rem`), paddings reducidos a `1.25rem` sin pérdida de contenido. | Conforme |
| **Mobile (390px)** | Tablas operativas | Contenedor con `overflow-x: auto` permitiendo deslizamiento táctil horizontal sin romper el layout exterior. | Conforme |
| **Mobile (390px)** | Pie de página | Flujo vertical apilado a columna única, textos centrados y espaciado cómodo. | Conforme |

---

## 6. Controles Técnicos de Accesibilidad Comprobados (F1.1)

> [!NOTE]
> Las evaluaciones presentadas describen los controles técnicos efectivamente comprobados en la implementación. No constituyen una certificación formal de auditoría WCAG externa.

| Criterio de Accesibilidad | Requisito Técnico | Implementación Verificada | Estado de Verificación |
| :--- | :--- | :--- | :---: |
| **Evitar bloques repetitivos** | Mecanismo para saltar bloques de navegación. | Enlace `.ecomix-skip-link` con destino `#contenidoPrincipal`, visible ante foco de teclado. | Control comprobado |
| **Contraste de color** | Relación de contraste de texto normal >= 4.5:1. | Barra y footer (blanco sobre `#0a1b30` / `#0f2744`, ratio > 12:1). Cuerpo (`#0f172a` sobre `#f8fafc`, ratio > 14:1). | Control comprobado |
| **Foco visible por teclado** | Componentes interactivos con indicador de foco claro. | Regla `:focus-visible` explícita con contorno verde (`#86efac` o `#15803d`) y offset de 2px en interactivos. | Control comprobado |
| **Nombre, función y valor** | Roles y etiquetas en controles de interfaz. | `aria-label`, `aria-controls`, `aria-expanded` en toggler y navegación; `aria-hidden="true"` en iconos decorativos. | Control comprobado |
| **Idioma programático** | Identificación del idioma de la página. | Atributo `lang="es"` definido en la etiqueta raíz `<html>`. | Control comprobado |

---

## 7. Resultados de Compilación y Pruebas de Regresión F1.1 (SM-01 a SM-08)

### 7.1 Compilación de la Solución
* **Herramienta:** MSBuild 17.14.18 (Visual Studio 2022 Community).
* **Comando:** `MSBuild.exe EcomixIA.sln /p:Configuration=Debug /p:Platform="Any CPU" /v:m`
* **Resultado:** Compilación exitosa (`EcomixIA.dll`). **0 Errores**, **0 Advertencias**. Código de salida: `0`.

### 7.2 Resultados de las Pruebas de Humo F1.1
Todas las pruebas fueron ejecutadas contra el servidor local IIS Express (`https://localhost:44357/`), validando código de respuesta HTTP 200, inclusión de los nuevos componentes de layout y retrocompatibilidad del contenido funcional.

| ID | Ruta del Endpoint | Nombre de la Prueba | HTTP | Patrón Clave | Skip-Link | Navbar | Footer | Aviso D-05 | Meta UPT |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **SM-01** | `/` | Portada / Home Index | `200 OK` | `EcoMix IA` | Sí | Sí | Sí | Sí | Sí |
| **SM-02** | `/Materiales/Index` | Catálogo de Materiales | `200 OK` | `Materiales` | Sí | Sí | Sí | Sí | Sí |
| **SM-03** | `/Materiales/Details/1` | Detalle de Material 1 (Cemento) | `200 OK` | `Cemento` | Sí | Sí | Sí | Sí | Sí |
| **SM-04** | `/Mezclas/Index` | Historial de Mezclas | `200 OK` | `Mezclas` | Sí | Sí | Sí | Sí | Sí |
| **SM-05** | `/Mezclas/Details/1` | Detalle Mezcla 1 (Con componentes) | `200 OK` | `Materiales por m` | Sí | Sí | Sí | Sí | Sí |
| **SM-06** | `/Mezclas/Details/7` | Detalle Mezcla 7 (Sin componentes) | `200 OK` | `no tiene materiales` | Sí | Sí | Sí | Sí | Sí |
| **SM-07** | `/Mezclas/Simulador` | Simulador IA (Formulario vacío) | `200 OK` | `Simulador` | Sí | Sí | Sí | Sí | Sí |
| **SM-08** | `/Mezclas/Simulador?mezclaId=1` | Simulador IA (Precargado con mezcla 1) | `200 OK` | `Simulador` | Sí | Sí | Sí | Sí | Sí |

---

## 8. Verificación de Integridad de la Base de Datos LocalDB en F1.1

Se comprobó la persistencia y estado de los datos en la instancia `(localdb)\MSSQLLocalDB`, base de datos `EcomixIA`, certificando que los cambios de diseño visual no tuvieron ningún impacto colateral en el almacenamiento:

| Tabla en `EcomixIA` | Registros Esperados | Registros Obtenidos | Estado de Integridad |
| :--- | :---: | :---: | :---: |
| `dbo.Materials` | 10 | 10 | Intacto |
| `dbo.Mezclas` | 8 | 8 | Intacto |
| `dbo.MezclaComponentes` | 32 | 32 | Intacto |
| `dbo.__MigrationHistory` | 1 | 1 | Intacto |

---

## 9. Matriz de Trazabilidad y Cumplimiento de Decisiones de Arquitectura (SRS v1.2)

Correspondencia corregida y formalizada según el documento `docs/FD03_EPIS_SRS_EcoMixIA_v1.2.md`:

| Código | Decisión Aprobada en SRS v1.2 | Implementación y Cumplimiento en Fase 1 | Estado |
| :---: | :--- | :--- | :---: |
| **D-01** | Privacidad de mezclas por usuario (seguridad por objeto, aislamiento) | El layout y la portada no exponen mezclas de usuarios ni vulneran la privacidad de datos. | Conforme |
| **D-02** | Catálogo global de materiales (consulta pública/registrados, CRUD exclusivo admin) | Enlaces al catálogo de materiales preservados sin alterar permisos de administración. | Conforme |
| **D-03** | Envío transaccional de correo (modalidad provisional, proveedor pendiente) | No aplicable a F1.1/F1.2; no se introducen dependencias de correo electrónico. | No aplicable en F1 |
| **D-04** | Dashboard personal ligero de mezclas propias sin persistencia de predicciones | No aplicable a F1.1/F1.2; navegación preparada sin enlaces ficticios a dashboards privados. | No aplicable en F1 |
| **D-05** | Identidad propia EcoMix IA inspirada en geología regional, sin afiliación Yura | Paleta mineral independiente adoptada y aviso explícito de no afiliación corporativa en footer. | Conforme |
| **D-06** | Consumo acumulado máximo de US$20 en Azure for Students | Cero consumo cloud durante el desarrollo y pruebas; ejecución 100% en LocalDB e IIS Express. | Conforme |
| **D-07** | Retención de 30 días para `AuditEvents` | No aplicable a F1.1/F1.2; reservado para F5 según el SRS. | No aplicable en F1 |
| **D-08** | Administrador sin lectura de mezclas ajenas y auditoría minimizada | No se introducen vistas administrativas que rompan el aislamiento de mezclas ajenas. | Conforme |
| **D-09** | Inmutabilidad de precios y factores CO₂ capturados por componente | No aplicable a vistas públicas; esquema y modelos de datos preservados intactos. | No aplicable en F1 |
| **D-10** | Provisión manual y segura del primer Administrador fuera de código | Se sustituyeron enlaces prematuros de login por el badge informativo `Demostración Local`. | Conforme |

---

## 10. Conclusión de la Subetapa F1.1
La subetapa **F1.1** fue aprobada formalmente tras completar la reestructuración del layout general y la verificación completa de pruebas de humo e integridad SQL.

---

## 11. Registro de Ejecución F1.2: Desarrollo de la Página Principal Promocional

### 11.1 Resumen Ejecutivo de F1.2
La subetapa **F1.2 — Portada promocional del portal público EcoMix IA** rediseñó íntegramente la vista inicial del sistema (`Views/Home/Index.cshtml`) para transformarla en una portada promocional estructurada, accesible y de alta calidad visual. La nueva página presenta el propósito del sistema, sus funcionalidades clave, su flujo de trabajo en tres pasos y su compromiso académico y ambiental, cumpliendo estrictamente con no anticipar el carrusel con imágenes (reservado para F1.3) ni la autenticación (Fase 2).

### 11.2 Archivos Modificados en F1.2
1. **`Views/Home/Index.cshtml`:** Rediseño completo en cuatro secciones semánticas:
   * **Sección 1 — Hero promocional (`.hero-promo`):** Título *EcoMix IA*, subtítulo *Diseño inteligente de mezclas de concreto sostenible*, descripción técnica formal, botón primario *Conocer funcionalidades* (anclaje a `#funcionalidades`), enlace secundario *Explorar simulador IA* (hacia `@Url.Action("Simulador", "Mezclas")`) con indicación explícita de modo de demostración local verificado.
   * **Sección 2 — Funcionalidades principales (`#funcionalidades`):** Tres tarjetas Bootstrap con Bootstrap Icons y clases de diseño:
     1. *Catálogo de materiales:* Gestión de insumos, densidades, costos unitarios y factores de emisión de CO₂.
     2. *Diseño y evaluación de mezclas:* Dosificación por m³, balance de componentes, costos y cálculo de huella de carbono acumulada.
     3. *Predicción mediante IA:* Estimación preliminar de resistencia a compresión a 7 y 28 días con el modelo ML integrado.
   * **Sección 3 — ¿Cómo funciona EcoMix IA? (`#como-funciona`):** Flujo visual en tres pasos (Paso 01: Consultar materiales, Paso 02: Configurar dosificación, Paso 03: Evaluar indicadores y predicciones), con recuadro aclaratorio diferenciando cálculos convencionales aritméticos de predicciones estadísticas del modelo ML, sin afirmar la existencia de un optimizador automático autónomo.
   * **Sección 4 — Propósito académico y ambiental (`#proposito-academico`):** Enfoque formativo UPT, contexto regional sur peruano (Tacna/Arequipa), independencia institucional (D-05) y la nota obligatoria de alcance técnico: *"Las estimaciones computacionales no sustituyen los ensayos de laboratorio ni las validaciones técnicas requeridas para aplicaciones estructurales."*
2. **`Content/site.css`:**
   * Adición de la **Sección 7A (Portada Promocional)**: Estilos para `.hero-promo`, `.hero-badge`, `.btn-ecomix-primary`, `.btn-outline-ecomix-light`, `.section-kicker`, `.feature-card`, `.feature-icon`, `.step-card`, `.step-badge`, `.academic-card` y `.scope-note`.
   * Inclusión de reglas responsivas en la **Sección 11** para viewports móviles (`< 768px`) y tablets (`768px - 991px`).
3. **`Views/Shared/_Layout.cshtml`:**
   * Corrección de trazabilidad en el pie de página institucional: sustitución de menciones preliminares a XGBoost/Random Forest/NSGA-II por la descripción verificable del servicio en producción: *"Predicción de resistencia mediante modelo ML AutoML VotingEnsemble"*.

### 11.3 Resultados de Compilación con MSBuild
* **Herramienta:** MSBuild 17.14.18 (Visual Studio 2022 Community)
* **Comando:** `MSBuild.exe EcomixIA.sln /p:Configuration=Debug /p:Platform="Any CPU" /v:m`
* **Resultado:** **0 Errores**, **0 Advertencias**. Código de salida: `0`.
* **Binario:** `bin\EcomixIA.dll` actualizado satisfactoriamente.

### 11.4 Matriz de Pruebas Específicas F1.2 (F1.2-01 a F1.2-08)

| ID | Nombre de la Prueba | Criterio de Verificación | Resultado Observado | Estado |
| :---: | :--- | :--- | :--- | :---: |
| **F1.2-01** | Disponibilidad HTTP portada | `GET /` responde `HTTP 200 OK`. | StatusCode = 200 | Conforme |
| **F1.2-02** | Título y subtítulo en Hero | Título "EcoMix IA" y subtítulo "Diseño inteligente de mezclas de concreto sostenible". | Confirmado en HTML | Conforme |
| **F1.2-03** | Tres tarjetas de funcionalidades | Presencia de tarjetas: Catálogo de materiales, Diseño y evaluación de mezclas, Predicción mediante IA. | 3 tarjetas confirmadas | Conforme |
| **F1.2-04** | Sección de funcionamiento | Sección "¿Cómo funciona EcoMix IA?" con Paso 01, Paso 02 y Paso 03 estructurados. | Flujo de 3 pasos validado | Conforme |
| **F1.2-05** | Enlaces internos ancla | Botón "Conocer funcionalidades" apunta a `#funcionalidades` y anclaje `#como-funciona` activo. | Anclajes validados | Conforme |
| **F1.2-06** | Enlace a Simulador IA | Botón secundario enlaza a `/Mezclas/Simulador` con distintivo de demostración local. | Enlace y badge verificados | Conforme |
| **F1.2-07** | Ausencia de promesas no implementadas | Aclaración explícita: no incluye optimización automática autónoma ni sustituye probetas físicas. | Verificación negativa limpia | Conforme |
| **F1.2-08** | Privacidad de datos en HTML | Cero filtraciones de contadores de mezclas de usuarios o datos privados de cuentas. | Cero fugas en HTML | Conforme |

### 11.5 Pruebas de Regresión de la Línea Base (SM-01 a SM-08)

| ID | Endpoint | Nombre de Prueba | HTTP | Patrón Clave Verificado | Skip-Link | Navbar | Footer | AutoML Footer |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **SM-01** | `/` | Portada / Home Index | `200 OK` | `EcoMix IA` / `Diseño inteligente` | Sí | Sí | Sí | Sí |
| **SM-02** | `/Materiales/Index` | Catálogo de Materiales | `200 OK` | `Materiales` | Sí | Sí | Sí | Sí |
| **SM-03** | `/Materiales/Details/1` | Detalle Material (Cemento) | `200 OK` | `Cemento` | Sí | Sí | Sí | Sí |
| **SM-04** | `/Mezclas/Index` | Historial de Mezclas | `200 OK` | `Mezclas` | Sí | Sí | Sí | Sí |
| **SM-05** | `/Mezclas/Details/1` | Detalle Mezcla 1 (Con componentes) | `200 OK` | `Materiales por m` | Sí | Sí | Sí | Sí |
| **SM-06** | `/Mezclas/Details/7` | Detalle Mezcla 7 (Sin componentes) | `200 OK` | `no tiene materiales` | Sí | Sí | Sí | Sí |
| **SM-07** | `/Mezclas/Simulador` | Simulador IA (Formulario vacío) | `200 OK` | `Simulador` | Sí | Sí | Sí | Sí |
| **SM-08** | `/Mezclas/Simulador?mezclaId=1` | Simulador IA (Precargado con Id 1) | `200 OK` | `Simulador` | Sí | Sí | Sí | Sí |

### 11.6 Verificación Responsive y Declaración de Evidencia Visual
* **Desktop (1440px):** Hero con padding de `3.5rem`, ancho máximo de lectura controlado (`850px`), tarjetas de funcionalidades en 3 columnas balanceadas (`col-md-4`), flujo horizontal de pasos y tarjeta académica con distribución `8/4`.
* **Tablet (768px):** Padding adaptado (`2.75rem`), colapso armónico de cuadrícula a dos o tres columnas según ancho disponible, tipografía responsive.
* **Mobile (390px):** Hero compacto (`2.25rem`), título a `2.25rem`, tarjetas en columna única vertical a ancho completo, botones táctiles con altura > 44px para facilitar la pulsación y eliminación de cualquier scroll horizontal involuntario.
* **Declaración de verificación visual:** La ejecución de capturas de pantalla mediante Chrome headless (`--headless --screenshot`) fue intentada pero no está disponible en este entorno de terminal Windows sin subsistema gráfico interactivo. La verificación responsive fue realizada de forma analítica comprobando las reglas de `Content/site.css`, la jerarquía de rejilla Bootstrap 5.3 y la estructura semántica del DOM.

### 11.7 Integridad de la Base de Datos SQL Server LocalDB
Verificación directa en la instancia `(localdb)\MSSQLLocalDB`, base de datos `EcomixIA`:
* `dbo.Materials`: 10 registros (Intacto).
* `dbo.Mezclas`: 8 registros (Intacto).
* `dbo.MezclaComponentes`: 32 registros (Intacto).
* `dbo.__MigrationHistory`: 1 registro (Intacto).

### 11.8 Auditoría y Salvaguarda de Presupuesto Azure (D-06)
* Durante F1.2 no se emitieron solicitudes HTTP hacia Azure Container Apps ni hacia la API FastAPI de inferencia.
* No se modificaron, aprovisionaron ni eliminaron recursos de la suscripción Azure for Students.
* Gasto incurrido en F1.2: **US$ 0.00**.

### 11.9 Veredicto de la Puerta de Calidad F1.2
* **Estado:** **APROBADA**.
* **Condición de avance a F1.3:** Se suspende la ejecución hasta la revisión y autorización expresa del usuario para iniciar F1.3 (Diseño e implementación del carrusel informativo con recursos gráficos autorizados).

---

## 12. Corrección de Codificación y Preparación de Recursos Gráficos

### 12.1 Auditoría Técnica de Codificación y Diagnóstico Causa Raíz
Se ejecutó una auditoría exhaustiva sobre los 47 archivos fuente del proyecto (`.cshtml`, `.css`, `.js`, `.cs`, `.md`), distinguiendo con rigor entre errores intrínsecos de los archivos y errores de visualización en terminal:

1. **Estado en disco:** Se constató que ningún archivo del proyecto contenía secuencias directas de mojibake (`C3 83`, `C3 82`) ni caracteres de sustitución (`EF BF BD` / `U+FFFD`). Todos los caracteres en español (tildes, `ñ`) y símbolos técnicos (`CO₂`, `m³`) estaban almacenados como secuencias UTF-8 válidas.
2. **Causa raíz en ASP.NET MVC (.NET Framework 4.7.2):** En ausencia de una marca de orden de bytes UTF-8 (BOM: `0xEF, 0xBB, 0xBF`) y sin configuración explícita de `fileEncoding` en `Web.config`, el compilador de vistas Razor (`System.Web.Razor`) lee los archivos `.cshtml` utilizando la codificación por defecto del sistema operativo (`Encoding.Default` = Windows-1252 ANSI en entornos Windows en español). Al compilar la vista, el motor interpretaba cada byte de la secuencia UTF-8 como un carácter ANSI separado (e.g., `C3 B1` se leía como `Ã` y `±`). Posteriormente, al escribir la respuesta HTTP con `Content-Type: text/html; charset=utf-8`, ASP.NET re-codificaba esos caracteres en UTF-8 (`C3 83 C2 B1`), generando el problema de doble codificación (mojibake) en el cliente.
3. **Distorsión en terminal PowerShell:** Se comprobó que la consola PowerShell utilizaba la página de códigos CP 850 (Western European DOS), provocando que cadenas UTF-8 legítimas mostrasen glifos de reemplazo (``) al emitirse por stdout, aun cuando la respuesta HTTP y los archivos fuesen correctos.

### 12.2 Archivos Afectados y Correcciones Aplicadas
Se normalizó la codificación aplicando la cabecera estándar de Visual Studio **UTF-8 con BOM** (`0xEF, 0xBB, 0xBF`) a todos los archivos que carecían de ella, garantizando que el compilador Razor y el compilador C# Roslyn los reconozcan unívocamente como UTF-8:

| Archivo | Codificación Inicial | Codificación Final | Estado de Corrección |
| :--- | :---: | :---: | :---: |
| `Views/Shared/_Layout.cshtml` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Views/Home/Index.cshtml` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Views/Mezclas/Index.cshtml` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Views/Mezclas/Details.cshtml` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Views/Mezclas/Simulador.cshtml` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Controllers/MezclasController.cs` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Models/Dtos/*.cs` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Models/ViewModels/*.cs` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |
| `Services/*.cs` | UTF-8 sin BOM | UTF-8 con BOM | Corregido |

> [!NOTE]
> **Propuesta para `Web.config` (No aplicada para respetar restricciones):** Para robustez en entornos de despliegue donde no se controle el BOM de archivos futuros, se recomienda incorporar en `<system.web>`:
> ```xml
> <globalization fileEncoding="utf-8" requestEncoding="utf-8" responseEncoding="utf-8" culture="es-PE" uiCulture="es-PE" />
> ```
> Dicho cambio no fue aplicado en `Web.config` respetando la directriz estricta de no modificar la configuración local en esta etapa.

### 12.3 Evidencia de Renderizado HTTP en Producción Local
Se verificó el contenido a nivel de bytes mediante solicitudes HTTP directas a IIS Express (`https://localhost:44357/` y `http://localhost:62778/`):

* **Cabecera HTTP:** `Content-Type: text/html; charset=utf-8` confirmada en todas las respuestas.
* **Secuencias multibyte UTF-8 verificadas en payload:**
  * `"Diseño inteligente de mezclas"`: bytes `44 69 73 65 C3 B1 6F` (`ñ` = `C3 B1`).
  * `"emisiones de CO₂"`: bytes `43 4F E2 82 82` (`₂` = `E2 82 82`, subíndice Unicode `U+2082`).
  * `"predicción de resistencia"`: bytes `C3 B3` (`ó`).
  * `"Catálogo de materiales"`: bytes `C3 A1` (`á`).
  * `"todavía no tiene materiales"`: bytes `C3 AD` (`í` = `C3 AD`).
  * `"Dosificación por m³ de Concreto"`: bytes `C2 B3` (`³` = `C2 B3`, superíndice Unicode `U+00B3`).
  * `"Contraseña"`: término auditado y confirmado no presente en la interfaz actual (autenticación diferida a Fase 2).
* **Ausencia de defectos:** Cero secuencias de doble codificación (`C3 83`, `C3 82`) y cero caracteres de sustitución (`EF BF BD`) en los 8 endpoints analizados.

### 12.4 Preparación de Recursos Gráficos para F1.3
Se estructuró y documentó la carpeta destinada al carrusel:

* **Directorio:** `Content/images/carousel/`
* **Archivo de especificaciones y control:** [Content/images/carousel/README.md](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/Content/images/carousel/README.md)
* **Archivos previstos:**
  1. `01-innovacion-concreto.webp` (Diapositiva 1: Innovación y dosificación inteligente de concreto sostenible)
  2. `02-materiales-sostenibles.webp` (Diapositiva 2: Materiales regionales, puzolanas y reducción de CO₂)
  3. `03-resistencia-concreto.webp` (Diapositiva 3: Control de resistencia f'c y análisis predictivo con IA)
* **Especificaciones técnicas:** Formato WebP, resolución 1920 × 800 px (adaptable), peso < 250 KB por imagen, espacio de color sRGB.
* **Política D-05:** Imágenes originales o con licencia libre verificada (CC0/Unsplash/Pexels con atribución), sin uso de logotipos o marcas de terceros (Cementos Yura S.A.).
* **Estado:** Completado y formalmente integrado en la subetapa F1.3.

### 12.5 Resultado de Compilación y Regresión
* **Compilación MSBuild Debug:** Código de salida `0`, 0 errores, 0 advertencias.
* **Pruebas de Humo (SM-01 a SM-08):** 8/8 superadas con HTTP 200 y cadenas verificadas.
* **Pruebas Funcionales F1.2 (F1.2-01 a F1.2-08):** 8/8 superadas.
* **Base de datos SQL Server LocalDB:** 10 materiales, 8 mezclas, 32 componentes, 1 migración (intactos).
* **Consumo presupuestario Azure (D-06):** US$ 0.00.

---

## 13. Subetapa F1.3 — Integración del Carrusel Promocional con Imágenes Originales

La subetapa **F1.3 — Integración del carrusel promocional con imágenes originales** tuvo como objetivo incorporar un componente de carrusel interactivo en la portada principal (`Views/Home/Index.cshtml`), utilizando 3 recursos gráficos originales en formato WebP con temática de ingeniería de concreto ecológico y sostenibilidad, respetando las políticas de diseño institucional (D-05), accesibilidad universal (WCAG AA), adaptabilidad responsive y preservación estricta de la integridad de base de datos e infraestructura.

### 13.1 Delimitación estricta del alcance en F1.3
* **Archivos modificados / agregados:**
  1. `Content/images/carousel/01-innovacion-concreto.webp` (Recurso gráfico original, diapositiva 1).
  2. `Content/images/carousel/02-materiales-sostenibles.webp` (Recurso gráfico original, diapositiva 2).
  3. `Content/images/carousel/03-resistencia-concreto.webp` (Recurso gráfico original, diapositiva 3).
  4. `Content/images/carousel/README.md` (Documentación técnica y registro de metadatos de las imágenes).
  5. `EcomixIA.csproj` (Declaración de los 3 archivos WebP y README.md como `<Content Include="..." />`).
  6. `Views/Home/Index.cshtml` (Marcado semántico del carrusel Bootstrap 5.3.3 con 3 diapositivas, controles manuales, indicadores y atributos ARIA, con UTF-8 BOM preservado).
  7. `Content/site.css` (Incorporación de la Sección 7B para `.ecomix-carousel` y ajustes responsivos en Sección 11).
  8. `.vs/EcomixIA/config/applicationhost.config` (Mapeo de tipo MIME `image/webp` en IIS Express local, sin tocar `Web.config`).
  9. `docs/FASE_01_EVIDENCIAS.md` (Registro detallado de ejecución y evidencias).
  10. `docs/carousel_desktop_1440px.png` y `docs/carousel_mobile_390px.png` (Capturas de pantalla reales capturadas mediante Chrome CDP headless).
* **Archivos y componentes preservados sin alteración:**
  - Controladores (`HomeController`, `MaterialesController`, `MezclasController`).
  - Modelos de datos y DTOs (`ConcretePredictionRequestDto`, `PredictionResponseDto`, etc.).
  - Cadenas de conexión y archivo `Web.config` (preservado intacto y excluido de Git).
  - Base de datos SQL Server LocalDB (`EcomixIA`) sin modificaciones ni migraciones.
  - Consumo Azure estrictamente en US$ 0.00 (sin llamadas a API ni ejecución de inferencias).

---

### 13.2 Inspección Técnica de las Imágenes Originales Integradas (F1.3-01)

Se recibieron y verificaron tres archivos gráficos originales en el directorio `Content/images/carousel/`:

| Propiedad | Diapositiva 1 | Diapositiva 2 | Diapositiva 3 |
| :--- | :--- | :--- | :--- |
| **Nombre de archivo** | `01-innovacion-concreto.webp` | `02-materiales-sostenibles.webp` | `03-resistencia-concreto.webp` |
| **Concepto de ingeniería** | Innovación y dosificación de concreto inteligente | Materiales sostenibles, puzolanas y economía circular | Ensayos de probeta, predicción f'c a 28 días con IA |
| **Dimensiones reales** | 1672 × 941 píxeles | 1672 × 941 píxeles | 1672 × 941 píxeles |
| **Relación de aspecto** | 16:9 (Widescreen) | 16:9 (Widescreen) | 16:9 (Widescreen) |
| **Formato y compresión** | WebP (VP8L, Lossless) | WebP (VP8L, Lossless) | WebP (VP8, Lossy) |
| **Firma binaria (Magic)** | `RIFF....WEBP` (`0x52 49 46 46` ... `0x57 45 42 50`) | `RIFF....WEBP` (`0x52 49 46 46` ... `0x57 45 42 50`) | `RIFF....WEBP` (`0x52 49 46 46` ... `0x57 45 42 50`) |
| **Tamaño en disco** | 1,438,764 bytes (1.37 MB) | 1,522,642 bytes (1.45 MB) | 115,636 bytes (113 KB) |
| **Entrega HTTP (IIS Express)** | HTTP 200 OK (`image/webp`) | HTTP 200 OK (`image/webp`) | HTTP 200 OK (`image/webp`) |
| **Cumplimiento D-05** | Sin logotipos comerciales de terceros | Sin logotipos comerciales de terceros | Sin logotipos comerciales de terceros |

> [!NOTE]
> **Configuración MIME en IIS Express:** Por defecto, IIS Express no tiene registrado el tipo MIME para la extensión `.webp`, devolviendo error HTTP 404.3. Se resolvió incorporando `<mimeMap fileExtension=".webp" mimeType="image/webp" />` en la configuración local de la solución (`.vs/EcomixIA/config/applicationhost.config`), manteniendo el archivo de producción `Web.config` completamente limpio e inalterado.

---

### 13.3 Inclusión en el Archivo de Proyecto (`EcomixIA.csproj`) (F1.3-02)

Los tres recursos gráficos y su archivo de control fueron declarados formalmente en `EcomixIA.csproj` dentro de un bloque `<ItemGroup>` como elementos de tipo `Content`:

```xml
<Content Include="Content\images\carousel\01-innovacion-concreto.webp" />
<Content Include="Content\images\carousel\02-materiales-sostenibles.webp" />
<Content Include="Content\images\carousel\03-resistencia-concreto.webp" />
<Content Include="Content\images\carousel\README.md" />
```

La compilación con MSBuild 17 en configuración Debug finalizó exitosamente con 0 errores y 0 advertencias.

---

### 13.4 Estructura HTML y Accesibilidad en `Views/Home/Index.cshtml` (F1.3-03 a F1.3-09)

El carrusel fue integrado inmediatamente después de la sección Hero y antes de la Sección 2 (`#funcionalidades`):

1. **Contenedor semántico:**
   - `<section class="ecomix-carousel-section" aria-label="Carrusel informativo de EcoMix IA">`
   - Encabezado oculto para lectores de pantalla: `<h2 class="visually-hidden">Pilares y Capacidades de EcoMix IA</h2>`
2. **Componente Bootstrap:**
   - `<div id="carruselPromocional" class="carousel slide ecomix-carousel" data-bs-ride="false">`
   - **Autoplay deshabilitado:** Atributo `data-bs-ride="false"` y ausencia de `data-bs-interval`, garantizando control total al usuario y cumplimiento de WCAG 2.2.2 (Pause, Stop, Hide).
3. **Indicadores de navegación (`.carousel-indicators`):**
   - 3 botones interactivos con `data-bs-target="#carruselPromocional"`, `data-bs-slide-to="0/1/2"`.
   - Diapositiva inicial 0 con clase `active` y `aria-current="true"`.
   - Etiquetas accesibles `aria-label="Diapositiva 1: Innovación en concreto"`, etc.
4. **Diapositivas (`.carousel-inner`):**
   - Diapositiva 1 (activa): Badge `Dosificación Inteligente`, título `Innovación en concreto sostenible`, descripción técnica y atributos de imagen `loading="eager"` (LCP optimizado).
   - Diapositiva 2: Badge `Economía Circular`, título `Materiales y sostenibilidad`, descripción de subproductos (cenizas volantes, escoria) y `loading="lazy"`.
   - Diapositiva 3: Badge `Modelos Predictivos`, título `Predicción de resistencia con IA`, descripción de predicción f'c a 28 días y `loading="lazy"`.
5. **Capa de contraste (`.ecomix-carousel-overlay`):**
   - Gradiente oscuro vertical de alta opacidad (`rgba(10, 27, 48, 0.88)` a `rgba(10, 27, 48, 0.45)`) que asegura una relación de contraste superior a 4.5:1 para el texto blanco sobre cualquier sección de la fotografía.
6. **Controles anterior/siguiente:**
   - Botones `<button class="carousel-control-prev" data-bs-target="#carruselPromocional" data-bs-slide="prev">` y `next`.
   - Textos ocultos para accesibilidad: `<span class="visually-hidden">Anterior</span>` y `Siguiente`.
7. **Integridad de codificación:**
   - Archivo `Views/Home/Index.cshtml` guardado con UTF-8 BOM (`0xEF, 0xBB, 0xBF`), garantizando que caracteres como `ó`, `ñ`, `í`, `³`, `₂` sean procesados fielmente por ASP.NET MVC 5 sin generar doble codificación.

---

### 13.5 Hoja de Estilos CSS (`Content/site.css`) (F1.3-10 y F1.3-11)

Se implementaron estilos específicos bajo la **Sección 7B** y ajustes responsivos en la **Sección 11**:

* **Contenedor `.ecomix-carousel`:** Esquinas redondeadas de `16px`, sombra de elevación `0 12px 32px rgba(10, 27, 48, 0.12)`, borde estructural de `1px solid var(--ecomix-border)`.
* **Imagen `.ecomix-carousel-img`:**
  - `width: 100%`, `display: block`.
  - `object-fit: cover` con punto focal `object-position: center 35%`, adaptando la relación 16:9 al contenedor sin distorsión anatómica ni estiramiento.
* **Alturas adaptables por breakpoint:**
  - **Escritorio (`min-width: 992px`):** `height: 480px`.
  - **Tablet (`768px - 991px`):** `height: 380px`.
  - **Móvil (`max-width: 767.98px`):** `height: 290px`.
* **Accesibilidad motriz (Motion Sensitivity):**
  - Regla `@media (prefers-reduced-motion: reduce)` que desactiva las transiciones animadas para usuarios con sensibilidad vestibular.
* **Comprobación de desbordamiento horizontal:**
  - Evaluado con Google Chrome headless en resolución móvil `390 × 844 px`:
    `docScrollWidth`: 390, `winInnerWidth`: 390, `hasHorizontalOverflow`: `false`.
    Desbordamiento horizontal: exactamente **0 píxeles**.

---

### 13.6 Matriz de Pruebas de Calidad F1.3 (F1.3-01 a F1.3-12)

| ID | Criterio de Prueba | Método de Verificación | Resultado Observado | Estado |
| :--- | :--- | :--- | :--- | :---: |
| **F1.3-01** | Verificación de archivos WebP originales | Inspección binaria y cabeceras HTTP | 3 archivos presentes, formato genuino `RIFF....WEBP`, dimensiones 1672×941 px, HTTP 200 con `image/webp`. | **PASS** |
| **F1.3-02** | Inclusión en `EcomixIA.csproj` | Parseo XML y compilación MSBuild | 3 imágenes y README.md incluidos como `Content`. Compilación limpia (0 errores). | **PASS** |
| **F1.3-03** | Posicionamiento en el DOM | Inspección de marcado Razor | Ubicado entre sección Hero y Sección 2 (`#funcionalidades`), sin alterar bloques adyacentes. | **PASS** |
| **F1.3-04** | Estructura HTML y accesibilidad | Inspección DOM y atributos ARIA | Presencia de `carousel-inner`, 3 `carousel-item`, gradiente de contraste, `role="region"`, `aria-label`, controles con `.visually-hidden`. | **PASS** |
| **F1.3-05** | Estado inicial del carrusel | Automatización Chrome CDP | Slide 1 activa (índice 0), indicador 1 con `active` e indicador `aria-current="true"`. | **PASS** |
| **F1.3-06** | Navegación manual (Next / Prev) | Interacción Chrome CDP vía script | Clic en Next avanza a diapositiva 1 ("Materiales y sostenibilidad"); clic en Prev regresa a diapositiva 0 sin recarga. | **PASS** |
| **F1.3-07** | Indicadores interactivos | Interacción Chrome CDP vía script | Clic en indicador 2 navega directamente a diapositiva 2 ("Predicción de resistencia con IA"). | **PASS** |
| **F1.3-08** | Autoplay deshabilitado | Inspección de atributos | `data-bs-ride="false"`, sin atributo `data-bs-interval`. Sin rotación no solicitada. | **PASS** |
| **F1.3-09** | Integridad de codificación UTF-8 | Inspección de bytes en payload HTTP | Títulos y descripciones con tildes y caracteres especiales (`ó`, `ñ`, `í`, `f'c`) emitidos limpiamente sin mojibake. | **PASS** |
| **F1.3-10** | Regla CSS y adaptabilidad de imagen | Inspección CSS y renderizado visual | `object-fit: cover`, `object-position: center 35%`, alturas responsivas (480px / 380px / 290px), sin distorsión. | **PASS** |
| **F1.3-11** | Responsive sin scroll horizontal | Emulación Chrome CDP móvil (390px) | `scrollWidth`: 390px == `windowWidth`: 390px. Desbordamiento horizontal: `false` (0 px). | **PASS** |
| **F1.3-12** | Consola JavaScript | Escucha de eventos `Runtime.exceptionThrown` | **0 errores JavaScript** registrados durante todo el ciclo de navegación e interacción. | **PASS** |

**Resultado consolidado de pruebas F1.3:** **12/12 superadas (100% de éxito).**

---

### 13.7 Matriz de Pruebas de Humo de Regresión (SM-01 a SM-08)

Se ejecutó la suite completa de pruebas de humo para garantizar que los cambios en la portada no afectaron los módulos preexistentes:

| Prueba | Ruta Solicitada | Código HTTP | Resultado de Regresión | Estado |
| :---: | :--- | :---: | :--- | :---: |
| **SM-01** | `/` | **200 OK** | Portada principal cargada con carrusel integrado y contadores sincronizados (Materiales: 10, Mezclas: 8). | **PASS** |
| **SM-02** | `/Materiales/Index` | **200 OK** | Catálogo de materiales renderizado correctamente (10 materiales visibles). | **PASS** |
| **SM-03** | `/Materiales/Details/1` | **200 OK** | Ficha de material 1 (`Cemento Portland Tipo I`) con costo y emisiones. | **PASS** |
| **SM-04** | `/Mezclas/Index` | **200 OK** | Maestro de mezclas renderizado con 8 mezclas (6 semillas + 2 locales). | **PASS** |
| **SM-05** | `/Mezclas/Details/1` | **200 OK** | Ficha de Mezcla 1 (`Concreto f'c 210`) con 4 componentes e indicadores. | **PASS** |
| **SM-06** | `/Mezclas/Details/7` | **200 OK** | Ficha de Mezcla 7 (`mezcla test1`, sin componentes) tolerante a valores cero. | **PASS** |
| **SM-07** | `/Mezclas/Simulador` | **200 OK** | Formulario del simulador interactivo disponible en modo local. | **PASS** |
| **SM-08** | `/Mezclas/Simulador?mezclaId=1` | **200 OK** | Precarga correcta de parámetros de Mezcla 1 en el formulario. | **PASS** |

---

### 13.8 Estado de la Base de Datos LocalDB y Presupuesto Azure

1. **Integridad de base de datos SQL Server LocalDB (`EcomixIA`):**
   - `dbo.Materials`: **10 registros** (verificado).
   - `dbo.Mezclas`: **8 registros** (verificado).
   - `dbo.MezclaComponentes`: **32 registros** (verificado).
   - `dbo.__MigrationHistory`: **1 registro** (verificado).
   - Cero modificaciones de esquema, tablas o registros de datos.
2. **Consumo presupuestario Azure (D-06):**
   - Gasto acumulado en la sesión: **US$ 0.00**.
   - Cero invocaciones al contenedor de inferencia FastAPI en Azure Container Apps.

---

### 13.9 Declaración de Cierre de F1.3

La subetapa **F1.3 — Integración del carrusel promocional con imágenes originales** queda **APROBADA** y consolidada documentalmente. El sistema se encuentra en un estado estable, verificado técnica y visualmente, compilado sin errores y listo para continuar con la subetapa **F1.4** previa instrucción del usuario.

---

## 14. Subetapa F1.4 — Validación Responsive, Accesibilidad y Optimización Visual

La subetapa **F1.4 — Validación responsive, accesibilidad y optimización visual** tuvo como objetivo realizar una auditoría integral, rigurosa y empírica de todo el portal público y sus vistas operativas, optimizar los activos gráficos WebP reduciendo el peso de transferencia en más del 85%, asegurar la precisión técnica y deontológica de los textos descriptivos, y resolver defectos reales de accesibilidad (asociación de etiquetas de formulario, adaptabilidad en pantallas ultra estrechas de 320 px y foco visible).

---

### 14.1 Delimitación estricta del alcance en F1.4
* **Archivos modificados:**
  1. `Content/images/carousel/01-innovacion-concreto.webp` (Optimización WebP lossy Q85, reducción de 1.37 MB a 129.7 KB).
  2. `Content/images/carousel/02-materiales-sostenibles.webp` (Optimización WebP lossy Q85, reducción de 1.45 MB a 141.7 KB).
  3. `Content/images/carousel/README.md` (Actualización de inventario con tamaños optimizados y métricas PSNR).
  4. `Views/Home/Index.cshtml` (Ajuste de textos del carrusel según especificación técnica rigurosa; preservación de UTF-8 BOM).
  5. `Views/Mezclas/Details.cshtml` (Adición de `flex-wrap` en barra de acciones para evitar desbordamiento a 320 px; corrección de caracteres Unicode).
  6. `Views/Mezclas/Simulador.cshtml` (Asociación explícita de etiquetas `@for` con IDs de campos `inCemento`, `inAgua`, etc., para lectores de pantalla; preservación de UTF-8 BOM).
  7. `docs/FASE_01_EVIDENCIAS.md` (Incorporación de la Sección 14 de evidencias).
* **Capturas visuales reales generadas (Chrome DevTools Protocol):**
  1. `docs/fase01_home_desktop.png` (Portada en escritorio 1440 × 900 px).
  2. `docs/fase01_home_tablet.png` (Portada en tablet 768 × 1024 px).
  3. `docs/fase01_home_mobile.png` (Portada en móvil 390 × 844 px).
  4. `docs/fase01_simulador_mobile.png` (Formulario del simulador en móvil 390 × 844 px).
* **Componentes preservados sin alteración:**
  - Controladores MVC 5 y servicios ML preexistentes.
  - Modelos de datos y contexto Entity Framework 6.
  - Configuración de conexión y archivo `Web.config` (protegido y excluido de Git).
  - Base de datos SQL Server LocalDB (`EcomixIA`).
  - Presupuesto en la nube de Azure (cero consumo, US$ 0.00).

---

### 14.2 Optimización de Recursos Gráficos WebP (Etapa 3)

Se ejecutó un análisis de compresión en las imágenes del carrusel utilizando el motor nativo `libwebp` a través de Pillow (Python 3.13) disponible en el sistema local, tras respaldar los originales fuera del repositorio en el directorio temporal del agente:

| Recurso Gráfico | Diapositiva | Resolución Nativa | Tamaño Original | Tamaño Optimizado | Reducción de Peso | Métrica de Fidelidad (PSNR) | Calidad Perceptual |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `01-innovacion-concreto.webp` | 1 | 1672 × 941 px | 1,438,764 B (1.37 MB) | **132,772 B (129.7 KB)** | **-90.8%** | **40.52 dB** | Indistinguible |
| `02-materiales-sostenibles.webp` | 2 | 1672 × 941 px | 1,522,642 B (1.45 MB) | **145,126 B (141.7 KB)** | **-90.5%** | **40.07 dB** | Indistinguible |
| `03-resistencia-concreto.webp` | 3 | 1672 × 941 px | 115,636 B (112.9 KB) | **115,636 B (112.9 KB)** | Preservado | Base original | Óptima previa |
| **Total Transferencia Carrusel** | — | — | **3,077,042 B (2.93 MB)** | **393,534 B (384.3 KB)** | **-87.2%** | — | Excelente |

* **Metodología:** Compresión con pérdida controlada a `Quality = 85`, `method = 6` (máximo esfuerzo heurístico de compresión) preservando el espacio de color sRGB y la resolución nativa de 1672 × 941 píxeles.
* **Ahorro de ancho de banda:** Se eliminaron **2.68 MB** de carga innecesaria en la carga inicial de la página principal.
* **Verificación de entrega:** Las 3 imágenes fueron comprobadas directamente en IIS Express, respondiendo con código **HTTP 200 OK** y cabecera `Content-Type: image/webp`.

---

### 14.3 Precisión Técnica y Deontológica en Textos del Carrusel (Etapa 2)

Se auditaron y corrigieron los textos descriptivos de las diapositivas en `Views/Home/Index.cshtml` para erradicar cualquier afirmación imprecisa que presentara como operativa una selección heurística autónoma de mezclas o reducciones experimentales no validadas:

* **Diapositiva 1:**
  * *Texto implementado:* *"Diseña mezclas, evalúa sus indicadores y explora herramientas de predicción con inteligencia artificial."*
  * *Alcance técnico reflejado:* Asistencia en diseño y formulación, desvinculando la idea de optimización autónoma por algoritmo.
* **Diapositiva 2:**
  * *Texto implementado:* *"Analiza los costos y las emisiones estimadas de CO₂ de cada dosificación."*
  * *Alcance técnico reflejado:* Balances de masa estequiométricos y factores de emisión bibliográficos, aclarando que no constituyen determinaciones empíricas de laboratorio.
* **Diapositiva 3:**
  * *Texto implementado:* *"Consulta estimaciones de resistencia a compresión a 7 y 28 días."*
  * *Alcance técnico reflejado:* Predicciones estadísticas inferidas mediante el modelo de Machine Learning AutoML VotingEnsemble integrado vía microservicio.

---

### 14.4 Matriz Responsive Completa: 5 Viewports × 8 Rutas (Etapa 4)

Se evaluó el comportamiento responsive en tiempo real mediante Chrome DevTools Protocol a lo largo de 40 combinaciones de pantalla y ruta:

| Ruta del Sistema | Desktop (1440×900) | Small Desktop (1024×768) | Tablet (768×1024) | Mobile (390×844) | Narrow Mobile (320×720) | Desbordamiento Horizontal |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `/` (Portada Principal) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |
| `/Materiales/Index` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |
| `/Materiales/Details/1` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |
| `/Mezclas/Index` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |
| `/Mezclas/Details/1` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) * | **0 px (PASS)** |
| `/Mezclas/Details/7` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) * | **0 px (PASS)** |
| `/Mezclas/Simulador` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |
| `/Mezclas/Simulador?mezclaId=1` | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | OK (0 px) | **0 px (PASS)** |

*\* Nota de corrección:* En `Views/Mezclas/Details.cshtml`, la botonera de acciones original no incluía `flex-wrap`, provocando que en 320 px el contenedor se expandiera a 359 px. Se incorporó `d-flex flex-wrap` permitiendo a los botones envolverse ordenadamente sin estirar la pantalla.

---

### 14.5 Pruebas de Accesibilidad, Foco y Teclado (Etapa 5)

1. **Navegación por teclado (Skip Link):**
   - El enlace `<a href="#contenidoPrincipal" class="ecomix-skip-link">` fue verificado con foco activo.
   - Cuenta con indicador de foco visible en ámbar (`outline: 3px solid var(--ecomix-amber)`).
2. **Interacción con menú móvil (Navbar Toggler):**
   - Evaluado en resolución móvil de 390 px mediante disparadores de eventos CDP.
   - Estado inicial: colapsado (`menuCollapsed: true`).
   - Clic de apertura: expandido con clase `show` (`menuExpanded: true`).
   - Clic de cierre: colapsado exitosamente (`menuCollapsed: true`).
3. **Control del carrusel por teclado:**
   - Botón siguiente (`.carousel-control-next`) accesible por teclado con foco visible y etiqueta `aria-label="Diapositiva siguiente"`.
   - Transición de diapositiva verificada (índice 0 a índice 1) mediante teclado.
4. **Asociación de etiquetas de formulario (WCAG 1.3.1 / 4.1.2):**
   - Se detectó que en `Views/Mezclas/Simulador.cshtml` los `@Html.LabelFor` no apuntaban a los IDs específicos utilizados por el script (`inCemento`, `inAgua`, `inEscoria`, etc.).
   - Se aplicó `@for = "inCemento"`, etc., logrando que el 100% de los campos editables queden asociados formalmente a sus etiquetas.
5. **Medición cuantitativa de contraste de color (WCAG 2.1 AA / AAA):**
   - **Texto del cuerpo:** `#0f172a` sobre fondo `#f8fafc` = **17.06:1** (Cumple AAA).
   - **Enlaces de navegación:** `#ffffff` sobre navbar `#0a1b30` = **17.32:1** (Cumple AAA).
   - **Botón primario de acción:** `#ffffff` sobre verde `#15803d` = **5.02:1** (Cumple AA, requerido ≥ 4.5:1).
   - **Títulos del carrusel:** `#ffffff` sobre capa gradiente `#0a1b30` = **17.32:1** (Cumple AAA).
   - **Descripciones del carrusel:** `#e2e8f0` sobre capa gradiente `#0a1b30` = **14.05:1** (Cumple AAA).
   - **Badge del carrusel:** `#86efac` sobre verde translúcido = **10.19:1** (Cumple AAA).
   - **Enlaces del pie de página:** `#94a3b8` sobre `#0a1b30` = **6.76:1** (Cumple AA).
6. **Comportamiento ante sensibilidad al movimiento (`prefers-reduced-motion`):**
   - Con la emulación activada, la duración de transición en `.ecomix-carousel .carousel-item` evaluó a `0s` con propiedad `none`, eliminando animaciones vestibulares bruscas.

---

### 14.6 Matriz de Pruebas Específicas F1.4 (F1.4-01 a F1.4-14)

| ID | Criterio de Verificación | Método de Prueba | Resultado Obtenido | Estado |
| :--- | :--- | :--- | :--- | :---: |
| **F1.4-01** | Portada sin overflow a 1440 px | Medición CDP `scrollWidth` vs `winW` | `docW: 1425 <= winW: 1440`. Desbordamiento: 0 px. | **PASS** |
| **F1.4-02** | Portada sin overflow a 768 px | Medición CDP `scrollWidth` vs `winW` | `docW: 768 <= winW: 768`. Desbordamiento: 0 px. | **PASS** |
| **F1.4-03** | Portada sin overflow a 390 px | Medición CDP `scrollWidth` vs `winW` | `docW: 390 <= winW: 390`. Desbordamiento: 0 px. | **PASS** |
| **F1.4-04** | Portada sin overflow a 320 px | Medición CDP `scrollWidth` vs `winW` | `docW: 320 <= winW: 320`. Desbordamiento: 0 px. | **PASS** |
| **F1.4-05** | Navbar móvil funcional | Clic y toggle CDP en 390 px | Alterna correctamente entre colapsado y expandido (`.show`). | **PASS** |
| **F1.4-06** | Carrusel navegable por teclado | Simulación de eventos de teclado | Diapositiva avanza al activar botón con foco por teclado. | **PASS** |
| **F1.4-07** | Foco visible en controles | Inspección de reglas `:focus-visible` | Anillo visible en ámbar y verde esmeralda en interactivos. | **PASS** |
| **F1.4-08** | Contraste verificado (≥ 4.5:1) | Cálculo fotométrico de luminancia | Todos los pares de texto superan 5.0:1 (alcanzando hasta 17.3:1). | **PASS** |
| **F1.4-09** | Comportamiento reduced motion | Emulación de media feature CDP | Transición desactivada (`transition: none !important; 0s`). | **PASS** |
| **F1.4-10** | Formularios legibles en móvil | Inspección DOM en `/Mezclas/Simulador` | Sin campos recortados (`anyCutOff: false`), labels vinculadas. | **PASS** |
| **F1.4-11** | Tablas legibles en móvil | Inspección DOM en `/Materiales/Index` | `.table-panel` con scroll horizontal interno protegido. | **PASS** |
| **F1.4-12** | Imágenes WebP optimizadas y funcionales | Validación binaria y HTTP IIS Express | Imágenes 1 y 2 reducidas > 90% (Q85, PSNR > 40 dB), HTTP 200. | **PASS** |
| **F1.4-13** | Ausencia de afirmaciones ML erróneas | Auditoría de textos en portada | Textos corregidos; clara diferenciación estequiométrica vs ML. | **PASS** |
| **F1.4-14** | Ausencia de errores JavaScript | Monitoreo `Runtime.exceptionThrown` | **0 errores de consola** registrados durante todo el ciclo. | **PASS** |

**Resultado consolidado de pruebas F1.4:** **14/14 superadas (100% de éxito).**

---

### 14.7 Capturas Visuales Reales Archivadas (Etapa 8)

Se capturaron y archivaron cuatro imágenes de renderizado real obtenidas directamente del navegador en el directorio `docs/`:

1. [docs/fase01_home_desktop.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/fase01_home_desktop.png) — Vista general de la portada en resolución de escritorio (1440 × 900 px).
2. [docs/fase01_home_tablet.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/fase01_home_tablet.png) — Vista general de la portada en resolución tablet (768 × 1024 px).
3. [docs/fase01_home_mobile.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/fase01_home_mobile.png) — Vista de la portada con carrusel en pantalla móvil (390 × 844 px).
4. [docs/fase01_simulador_mobile.png](file:///C:/Users/Admin/Desktop/Proyectos/ML%20EcomixIA%20Sistema/docs/fase01_simulador_mobile.png) — Formulario de dosificación asistida del simulador en pantalla móvil (390 × 844 px).

---

### 14.8 Requisito de Despliegue Futuro para Servidores IIS de Producción

En cumplimiento de la directriz de no modificar `Web.config` localmente:
* El mapeo `<mimeMap fileExtension=".webp" mimeType="image/webp" />` se encuentra operando únicamente en el host local de pruebas (`.vs/EcomixIA/config/applicationhost.config`).
* **Requisito formal de publicación futura:** Se registra como requisito de despliegue para la fase de puesta en producción (IIS Server o Azure App Service / Container Apps) que el servidor de alojamiento disponga de la definición MIME para la extensión `.webp` en su configuración web o del sistema.

---

### 14.9 Compilación y Pruebas de Humo de Regresión (SM-01 a SM-08)

* **Compilación MSBuild Debug:** Código de salida `0`, 0 errores, 0 advertencias.
* **Pruebas de Humo ejecutadas:**
  * **SM-01 (`/`):** 200 OK — Portada principal con carrusel optimizado y textos verificados.
  * **SM-02 (`/Materiales/Index`):** 200 OK — Catálogo de 10 materiales visible.
  * **SM-03 (`/Materiales/Details/1`):** 200 OK — Ficha de Cemento Portland Tipo I.
  * **SM-04 (`/Mezclas/Index`):** 200 OK — Maestro de 8 mezclas de concreto.
  * **SM-05 (`/Mezclas/Details/1`):** 200 OK — Detalle de Mezcla 1 con botonera responsive.
  * **SM-06 (`/Mezclas/Details/7`):** 200 OK — Detalle de Mezcla 7 (mezcla vacía) tolerante.
  * **SM-07 (`/Mezclas/Simulador`):** 200 OK — Simulador interactivo con etiquetas accesibles.
  * **SM-08 (`/Mezclas/Simulador?mezclaId=1`):** 200 OK — Precarga de valores de Mezcla 1.

---

### 14.10 Integridad de la Base de Datos LocalDB y FinOps Azure

* **SQL Server LocalDB (`(localdb)\MSSQLLocalDB`, `EcomixIA`):**
  * `dbo.Materials`: **10 registros** (verificado).
  * `dbo.Mezclas`: **8 registros** (verificado).
  * `dbo.MezclaComponentes`: **32 registros** (verificado).
  * `dbo.__MigrationHistory`: **1 registro** (verificado).
* **FinOps Azure (D-06):**
  * Gasto acumulado en la sesión: **US$ 0.00**.
  * Cero llamadas al microservicio de inferencia en la nube.

---

### 14.11 Declaración de Cierre de F1.4

La subetapa **F1.4 — Validación responsive, accesibilidad y optimización visual** queda formalmente **APROBADA**. El portal público de EcoMix IA y sus vistas operativas han sido validadas en 5 resoluciones, cuentan con contraste accesible certificado, recursos WebP optimizados y alta fidelidad técnica.

Queda expedito el camino para avanzar a la formalización y cierre de la Fase 1 (**F1.5**) bajo instrucción del usuario.

---

## 15. Subetapa F1.5 — Cierre Técnico y Documental de Fase 1

La subetapa **F1.5 — Auditoría final, consolidación documental y commit local de Fase 1** formaliza la conclusión de todos los entregables comprometidos para la **Fase 1: Portal Público e Identidad Visual**, garantizando la integridad arquitectural, la seguridad de configuración, la accesibilidad universal y la ausencia de regresiones operativas en el sistema EcoMix IA.

---

### 15.1 Resumen Ejecutivo Consolidado de la Fase 1

| Subetapa | Entregable Principal | Métricas y Logros Técnicos | Estado |
| :--- | :--- | :--- | :---: |
| **F1.1** | Layout general y navegación responsive | Plantilla HTML5 semántica (`_Layout.cshtml`), paleta mineral/sostenibilidad en `site.css` (11 secciones), Skip Link accesible, barra sticky con toggler móvil y footer ético/académico (D-05). | **APROBADA** |
| **F1.2** | Portada promocional del sistema | Portada de ingeniería (`Views/Home/Index.cshtml`) con Hero conceptual, tarjetas de funcionalidades, flujo metodológico de 3 pasos y sección de rigurosidad científica. | **APROBADA** |
| **Revisión UTF-8** | Auditoría y corrección de codificación | Firma UTF-8 BOM (`0xEF, 0xBB, 0xBF`) en 11 archivos críticos (Razor y C#), resolviendo problemas de doble codificación en IIS Express. | **CONFORME** |
| **F1.3** | Carrusel promocional con imágenes originales | Integración de 3 imágenes WebP originales (1672×941 px) en `Content/images/carousel/`, sin autoplay (`data-bs-ride="false"`), controles e indicadores ARIA. | **APROBADA** |
| **F1.4** | Validación responsive, accesibilidad y optimización | Compresión WebP Q85 (-87.2% peso / -2.68 MB, PSNR > 40 dB), 40 auditorías responsive (5 viewports × 8 rutas, 0 overflow), contraste WCAG AA/AAA (5.0:1 a 17.3:1) y `@for` en formularios. | **APROBADA** |
| **F1.5** | Auditoría final, cierre documental y commit local | Verificación integral de cambios, auditoría byte a byte de archivos C#, 8/8 pruebas de humo, preservación de LocalDB, exclusión de `Web.config` y commit local controlado. | **APROBADA** |

---

### 15.2 Inventario Consolidado de Archivos del Commit de Fase 1

Todos los archivos modificados e incorporados han sido auditados exhaustivamente para asegurar que corresponden exclusivamente al alcance de Fase 1:

#### A. Vistas Razor, Estilos CSS y Proyecto
1. `Views/Shared/_Layout.cshtml` — Maquetación general HTML5, accesibilidad, skip-link, alertas TempData y pie institucional (D-05).
2. `Views/Home/Index.cshtml` — Portada promocional, carrusel Bootstrap 5.3, tarjetas de capacidad, flujo de 3 pasos y precisiones metodológicas.
3. `Views/Mezclas/Details.cshtml` — Inclusión de `d-flex flex-wrap` en cabecera para soporte responsive de 320 px y UTF-8 BOM.
4. `Views/Mezclas/Index.cshtml` — Inclusión de UTF-8 BOM.
5. `Views/Mezclas/Simulador.cshtml` — Asociación formal de etiquetas `@Html.LabelFor` con atributo `@for = "inCemento"` (accesibilidad WCAG) y UTF-8 BOM.
6. `Content/site.css` — Hoja de estilos global modularizada (Secciones 1 a 11, incluyendo Sección 7B para carrusel).
7. `EcomixIA.csproj` — Inclusión de los tres activos WebP y `README.md` como `<Content Include="..." />`.

#### B. Activos Gráficos Optimizados
8. `Content/images/carousel/01-innovacion-concreto.webp` (132,772 B, 1672×941 px, WebP Q85).
9. `Content/images/carousel/02-materiales-sostenibles.webp` (145,126 B, 1672×941 px, WebP Q85).
10. `Content/images/carousel/03-resistencia-concreto.webp` (115,636 B, 1672×941 px, WebP base).
11. `Content/images/carousel/README.md` — Documentación técnica, dimensiones y políticas de autoría D-05.

#### C. Código C# (Preservación estricta — Cambios exclusivos de BOM UTF-8)
12. `Controllers/MezclasController.cs` — Inclusión de UTF-8 BOM en cabecera (cero cambios lógicos).
13. `Models/Dtos/ConcretePredictionRequestDto.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
14. `Models/Dtos/PredictionResponseDto.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
15. `Models/Dtos/ProblemDetailsDto.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
16. `Models/ViewModels/SimuladorDosificacionViewModel.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
17. `Services/EcoMixMlClientException.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
18. `Services/EcoMixMlClientService.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).
19. `Services/IEcoMixMlClientService.cs` — Inclusión de UTF-8 BOM (cero cambios lógicos).

#### D. Documentación y Evidencias Visuales
20. `docs/FASE_01_EVIDENCIAS.md` — Bitácora completa y exhaustiva de evidencias de Fase 1.
21. `docs/carousel_desktop_1440px.png` — Captura del carrusel en escritorio (F1.3).
22. `docs/carousel_mobile_390px.png` — Captura del carrusel en móvil (F1.3).
23. `docs/fase01_home_desktop.png` — Portada general en escritorio 1440×900 px (F1.4).
24. `docs/fase01_home_tablet.png` — Portada general en tablet 768×1024 px (F1.4).
25. `docs/fase01_home_mobile.png` — Portada general en móvil 390×844 px (F1.4).
26. `docs/fase01_simulador_mobile.png` — Formulario del simulador en móvil 390×844 px (F1.4).

#### E. Archivos Excluidos Estrictamente del Commit
* `Web.config` — Configuración local con cadena de conexión `(localdb)\MSSQLLocalDB` preservada intacta fuera del versionamiento.
* `Web.Secrets.config` — Excluido de Git mediante `.gitignore` para salvaguarda de secretos.

---

### 15.3 Evidencias Visuales Verificadas

Se confirmó la existencia, validez binaria (`PNG` magic bytes `89 50 4E 47`) y ausencia de datos sensibles en las seis capturas documentales:

| Archivo de Captura | Dimensiones Evaluadas | Peso en Disco | Propósito Documental |
| :--- | :---: | :---: | :--- |
| `docs/carousel_desktop_1440px.png` | 1440 × 900 px | 879.0 KB | Evidencia de integración del carrusel con 3 diapositivas en escritorio. |
| `docs/carousel_mobile_390px.png` | 390 × 844 px | 679.4 KB | Evidencia de adaptación visual del carrusel en viewport móvil de 390 px. |
| `docs/fase01_home_desktop.png` | 1440 × 900 px | 787.9 KB | Renderizado completo de la portada promocional en alta resolución. |
| `docs/fase01_home_tablet.png` | 768 × 1024 px | 1,681.4 KB | Renderizado de portada en tablet con distribución de columnas 2x2. |
| `docs/fase01_home_mobile.png` | 390 × 844 px | 677.5 KB | Renderizado de portada con navbar toggler colapsado y texto apilado. |
| `docs/fase01_simulador_mobile.png` | 390 × 844 px | 196.3 KB | Formulario del simulador en móvil sin campos recortados ni overflow. |

---

### 15.4 Resultados de las Pruebas de Humo de Regresión (SM-01 a SM-08)

Ejecutadas con éxito tras la consolidación de cambios:

| Prueba | Endpoint Evaluado | Estado HTTP | Cadenas Críticas Verificadas | Estado |
| :---: | :--- | :---: | :--- | :---: |
| **SM-01** | `/` | **200 OK** | `EcoMix IA`, `Innovación en concreto sostenible` | **PASS** |
| **SM-02** | `/Materiales/Index` | **200 OK** | `Materiales`, `Cemento Portland Tipo I` (10 registros) | **PASS** |
| **SM-03** | `/Materiales/Details/1` | **200 OK** | `Cemento Portland Tipo I`, costo `0.62` | **PASS** |
| **SM-04** | `/Mezclas/Index` | **200 OK** | `Mezclas`, `Concreto f'c 210` (8 mezclas) | **PASS** |
| **SM-05** | `/Mezclas/Details/1` | **200 OK** | `Concreto f'c 210`, `Parámetros de diseño` | **PASS** |
| **SM-06** | `/Mezclas/Details/7` | **200 OK** | `mezcla test1`, `Esta mezcla todavía no tiene materiales.` | **PASS** |
| **SM-07** | `/Mezclas/Simulador` | **200 OK** | `Simulador`, `@for="inCemento"`, `@for="inAgua"` | **PASS** |
| **SM-08** | `/Mezclas/Simulador?mezclaId=1` | **200 OK** | `Concreto f'c 210`, precarga cemento `350` | **PASS** |

---

### 15.5 Integridad de la Base de Datos SQL Server LocalDB

Se verificó el estado de solo lectura de la base de datos `EcomixIA` en `(localdb)\MSSQLLocalDB`:
* `dbo.Materials`: **10 registros** (invariable).
* `dbo.Mezclas`: **8 registros** (invariable).
* `dbo.MezclaComponentes`: **32 registros** (invariable).
* `dbo.__MigrationHistory`: **1 registro** (invariable).
* Cero ejecuciones de `Update-Database`, creación de tablas o alteración de datos.

---

### 15.6 Revisión de Codificación y Seguridad

* **Codificación UTF-8:** Todas las vistas `.cshtml`, archivos `.css` y código `.cs` cuentan con firma UTF-8 estándar con BOM. Verificación en tiempo de ejecución: cero caracteres de mojibake (`Ã`, ``, etc.).
* **Seguridad de configuración:** `Web.config` se mantiene protegido en el entorno local apuntando a LocalDB. `Web.Secrets.config` permanece fuera del repositorio. No existen claves API de producción ni secretos versionados.
* **Dependencia de despliegue IIS:** El mapeo MIME para `.webp` implementado en `.vs/EcomixIA/config/applicationhost.config` opera en el entorno local. Se formaliza el requisito de que el servidor web de producción de destino cuente con el tipo MIME `image/webp`.

---

### 15.7 Estado Presupuestario y FinOps Azure (D-06)

* **Consumo de la sesión de Fase 1:** **US$ 0.00** (cero invocaciones a servicios Azure Container Apps o Machine Learning).
* **Condición de conciliación:** El límite de US$ 20 del crédito estudiantil (D-06) permanece pendiente de conciliación administrativa institucional, manteniéndose la aprobación condicionada de Fase 0.

---

### 15.8 Puerta de Calidad de Fase 1 (Quality Gate)

| Criterio de Calidad | Meta Requerida | Resultado Logrado | Estado |
| :--- | :--- | :--- | :---: |
| **Compilación MSBuild** | 0 errores en Debug Any CPU | 0 errores, 0 advertencias | **SUPERADA** |
| **Pruebas de Humo** | 100% de rutas operativas (8/8) | 8/8 con HTTP 200 OK y UTF-8 limpio | **SUPERADA** |
| **Pruebas Funcionales F1** | F1.2 (8), F1.3 (12), F1.4 (14) | 34/34 pruebas aprobadas (100% PASS) | **SUPERADA** |
| **Optimización de Recursos** | WebP < 350 KB por imagen | 130 KB y 142 KB (87.2% ahorro total) | **SUPERADA** |
| **Accesibilidad Web** | Contraste ≥ 4.5:1, sin overflow | Contraste 5.0:1 a 17.3:1, 0 px overflow | **SUPERADA** |
| **Integridad de Datos** | 10 / 8 / 32 / 1 registros en BD | 10 / 8 / 32 / 1 registros verificados | **SUPERADA** |
| **Protección de Secretos** | Web.config excluido de Git | Excluido del staging selectivo | **SUPERADA** |

---

### 15.9 Declaración de Cierre y Commit de Fase 1

La **Fase 1: Portal Público e Identidad Visual** se declara formalmente **APROBADA Y CERRADA**.

* **Mensaje de commit local:** `feat(fase-1): implementar portal publico responsive EcoMix IA`
* **Rama de trabajo:** `feat/ecomix-fase-01-portal-publico`
* **Commit base inicial:** `2c9466f`
* El hash resultante del commit de cierre quedará registrado en el árbol de Git y en el informe final de ejecución.



