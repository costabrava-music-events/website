# Meta Publishing CBME

## Configuración

El publicador local es `scripts/social/meta_publish 2.py`. Lee `_private/meta.env` con:

- `META_ACCESS_TOKEN`
- `META_APP_ID` y `META_APP_SECRET`
- `IG_USER_ID`
- `FB_PAGE_ID`
- `PUBLIC_ASSET_BASE`

Nunca imprimir ni incluir estos valores en una respuesta o en commits.

## Comandos

Desde la raíz del proyecto:

```sh
python3 "scripts/social/meta_publish 2.py" check-config
python3 "scripts/social/meta_publish 2.py" check-token-scopes --instagram
python3 "scripts/social/meta_publish 2.py" plan docs/social/<cola>.json
python3 "scripts/social/meta_publish 2.py" publish-due docs/social/<cola>.json --id <job-id>
python3 "scripts/social/meta_publish 2.py" publish-due docs/social/<cola>.json --id <job-id> --live
```

`--live` publica de verdad. Para feed o Story futura, usar `schedule-pending`; Reels no se programan con esta CLI.

## Job de Reel

```json
{
  "id": "2026-08-03-campana-reel",
  "scheduled_at": "2026-08-03T12:00:00+02:00",
  "asset": "assets/social/campana/cbme-reel.mp4",
  "video_url": "https://…/cbme-reel.mp4",
  "platforms": ["instagram_reel"],
  "share_to_feed": true,
  "thumb_offset": 8,
  "caption": "Texto del reel.",
  "hashtags": ["#CostaBravaMusicEvents"]
}
```

El vídeo debe estar en una URL HTTPS pública que responda 200. Si `PUBLIC_ASSET_BASE` aún no sirve el asset, usar una URL pública segura ya disponible y verificarla. No publicar material privado en servicios públicos improvisados.

## Incidencias

- `OAuthException` 190, subcódigo 463: el token expiró. Renovarlo antes de continuar.
- Contenedor en proceso: esperar y consultar; no ejecutar un segundo `--live`.
- No hay estado local pero el proceso parece terminar: listar los últimos medios del IG y comparar copy/timestamp antes de reintentar.
