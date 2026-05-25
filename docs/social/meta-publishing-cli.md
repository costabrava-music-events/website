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
python3 scripts/social/meta_publish.py plan docs/social/week-2026-05-25-meta-queue.json
python3 scripts/social/meta_publish.py publish-due docs/social/week-2026-05-25-meta-queue.json
python3 scripts/social/meta_publish.py publish-due docs/social/week-2026-05-25-meta-queue.json --live
```

Sin `--live` solo simula.

## Limitaciones

- Feed de Instagram: automatizable.
- Foto en Facebook: automatizable.
- Story simple: automatizable.
- Story con encuesta o cuenta atras: el CLI puede publicar la story simple. El sticker interactivo queda como nota manual si se quiere completar/republicar desde Instagram.
- Can Marc queda bloqueado por permiso salvo que se use `--allow-pending-permission`.
