# Guía de Demostración del Sistema — EcoMix IA (Avance MVP)

**Proyecto:** EcoMix IA — Sistema Inteligente de Dosificación y Optimización de Mezclas de Concreto Ecológico  
**Versión:** MVP Local Demostrable (Fase 1 completada + Prototipo de Identidad F2.3-A)  
**Fecha de Demostración:** 9 de noviembre de 2026  
**Entorno de Ejecución:** ASP.NET MVC 5 / .NET Framework 4.7.2 / SQL Server LocalDB / Bootstrap 5.3.3 / IIS Express  

---

## 1. Instrucciones de Ejecución Local

Para levantar el prototipo localmente en modo demostración controlada:

### Paso 1: Terminal en raíz del repositorio
```powershell
cd "C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema"
```

### Paso 2: Compilación de verificación con MSBuild
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" EcomixIA.csproj /p:Configuration=Debug /t:Build /verbosity:minimal
```

### Paso 3: Iniciar el servidor local IIS Express
```powershell
& "C:\Program Files\IIS Express\iisexpress.exe" /config:".vs\EcomixIA\config\applicationhost.config" /site:EcomixIA
```

### URLs de Acceso Local
- **URL Principal (HTTPS):** [https://localhost:44357/](https://localhost:44357/)
- **URL Secundaria (HTTP):** [http://localhost:62778/](http://localhost:62778/)

---

## 2. Mapa de Funcionalidades: Operativas vs. En Curso

| Componente | Estado en Demo | Alcance Técnico Preciso y Demostrable |
| :--- | :---: | :--- |
| **Portada Promocional y Carrusel** | **Operativo (100%)** | Navegación responsive, 3 diapositivas WebP optimizadas con metas de mitigación ambiental basadas en literatura y enlaces a módulos. |
| **Catálogo de Materiales** | **Operativo (100%)** | 10 materiales sostenibles cargados en base local, con densidades, precios unitarios de referencia y factores teóricos de emisión de CO₂. |
| **Catálogo de Mezclas (Muestras Legadas)** | **Operativo (100%)** | 8 mezclas experimentales legadas utilizadas para pruebas locales de desarrollo y calibración de cálculos (no homologadas como plantillas industriales). |
| **Simulador de Inferencia ML** | **Operativo (100%)** | Formulario con los 7 componentes en kg/m³, cálculo aritmético de masa/relación a/c y consulta de predicciones estadísticas preliminares. |
| **Precarga de Parámetros en Simulador** | **Operativo (100%)** | Enlace desde el detalle de la mezcla de prueba hacia el simulador para precargar los 7 valores numéricos. |
| **Infraestructura Identity 2 / OWIN** | **Verificado en Ensayo** | Implementación de registro con filtro estricto de dominios institucionales (`@upt.pe`, `@virtual.upt.pe`) y lista blanca de investigación (`@gmail.com`). |
| **Autenticación (Login / Lockout / LogOff)** | **Verificado en Ensayo** | Control de acceso con exigencia obligatoria de correo confirmado, bloqueo preventivo tras 5 intentos fallidos y cierre de sesión con token antifalsificación (CSRF). |
| **Emisión de Correo Transaccional** | **Modo Desarrollo Local** | Emisor simulado en carpeta local `App_Data/EmailOutbox/` para no exponer credenciales ni depender de pasarelas SMTP externas. |
| **Recuperación de Contraseñas** | *Postergado* | Se abordará en la subetapa F2.3-B. |
| **Panel de Administración RBAC** | *Postergado* | Gestión de usuarios, perfiles y auditoría avanzada programados para F2.4. |

---

## 3. Limitación de Seguridad Crítica: Brecha Pendiente de Autorización Server-Side

> [!WARNING]
> **Condición de Seguridad Actual (No Apta para Despliegue Público ni Cuentas Reales):**
> En la arquitectura actual, los visitantes anónimos pueden consultar las 8 mezclas legadas (`/Mezclas/Index`, `/Mezclas/Details/1`), mientras que las cuentas autenticadas reciben una denegación de acceso (lista vacía o HTTP 403).
> 
> Esta condición se clasifica técnicamente como una **brecha pendiente de autorización server-side** (asimetría de acceso y falta de control de propiedad), y **NO** como un Safe Denial completo.
> 
> **Detalles técnicos esenciales:**
> 1. Las mezclas de la tabla `dbo.Mezclas` **no cuentan con un identificador de propietario (`OwnerUserId`)** en esta fase. Por tanto, **no son privadas por usuario**.
> 2. No se modifican apresuradamente los controladores en este momento para no desestabilizar la demostración local programada para hoy.
> 3. **Queda terminantemente prohibido habilitar despliegue público, apertura a internet o registro de usuarios reales** mientras no se subsane esta asimetría mediante la migración del modelo de propiedad en Fase 3 y una política de autorización uniforme en el servidor.

---

## 4. Guion de Demostración en 5 Minutos (Secuencia Segura)

```
00:00 — 01:00  [Minuto 1] Portada Institucional e Identidad Visual
01:00 — 02:00  [Minuto 2] Catálogo de Materiales y Mezcla de Ejemplo (4 componentes)
02:00 — 03:00  [Minuto 3] Simulador Predictivo con IA (Valores Precargados / Capturas)
03:00 — 04:00  [Minuto 4] Registro Institucional y Validación de Dominios (Fase 2)
04:00 — 05:00  [Minuto 5] Inicio de Sesión, Protección Lockout y Cierre Técnico
```

### Reglas Estrictas durante la Demostración
- **No enviar inferencias nuevas a Azure** durante la presentación; utilizar los datos ya calculados y las capturas de inferencia previamente verificadas.
- **No ejecutar operaciones de escritura** (crear/editar/eliminar materiales o mezclas en caliente).
- **No mostrar tokens, contraseñas ni archivos privados** del buzón simulado en `App_Data/EmailOutbox`.

---

### Minuto 1: Portada Institucional y Propuesta de Valor (0:00 - 1:00)
1. Abrir el navegador en `https://localhost:44357/`.
2. **Puntos a exponer:**
   - Presentar la interfaz responsive desarrollada con Bootstrap 5.3.3 y la identidad visual de **EcoMix IA**.
   - Mostrar el carrusel de tres diapositivas (Innovación en diseño de mezclas, Materiales sostenibles con adiciones puzolánicas, y Predicción de resistencia a 7 y 28 días).
   - Aclarar que la meta de reducción de CO₂ (hasta 40%) corresponde a proyecciones bibliográficas del marco teórico regional (Tacna/Arequipa), sujetas a validación experimental.
   - Mostrar la insignia informativa *"Demostración Local"*.

