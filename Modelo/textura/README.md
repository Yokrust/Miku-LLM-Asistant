# Cerrar los ojos de Miku

`DISENO.md` §18 daba esto por bloqueado a la espera de reexportar el modelo 3D.
No hace falta: **los ojos están pintados en la textura, no modelados.**

El USDZ es una malla estática con una sola textura horneada — sin blend shapes, sin
esqueleto y sin geometría de ojos separada. Comprobado descomprimiendo el `.usdz`,
que sólo contiene `scene.usdc` y `imagetexture_baseColor.jpg`.

## Cómo hacerlo

1. Abre `baseColor-original.jpg` (2048 × 1024).
2. El ojo es la **forma azul de la mitad inferior, hacia el centro** del atlas.
   Es un solo ojo: la UV lo espeja para los dos lados, así que pintas una vez.
3. Píntalo cerrado — la línea de párpado y las pestañas, en el tono de la piel.
4. Guarda como `baseColor-ojos-cerrados.jpg` en esta misma carpeta.
5. Regenera el render:

```bash
swift MikuApp/Scripts/render-miku.swift \
  "Modelo/Hatsune Miku Low Poly Model.usdz" \
  MikuApp/Resources/Assets \
  Modelo/textura/baseColor-ojos-cerrados.jpg
```

El tercer argumento sustituye la textura al vuelo, sin tocar el `.usdz`.

Con los ojos cerrados y el aura, «en reposo» se leerá como la composición pedía:
ella dormida, esperando su nombre.
