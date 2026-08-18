# Renovar el token de Meta para Instagram CBME

Esta guía se usa cuando Meta devuelve `OAuthException` 190 / subcódigo 463 o cuando el token ha caducado.

## 1. Generar un token nuevo

1. Inicia sesión con el usuario de Meta que administra la página de Facebook vinculada a `@costabrava_music_events` y abre el [Graph API Explorer](https://developers.facebook.com/tools/explorer/).
2. Selecciona la aplicación de Meta de CBME, no la aplicación genérica del Explorer.
3. Elige **User Token** y **Get User Access Token**.
4. Solicita estas permissions:
   - `instagram_basic`
   - `instagram_content_publish`
   - `pages_show_list`
   - `pages_read_engagement`
   - `business_management`
5. Genera el token y cópialo solo en el archivo local `_private/meta.env`, sustituyendo el valor de `META_ACCESS_TOKEN`.

No pegues el token en chats, incidencias, capturas, commits ni pull requests.

## 2. Convertirlo en token de larga duración

Desde la raíz del proyecto:

```sh
python3 "scripts/social/meta_publish 2.py" exchange-long-lived --write
```

El comando usa `META_APP_ID` y `META_APP_SECRET` del mismo `_private/meta.env`, cambia el token corto por uno de larga duración y actualiza el archivo local.

## 3. Verificar antes de publicar

```sh
python3 "scripts/social/meta_publish 2.py" check-config
python3 "scripts/social/meta_publish 2.py" debug-token
python3 "scripts/social/meta_publish 2.py" check-token-scopes --instagram
```

Debe aparecer `Scopes OK` y no debe aparecer un error OAuth 190/463. Si falla, no ejecutar `publish-due --live`.

## 4. Reanudar una publicación

Después de verificar el token, avisar: `token renovado`. Revisar primero el dry-run y publicar solo el job aprobado:

```sh
python3 "scripts/social/meta_publish 2.py" publish-due docs/social/<cola>.json --id <job-id>
python3 "scripts/social/meta_publish 2.py" publish-due docs/social/<cola>.json --id <job-id> --live
```

Para un Reel que falló antes de crear el contenedor, se puede reintentar una vez tras renovar y verificar el token. Si Meta devuelve un contenedor en proceso, esperar y consultar; no crear otro.