### Minuto 2: Catálogo de Materiales y Mezcla de Ejemplo (1:00 - 2:00)
1. Hacer clic en **Materiales** (`/Materiales/Index`).
   - Mostrar los 10 insumos del catálogo local (Cemento Tipo I, Escoria de Alto Horno, Ceniza Volante, Superplastificante, Agregados, etc.).
   - Entrar al detalle de un material (`/Materiales/Details/1`) para exhibir sus propiedades técnicas (densidad, costo unitario por kg y factor de CO₂).
2. Hacer clic en **Mezclas** (`/Mezclas/Index`) y abrir la **Mezcla 1** (`/Mezclas/Details/1`).
   - Mostrar la mezcla de ejemplo estructurada con 4 componentes (Cemento Portland, Agua, Agregado Grueso y Agregado Fino).
   - Resaltar los indicadores calculados de forma determinista: masa total por m³, relación agua/cemento (a/c = 0.51) y costo por metro cúbico.

### Minuto 3: Simulador Predictivo con IA (2:00 - 3:00)
1. Desde la mezcla de ejemplo, hacer clic en el botón verde **"Simular con IA"** (`/Mezclas/Simulador?mezclaId=1`).
2. **Explicación técnica:**
   - Mostrar la precarga instantánea de los componentes en kg/m³.
   - Explicar la diferenciación metodológica: el balance volumétrico y los costos son aritméticos; la resistencia a la compresión a 7 y 28 días corresponde a una **inferencia estadística de Machine Learning** generada por un ensamble AutoML (VotingEnsemble).
   - **Aclaración mandatoria:** Enfatizar que estas estimaciones matemáticas son herramientas de asistencia al diseño y **no sustituyen los ensayos físicos normalizados de laboratorio (NTP 339.034 / ASTM C39) ni constituyen certificaciones estructurales**.
   - Mostrar los resultados previamente verificados (ej. ~26.4 MPa a 28 días) sin realizar llamadas a la nube durante la sesión.

