# Guion de Demostración y Sustentación Final — EcoMix IA

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Simulación de Concreto Ecológico  
**Hito:** H05 — Preparación de Entrega y Cierre  
**Fecha:** 20 de Noviembre de 2026  
**Audiencia:** Comité Evaluador, Jurado de Tesis, Stakeholders y Docentes  
**Tiempo Estimado:** 15 a 20 minutos  

---

## 1. Preparación y Cuentas de Demostración

Antes de iniciar la presentación, verifique que la base de datos `EcomixIA` esté activa y que IIS Express esté en ejecución en `https://localhost:44357/`.

| Rol | Correo de Demostración | Contraseña de Prueba | Propósito en la Demostración |
|---|---|---|---|
| **Administrador** | `joamedina@upt.pe` | *(Establecida en provisión)* | Demostrar CRUD de materiales, gestión de usuarios, protección de último admin y auditoría. |
| **Usuario Registrado 1** | `auth.test.civil@upt.pe` | *(Contraseña robusta)* | Demostrar simulador ML, creación de mezclas privadas y dashboard personal. |
| **Usuario Registrado 2** | `joamedina2@upt.pe` | *(Contraseña robusta)* | Demostrar aislamiento estricto de recetas privadas (no ve las mezclas de Usuario 1). |
| **Cuenta No Confirmada** | `auth.unconfirmed.test@upt.pe` | *(N/A)* | Demostrar bloqueo de acceso ante correo no verificado (D-03). |

---

## 2. Estructura de la Demostración Paso a Paso

### Escenario 1: Portada Pública, Identidad Visual y Descargo Normativo (2 min)
- **Ruta:** `https://localhost:44357/`
- **Puntos Clave a Exponer:**
  1. **Identidad Propia:** Mostrar la línea gráfica inspirada en la industria cementera del sur peruano (tonos cemento y ocre) con identidad diferenciada **EcoMix IA** (Directiva D-05).
  2. **Carrusel Promocional Accesible:** Demostrar navegación por diapositivas con imágenes WebP optimizadas y textos descriptivos (RF-02 / RF-45).
  3. **Descargo Normativo Obligatorio:** Señalar el pie de página y la política de privacidad (`/Home/Privacidad`), destacando que el modelo `VotingEnsemble` es una herramienta de estimación experimental y no sustituye los ensayos destructivos de probetas ASTM C39 / NTP 339.034 del RNE E.060.

---

### Escenario 2: Control de Acceso y Política D-02 en Catálogo (2 min)
- **Acción:** Como visitante no autenticado, intentar acceder a:  
  `https://localhost:44357/Materiales`
- **Comportamiento Esperado:**
  - El sistema intercepta la solicitud y redirige automáticamente a `/Account/Login?ReturnUrl=%2FMateriales`.
  - **Explicación:** Se cumple la directiva aprobada **D-02**: *"Los visitantes no consultan el catálogo de materiales"*.
- **Acción 2:** Iniciar sesión con `auth.test.civil@upt.pe`.
  - El usuario ahora puede consultar el listado y detalle de materiales con sus costos y factores de emisión de CO₂.
  - No aparecen botones de «Crear», «Editar» ni «Eliminar» (interfaz de solo lectura para usuarios registrados).

---

### Escenario 3: Simulación de Dosificación con Inferencia ML (3 min)
- **Ruta:** `https://localhost:44357/Mezclas/Simulador`
- **Puntos Clave a Exponer:**
  1. **Ingreso de Dosificación:** Ingresar una formulación experimental:
     - Cemento: `350 kg/m³`
     - Escoria de Alto Horno: `100 kg/m³`
     - Ceniza Volante: `50 kg/m³`
     - Agua: `180 kg/m³`
     - Superplastificante: `5 kg/m³`
     - Agregado Grueso: `1000 kg/m³`
     - Agregado Fino: `700 kg/m³`
  2. **Inferencia Asíncrona:** Presionar **«Simular Resistencia»**.
  3. **Resultados en Tiempo Real:**
     - Mostrar predicción de resistencia a 7 días y 28 días (MPa).
     - Ratios analíticos calculados por el modelo (w/c, w/b, % sustitución puzolánica).
     - Gráfico comparativo interactivo generado con Chart.js (RF-18).
     - Métricas ecológicas inmediatas: Reducción de CO₂ estimada frente a una mezcla tradicional patrón.

---

### Escenario 4: Creación de Mezcla Privada y Snapshots Inmutables (D-09) (3 min)
- **Ruta:** `https://localhost:44357/Mezclas/Create`
- **Puntos Clave a Exponer:**
  1. **Creación de Mezcla:** Guardar una nueva mezcla privada titulada *"EcoMix Pavimento 280 kg/cm²"*.
  2. **Asignación de Componentes:** Agregar los materiales con sus cantidades dosificadas.
  3. **Demostración de Snapshots Históricos (D-09):**
     - Explicar que en la tabla `MezclaComponentes` se guardaron los campos `CostoPorKgGuardado`, `Co2PorKgGuardado`, `FechaSnapshotUtc` y `OrigenSnapshot`.
     - Si en el futuro un Administrador actualiza el precio del cemento en el catálogo global, el costo de esta mezcla histórica **permanecerá 100% inalterado y reproducible**.

