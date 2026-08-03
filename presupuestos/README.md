# Sistema de pressupostos CBME

Accede al editor desde el sitio publicado. El acceso se realiza con Google y
solo permite la cuenta administradora configurada en Firebase.

- `data.js`: catàleg de preus, plantilles, IVA, paga i senyal i dades de l'empresa.
- `index.html`: editor i vista previa.
- `styles.css`: disseny de pantalla i impressio.
- `app.js`: editor, borrador local y guardado del histórico en Firestore.
- `../firestore.rules`: acceso privado y validación de los presupuestos.

Flux recomanat:

1. Tria una plantilla.
2. Omple dades de client i event.
3. Afegeix, edita o elimina partides.
4. Revisa condicións.
5. Pulsa `Guardar` para crear una versión en el histórico.
6. Abre cualquier presupuesto guardado para editarlo; cada guardado conserva
   una versión anterior.
7. Pulsa `Imprimir / PDF` y guarda el documento como PDF.

Els preus inicials venen dels pressupostos de referencia aportats i s'han deixat com a base editable.