### Minuto 4: Registro Institucional y Validación de Dominios (3:00 - 4:00)
1. Navegar a **Registrarse** (`/Account/Register`).
2. **Puntos de avance de Fase 2:**
   - Explicar la política de seguridad implementada: solo se admiten dominios institucionales autorizados (`@upt.pe`, `@virtual.upt.pe`) y correos de investigación preaprobados (`@gmail.com`).
   - Señalar los requisitos de robustez de contraseña (mínimo 8 caracteres, mayúscula, minúscula, número y símbolo especial).
   - Explicar el ciclo de activación: el usuario nace inactivo (`EmailConfirmed = false`) y requiere confirmación previa para operar.
   - Indicar que en el entorno local de desarrollo los correos se procesan a través de `SimulatedEmailService` para evitar consumo de servicios externos.

### Minuto 5: Inicio de Sesión, Protección Lockout y Cierre (4:00 - 5:00)
1. Navegar a **Ingresar** (`/Account/Login`).
2. **Exposición de mecanismos de seguridad:**
   - Destacar la protección contra ataques de fuerza bruta (*Account Lockout* tras 5 intentos fallidos por un lapso de 5 minutos).
   - Explicar la validación que impide el ingreso a cuentas con correo no confirmado.
   - **Transparencia técnica:** Mencionar que la infraestructura de identidad se probó de forma completamente aislada en una base secundaria (`EcomixIA_F2_Migration_Test`), preservando la base de datos principal intacta.
   - Detallar la limitación actual sobre la asimetría de acceso a mezclas legadas y los próximos pasos para corregirla.
3. Concluir la presentación resumiendo el avance del prototipo.

---

## 5. Limitaciones Reales del Prototipo Actual

1. **Aislamiento de la Base de Datos:**  
   La base principal `EcomixIA` permanece con su esquema original de 4 tablas de negocio (10 materiales, 8 mezclas, 32 componentes). La migración de Identity 2 (`AspNetUsers`, `AspNetRoles`, etc.) ha sido validada exclusivamente en la base secundaria de pruebas `EcomixIA_F2_Migration_Test`.
2. **Consumo de Servicios en la Nube:**  
   Durante la ejecución de las pruebas y la preparación de esta demostración **no se ha realizado ninguna invocación al endpoint de inferencia en Azure Container Apps** (0 llamadas ejecutadas). Esto certifica la ausencia de tráfico en la sesión, pero no implica costo nulo del recurso en Azure.
3. **Servicio de Correo Simulado:**  
   Los correos transaccionales se almacenan en formato JSON dentro de `App_Data/EmailOutbox/`, sin conexión a servidores SMTP de producción.
4. **Propiedad de Mezclas Pendiente:**  
   La tabla `dbo.Mezclas` no almacena autoría por usuario; la gestión privada de mezclas se desarrollará en Fase 3 tras regularizar la política de autorización server-side.

---

## 6. Próximos Pasos Técnicos Prioritarios

1. **Corrección de la Autorización Server-Side:** Unificar la política de acceso a las mezclas legadas para evitar la asimetría entre anónimos y autenticados antes de cualquier apertura pública.
2. **F2.3-B (Recuperación de Contraseñas):** Flujo de restablecimiento seguro mediante tokens temporales de un solo uso.
3. **F2.4 (Consolidación y Roles):** Ejecución de la migración Identity en la base principal bajo mantenimiento programado y asignación de roles (`Administrador`, `Investigador`, `Registrado`).
4. **Fase 3 (Modelo de Propiedad):** Incorporación del campo `OwnerUserId` en `dbo.Mezclas` para habilitar el aislamiento total de mezclas por usuario.
