# Portal de Documentación Técnica Interactiva · EcoMix IA

Este directorio (`docs-interactive/`) contiene la documentación arquitectónica visual e interactiva del sistema **EcoMix IA**, generada con **Archify 3.2**.

El portal y sus diagramas son completamente **autónomos y estáticos**: no requieren de SQL Server, Internet Information Services (IIS) ni suscripciones activas a Microsoft Azure para ser explorados.

---

## 1. Contenido y Diagramas Interactivos

| Diagrama | Archivo HTML Renderizado | Archivo Fuente Editable | Tipo Archify | Estado Semántico |
|---|---|---|---|---|
| **Arquitectura General del Sistema** | [`arquitectura-general.html`](./arquitectura-general.html) | [`arquitectura-general.architecture.json`](./arquitectura-general.architecture.json) | `architecture` | 🟢 Implementado en Core / 🟡 BD no verificada |
| **Flujo de Registro y Creación de Mezclas** | [`flujo-registro-mezclas.html`](./flujo-registro-mezclas.html) | [`flujo-registro-mezclas.workflow.json`](./flujo-registro-mezclas.workflow.json) | `workflow` | 🟢 Implementado en Controladores |
| **Integración Propuesta con Azure ML** | [`integracion-azure-ml.html`](./integracion-azure-ml.html) | [`integracion-azure-ml.architecture.json`](./integracion-azure-ml.architecture.json) | `architecture` | 🔴 Propuesta Técnica Futura (No implementada) |
| **Modelo Entidad-Relación** | [`modelo-erd.html`](./modelo-erd.html) | [`modelo-erd.erd.json`](./modelo-erd.erd.json) | `erd` | 🟢 Implementado (EF6 / SQL Server) |

---

## 2. Convención Semántica de Estados

Para garantizar la máxima claridad técnica y evitar representar funcionalidades hipotéticas como existentes, los diagramas adoptan la siguiente convención visual:

- 🟢 **Implementado y Verificado en Código:** Componentes de software con código fuente existente en el proyecto C# / ASP.NET MVC 5 (`Controllers/`, `Models/`, `Views/`, `Content/`).
- 🟡 **Configurado / No Verificado en Runtime:** Artefactos presentes en el repositorio cuya ejecución requiere servicios externos no activos en este entorno (p. ej. instancia SQL Server `.\SQLEXPRESS` y script `DatosEjemplo.sql`).
- 🔴 / 🟣 **Propuesta Técnica para Futuras Fases:** Arquitectura proyectada para el repositorio externo `EcoMix-IA-AzureML` y microservicios de inferencia predictiva de resistencia ($f'c$). **No están implementados en la aplicación actual**.

---

## 3. Ejecución Local del Portal

El portal principal es [`index.html`](./index.html), el cual ofrece navegación por pestañas, modo oscuro predeterminado, tarjetas explicativas de sostenibilidad y visor embebido para los diagramas.

### Opción 1: Abrir directamente en el navegador
Puedes hacer doble clic sobre `docs-interactive/index.html` o abrirlo desde cualquier navegador moderno (Edge, Chrome, Firefox). Cada archivo HTML de Archify es completamente autónomo y no requiere servidor web.

### Opción 2: Servidor HTTP local ligero

#### Con Python:
```bash
# Desde la carpeta raíz del proyecto:
python -m http.server 8080 --directory docs-interactive
```
Luego abre en tu navegador: [http://localhost:8080](http://localhost:8080)

#### Con Node.js / npx:
```bash
npx serve docs-interactive
```

---

## 4. Cómo Actualizar y Recompilar los Diagramas

Todos los diagramas cuentan con su archivo fuente JSON editable en este directorio. Si realizas cambios en la arquitectura o en los modelos:

1. Edita el archivo `.json` correspondiente (p. ej. `arquitectura-general.architecture.json`).
2. Ejecuta la herramienta oficial de entrega y validación de Archify:

```bash
# Sintaxis general:
node <ruta-archify>/bin/archify.mjs deliver <tipo> <archivo-fuente.json> <archivo-salida.html> --quality showcase

# Ejemplos:
node archify/bin/archify.mjs deliver architecture docs-interactive/arquitectura-general.architecture.json docs-interactive/arquitectura-general.html --quality showcase
node archify/bin/archify.mjs deliver workflow docs-interactive/flujo-registro-mezclas.workflow.json docs-interactive/flujo-registro-mezclas.html --quality showcase
node archify/bin/archify.mjs deliver architecture docs-interactive/integracion-azure-ml.architecture.json docs-interactive/integracion-azure-ml.html --quality showcase
node archify/bin/archify.mjs deliver erd docs-interactive/modelo-erd.erd.json docs-interactive/modelo-erd.html --quality showcase
```

Cada invocación valida automáticamente las reglas de geometría, puertos, rutas ortogonales, esquemas JSON y emite un recibo criptográfico SHA-256 (`.delivery.json`).

---

## 5. Publicación en GitHub Pages

Para publicar este portal interactivo en GitHub Pages de forma pública o privada:

### Método A: Mediante GitHub Actions (Recomendado)

Crea el archivo `.github/workflows/deploy-docs.yml` en la raíz del repositorio con el siguiente contenido:

```yaml
name: Despliegue de Documentación EcoMix IA

on:
  push:
    branches: [ master, main ]
    paths:
      - 'docs-interactive/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout del código
        uses: actions/checkout@v4

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v4

      - name: Cargar artefacto de documentación
        uses: actions/upload-pages-artifact@v3
        with:
          path: 'docs-interactive/'

      - name: Desplegar en GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Método B: Publicación desde la carpeta `/docs`

Si prefieres la opción estándar de GitHub Pages basada en directorios:
1. En GitHub, ve a **Settings** > **Pages**.
2. En **Build and deployment** > **Source**, selecciona `Deploy from a branch`.
3. Copia o enlaza simbólicamente el contenido de `docs-interactive/` hacia una carpeta llamada `docs/` en la raíz.
4. Elige la rama `master` (o `main`) y la carpeta `/docs`.
5. Guarda los cambios. Tu documentación estará disponible en `https://<usuario>.github.io/<repositorio>/`.
