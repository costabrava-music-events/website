# Reel Can Marc - fiesta boda 2026-06-08

Estado: republicacion en catalan corregido solicitada por Albert.

## Entregables

- Video local: `assets/social/can-marc-2026-06-08/can-marc-fiesta-boda.mp4`
- Cola Meta: `docs/social/can-marc-2026-06-08-meta-queue.json`

## Direccion

- Formato recomendado: Reel.
- Motivo: video real de fiesta, energia alta, mejor encaje que post estatico.
- Enfoque: pista, ambiente y servicio musical de boda en masia.
- Venue: `@eljardicanmarc_begur` (handle confirmado desde la web oficial de Can Marc).

## Copy

Festa de casament a El Jardí de Can Marc.

Aquell moment en què el sopar queda enrere, s'encén la pista i la música ja té una sola missió: que ningú vulgui marxar.

Gràcies @eljardicanmarc_begur per l'espai.

#BodaCanMarc #ElJardiDeCanMarc #BodesCostaBrava #BodesBegur #DJCasaments #WeddingDJSpain #CostaBravaMusicEvents

## Permisos

- Albert ha pedido publicarlo ahora y etiquetar a Can Marc.
- Mantener el copy sin nombres de pareja ni invitados.
- Si alguien reconocible pide retirada, borrar el reel desde Instagram/Meta.

## Publicacion

Requiere que el MP4 este disponible en URL publica bajo `https://costabravamusicevents.com`.

Comprobar:

```sh
python3 scripts/social/meta_publish.py plan docs/social/can-marc-2026-06-08-meta-queue.json
```

Publicar:

```sh
python3 scripts/social/meta_publish.py publish-due docs/social/can-marc-2026-06-08-meta-queue.json --id 2026-06-08-can-marc-fiesta-boda-reel-ca-ortografia --live --allow-pending-permission
```