---

### Escenario 5: Dashboard Personal y Aislamiento Multi-Inquilino (D-04) (3 min)
- **Ruta:** `https://localhost:44357/Dashboard`
- **Puntos Clave a Exponer:**
  1. **KPIs Consolidados:**
     - **Total de Mezclas Privadas:** Número exacto de formulaciones del usuario actual.
     - **Costo Promedio por m³:** Media aritmética exacta calculada solo con mezclas con snapshots verificados.
     - **CO₂ Promedio por m³:** Emisión media de carbono del portafolio del usuario.
  2. **Demostración de Aislamiento de Datos:**
     - Cerrar sesión e iniciar sesión como `joamedina2@upt.pe`.
     - Acceder a `/Dashboard`.
     - Mostrar que este segundo usuario **no ve ninguna de las mezclas ni estadísticas del primer usuario** (aislamiento estricto por `OwnerUserId` en servidor, RF-30 / RNF-13).

---

### Escenario 6: Panel de Administración y Protección del Último Administrador (D-10) (3 min)
- **Ruta:** `https://localhost:44357/Admin/Dashboard` (Iniciar sesión como `joamedina@upt.pe`).
- **Puntos Clave a Exponer:**
  1. **Dashboard Administrativo Agregado (RF-25):**
     - Conteo global de usuarios registrados, usuarios activos e invocaciones del modelo ML.
     - Cero exposición de recetas privadas ajenas (el Administrador tampoco tiene acceso a ver recetas ajenas, RF-32).
  2. **Gestión de Usuarios y Paginación (RF-21):**
     - Visualizar listado con estados Habilitado / Deshabilitado y roles.
  3. **Demostración de Protección Concurrente del Último Admin (H05-A2 / D-10):**
     - Intentar deshabilitar o degradar al usuario `joamedina@upt.pe` (siendo el único administrador activo).
     - El sistema bloquea inmediatamente la operación con alerta roja:  
       *«Operación bloqueada por seguridad: No es posible deshabilitar al último Administrador activo del sistema.»*
     - La base de datos aplica bloqueo serializable `WITH (UPDLOCK, HOLDLOCK)`.

---

### Escenario 7: Pista de Auditoría con Retención de 30 Días (D-07) (2 min)
- **Ruta:** `https://localhost:44357/Admin/Audit`
- **Puntos Clave a Exponer:**
  1. **Eventos Estructurados:** Mostrar los registros de seguridad (`LoginExitoso`, `PredictStrength`, `BlockDisableLastAdmin`, etc.).
  2. **Sanitización y Privacidad (H05-A4):**
     - Los detalles técnicos registran latencia, códigos de error y modelo invocado.
     - Cero almacenamiento de contraseñas, secretos, tokens, rutas del servidor ni dosificaciones de mezclas privadas.
  3. **Retención Estricta de 30 Días (RF-49 a RF-51):**
     - Consultas activas filtran automáticamente registros con más de 30 días de antigüedad.
     - Botón de depuración física manual disponible exclusivamente para administradores.

---

### Escenario 8: Verificación Automatizada de Calidad Técnica (2 min)
- **Acción:** Abrir consola de PowerShell y ejecutar el orquestador maestro:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "tests\Run_All_Tests.ps1"
  ```
- **Resultado en Vivo:**
  - Mostrar la ejecución secuencial de las 6 suites modulares.
  - Concluir con la pantalla de certificación:
    ```
    ================================================================================
      RESUMEN EJECUTIVO CONSOLIDADO DE PRUEBAS H05
    ================================================================================
      [PASS] Suite 01: Unit & Domain             |  23 PASS |  0 FAIL
      [PASS] Suite 02: Integration EF6 & SQL     |   9 PASS |  0 FAIL
      [PASS] Suite 03: HTTP & Authorization      |   8 PASS |  0 FAIL
      [PASS] Suite 04: FastAPI Contract Mocks    |  10 PASS |  0 FAIL
      [PASS] Suite 05: Security & Concurrency    |   9 PASS |  0 FAIL
      [PASS] Suite 06: Full Regression H01-H04   |   7 PASS |  0 FAIL
    --------------------------------------------------------------------------------
      TOTAL: 66 PASS / 0 FAIL | Tiempo Total: ~30 s (100% Satisfactorio)
    ================================================================================
    ```

---

## 3. Mensaje Final de Cierre

> *"EcoMix IA no solo cumple con los requerimientos funcionales de dosificación y estimación de resistencia mediante inteligencia artificial, sino que implementa una arquitectura empresarial sólida, respaldada por prácticas de seguridad rigurosas: aislamiento multi-inquilino de recetas privadas, inmutabilidad histórica mediante snapshots, política de retención de auditoría de 30 días, protección contra desgobierno del último administrador y un control presupuestario estricto en la nube."*
