---
name: publicar-instagram-cbme
description: "Crea, prepara, programa o publica contenido de Instagram para Costa Brava Music Events (CBME): Reels, Stories, posts y carruseles. Úsala cuando la petición mencione Instagram, Meta, @costabrava_music_events, contenido social de CBME, vídeos de boda/evento o la publicación/programación de esos formatos."
---

# Publicar Instagram CBME

Gestiona contenido para `@costabrava_music_events` desde el material hasta la verificación de publicación.

## Regla de publicación

- Crear, editar o preparar contenido no autoriza a publicarlo. Entregar borrador, asset y copy para revisión.
- Publicar o programar solo si el usuario lo pide explícitamente. Confirmar con la API que ha quedado creado; no asumir éxito.
- No exponer tokens, IDs privados ni URLs que contengan tokens.

## Preparar contenido

1. Inspeccionar el material disponible y reutilizar los patrones de `assets/social/` y `docs/social/`.
2. Definir una única idea, audiencia y CTA. Para copy persuasiva, usar la skill `copywriting`.
3. Adaptar el formato:
   - Reel: vídeo vertical 9:16, 1080x1920; ritmo breve, primer segundo claro y portada elegida.
   - Story: 9:16, 1080x1920; una acción o sticker por story. Los stickers interactivos requieren publicación manual.
   - Post: 4:5, 1080x1350.
   - Carrusel: 4:5, 1080x1350 y una idea progresiva por diapositiva.
4. Guardar assets en `assets/social/<campaña-fecha>/` y el copy/cola en `docs/social/<campaña>-meta-queue.json`.
5. No inventar disponibilidad, precios, testimonios, artistas, permisos o marcas. No usar música sin confirmar derechos.

## Cola de Meta

Leer `references/meta-publishing.md` antes de usar la API. Crear un job con `id`, `scheduled_at`, `asset`, `platforms`, `caption` y `hashtags`.

- Para Reels, añadir `video_url` pública y `share_to_feed`.
- Usar `thumb_offset` solo si se ha revisado el fotograma elegido.
- Incluir la URL pública real; comprobar que devuelve HTTP 200 antes de publicar.
- Mantener captions naturales, con 0–2 emojis salvo que el tono del evento pida más; cerrar con un CTA concreto.

## Publicar y verificar

1. Ejecutar `check-config` y `check-token-scopes --instagram` antes de una publicación real.
2. Si Meta devuelve token caducado (OAuth 190/463), detenerse y pedir renovación; no reintentar ni crear duplicados.
3. Ejecutar primero el comando sin `--live` y revisar asset, copy y destino.
4. Solo con autorización explícita, ejecutar `publish-due ... --live`.
5. Esperar el procesamiento de Reels. Confirmar el `permalink`, el copy y el tipo de medio mediante `/{IG_USER_ID}/media`; si la salida quedó incompleta, consultar antes de reintentar.
6. Registrar el estado local y devolver enlace, formato publicado y cualquier limitación pendiente.

## Límites operativos

- La API actual publica Reels directamente; no los programa. Feed y Stories simples pueden programarse.
- Las Stories con encuesta, preguntas o cuenta atrás requieren el acabado manual en Instagram.
- Conservar cambios ajenos del repositorio: añadir/confirmar solo archivos de la campaña.
