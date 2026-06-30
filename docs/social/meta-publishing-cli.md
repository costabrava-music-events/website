# Meta publishing CLI

CLI local para publicar cola social de CBME por Meta Graph API.

## Config privada

Crear `_private/meta.env`:

```sh
META_ACCESS_TOKEN=...
IG_USER_ID=...
FB_PAGE_ID=...
PUBLIC_ASSET_BASE=https://costabravamusicevents.com
```

Los assets deben estar publicados bajo `PUBLIC_ASSET_BASE`, porque Instagram Content Publishing API requiere `image_url` publica.

## Comandos

```sh
python3 scripts/social/meta_publish.py check-config --facebook
python3 scripts/social/meta_publish.py check-token-scopes --instagram --facebook
python3 scripts/social/meta_publish.py plan docs/social/week-2026-05-25-meta-queue.json
python3 scripts/social/meta_publish.py schedule-pending docs/social/week-2026-05-25-meta-queue.json
python3 scripts/social/meta_publish.py schedule-pending docs/social/week-2026-05-25-meta-queue.json --live
python3 scripts/social/meta_publish.py publish-due docs/social/week-2026-05-25-meta-queue.json
python3 scripts/social/meta_publish.py publish-due docs/social/week-2026-05-25-meta-queue.json --live
python3 scripts/social/meta_publish.py publish-due docs/social/seasea-2026-05-29-meta-queue.json --id 2026-05-29-seasea-reel --live
```

Sin `--live` solo simula.

`schedule-pending` crea contenedores programados reales en Instagram para trabajos futuros y los guarda en `_private/meta_publish_state.json`. `publish-due` salta los jobs ya programados para no duplicarlos.

`check-token-scopes` acepta `instagram_content_publish` y `instagram_content_publishing` como equivalentes, porque Meta usa ambos nombres segun el flujo de login.

## Limitaciones

- Feed de Instagram: automatizable y programable.
- Reel de Instagram: automatizable como publicacion directa con `instagram_reel`; requiere `asset`/`video_url` publico y espera a que Meta termine de procesar el contenedor.
- Foto en Facebook: automatizable.
- Story simple: automatizable y programable.
- Story con encuesta o cuenta atras: el CLI puede publicar la story simple. El sticker interactivo queda como nota manual si se quiere completar/republicar desde Instagram.
- La programacion real via API puede devolver `(#3) User must be on whitelist`. Si pasa, Meta no deja crear posts planificados con esta app/cuenta y toca usar disparo exacto propio o programar desde Meta Business Suite.
- Can Marc queda bloqueado por permiso salvo que se use `--allow-pending-permission`.
