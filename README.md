# Costa Brava Music Events — Web estática (GitHub Pages)

Sitio **100% estático** (solo **HTML + CSS + JavaScript**) para *Costa Brava Music Events*.

Incluye:
- **Diseño moderno 2026** (hero inmersivo, micro-animaciones, scroll suave)
- **Tailwind CSS (CDN)** + utilidades custom mínimas en `assets/css/styles.css`
- **Alpine.js (CDN)** para menú móvil e interacciones ligeras
- **Swiper.js** para carrusel de galería
- **AOS** para animaciones on-scroll
- Performance: `<picture>` + `srcset` + `loading="lazy"` donde aplica

> Nota: Las imágenes de demo se cargan desde Unsplash (externas) para que el diseño luzca desde el primer día.
> Puedes reemplazarlas por imágenes locales en `assets/img/` cuando tengas tu media final.

---

## Estructura del proyecto

```
/
  index.html
  about.html
  gallery.html
  contact.html
  assets/
    css/
      styles.css
    js/
      main.js
    img/
      brand-mark.svg
```

---

## Cómo previsualizar en local

Opción rápida (doble clic): abre `index.html` en tu navegador.

Opción recomendada (servidor local):

```bash
python3 -m http.server 4173
```

Luego abre `http://localhost:4173`.

---

## Publicar en GitHub Pages (hoy mismo)

1. Sube el repositorio a GitHub (si aún no lo está).
2. Ve a **Settings → Pages**.
3. En **Build and deployment**:
   - **Source**: *Deploy from a branch*
   - **Branch**: `main`
   - **Folder**: `/ (root)`
4. Guarda. En 1–3 minutos tendrás la URL publicada.

---

## Personalización rápida (imprescindible)

- **Contacto**
  - Cambia `hello@costabravamusicevents.com` y `+34 600 000 000` en `index.html` y `contact.html`.
- **Formulario**
  - Sustituye `https://formspree.io/f/your-form-id` por tu endpoint real de Formspree.
- **Redes**
  - Actualiza los enlaces del footer (Instagram/TikTok/Spotify).
- **Imágenes**
  - Reemplaza URLs externas por archivos en `assets/img/` y ajusta `srcset`.

---

## Notas técnicas

- **JS**
  - Lógica compartida en `assets/js/main.js` (parallax sutil, Swiper, AOS y estado Alpine).
- **CSS**
  - Tailwind hace el 95% del styling; `assets/css/styles.css` contiene efectos y helpers (noise, focus, x-cloak).

