# SEA SEA CLUB - Reel Instagram

Estado: reel v2 publicado y retirado manualmente por cortes raros. Nueva propuesta: usar video original sin cortes.

## Entregables

- Reel original privado: `_private/social/seasea-2026-05-29/seasea-original.mp4`
- Cola Meta: `docs/social/seasea-2026-05-29-meta-queue.json`

## Direccion

- Formato: Reel vertical 9:16
- Duracion: 27.2 s
- Tono: sunset / venue / evento preparado
- Enfoque: ambiente, montaje, luz y musica frente al mar
- Edicion: video original sin cortes para evitar saltos raros
- Audio: original del video; si se sube manualmente, valorar audio house/chill dentro de Instagram

## Copy sugerido

Barcelona, Mediterraneo y un espacio que cambia de ritmo con las horas.

En SEA SEA CLUB, sonido, luz y atmosfera trabajan juntos para que la experiencia fluya: desde el primer encuentro hasta el momento en que la musica toma el control.

Montaje preparado para una noche frente al mar.

#SeaSeaClub #BarcelonaEvents #BarcelonaNightlife #BeachClubBarcelona #MusicEvents #DJSets #CostaBravaMusicEvents

## Publicacion

No publicar sin aprobacion explicita.

El reel anterior fue publicado con id `17984672715006228` y retirado manualmente el 29/05/2026.

Comprobar plan:

```sh
python3 scripts/social/meta_publish.py plan docs/social/seasea-2026-05-29-meta-queue.json
```

Publicar de verdad, solo tras aprobacion:

```sh
python3 scripts/social/meta_publish.py publish-due docs/social/seasea-2026-05-29-meta-queue.json --id 2026-05-29-seasea-reel --live
```

Nota: Instagram Reels API necesita que el video este disponible en una URL publica bajo `PUBLIC_ASSET_BASE`. Mantener el asset publico solo durante la subida y retirarlo despues si no debe quedar en la web.
