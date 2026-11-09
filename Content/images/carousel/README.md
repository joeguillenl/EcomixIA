# Recursos Gráficos del Carrusel Promocional — EcoMix IA (F1.3 / F1.4)

Este directorio almacena los activos gráficos oficiales correspondientes a la subetapa **F1.3 / F1.4: Carrusel promocional con imágenes representativas y optimización WebP**, integrados en la portada del sistema.

---

## 1. Inventario y Especificaciones Reales de las Imágenes (Optimizadas en F1.4)

| Archivo | Diapositiva | Dimensiones | Ratio | Tamaño Original | Tamaño Optimizado | Reducción | Calidad Visual (PSNR) | Formato WebP |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `01-innovacion-concreto.webp` | 1 | **1672 × 941 px** | 16:9 (1.78:1) | 1,438,764 bytes (1.37 MB) | **132,772 bytes (129.7 KB)** | **-90.8%** | 40.52 dB (Excelente) | WebP (VP8, Q85) |
| `02-materiales-sostenibles.webp` | 2 | **1672 × 941 px** | 16:9 (1.78:1) | 1,522,642 bytes (1.45 MB) | **145,126 bytes (141.7 KB)** | **-90.5%** | 40.07 dB (Excelente) | WebP (VP8, Q85) |
| `03-resistencia-concreto.webp` | 3 | **1672 × 941 px** | 16:9 (1.78:1) | 115,636 bytes (112.9 KB) | **115,636 bytes (112.9 KB)** | Preservado | Base original | WebP (VP8) |

> **Nota sobre optimización:** En la subetapa F1.4 se aplicó compresión WebP con pérdida de alta fidelidad (Quality 85, método de compresión 6 en sRGB) a las imágenes 1 y 2, reduciendo el peso de transferencia total de 3.08 MB a solo 393.5 KB (reducción global del **87.2%**), manteniendo intactas las dimensiones nativas de 1672 × 941 px sin distorsión visible (PSNR > 40 dB).

---

## 2. Compatibilidad y Ajuste Visual Responsive

* **Resolución real:** Las tres imágenes comparten de forma homogénea una resolución nativa de **1672 × 941 px** con proporción panorámica **16:9**.
* **Tratamiento CSS (`Content/site.css`):**
  * La clase `.ecomix-carousel-img` aplica `object-fit: cover` y `object-position: center 35%`, asegurando que las fotografías cubran el contenedor responsive sin deformarse.
  * Altura desktop: `480px` (máximo `520px`).
  * Altura tablet (`768px - 991px`): `380px`.
  * Altura móvil (`< 768px`): `290px`.
* **Servidor local (IIS Express):** La asignación MIME `<mimeMap fileExtension=".webp" mimeType="image/webp" />` se encuentra registrada en la configuración de IIS Express, permitiendo la entrega con cabecera `image/webp` y código `HTTP 200 OK`.

---

## 3. Política de Derechos de Autor y Propiedad Intelectual (D-05)

En estricto cumplimiento de la decisión arquitectural **D-05** y los principios éticos de la Universidad Privada de Tacna:
1. **Procedencia declarada:** Fotografías representativas de laboratorio de ingeniería civil e insumos de concreto sostenible provistas para uso académico y de investigación formativa en el marco de la asignatura Programación Web II (2026).
2. **Desvinculación marcaria:** Ninguna de las imágenes exhibe logotipos comerciales, marcas registradas ni embalajes distintivos de Cementos Yura S.A. ni de terceras empresas del sector.
3. **Inclusión en proyecto:** Los tres archivos WebP y este documento se encuentran incorporados formalmente en `EcomixIA.csproj` con el elemento `<Content Include="..." />` para garantizar su inclusión en procesos de publicación web.
