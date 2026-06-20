# Prompt Template

## Style Block

hand-drawn adventure cartoon illustration, post-apocalyptic robot world, bold uneven ink outlines, screen-print inspired limited palette, readable silhouette, expressive action, subtle paper grain, controlled detail density

## Constraint Block

no text, no letters, no numbers, no watermark, no card frame, no UI elements, single focal point, safe margins, clean readable silhouette

## Icon-specific guidance

centered composition, one dominant shape, high-contrast silhouette, transparent background, readable at 24-40px

## Per-asset fill-in fields

- subject
- action
- camera
- palette accent
- mood
- gameplay read
- background handling

## Export rules

- Runtime outputs go to the `runtime_output_path` listed in `asset-manifest.csv`
- Transparent subjects export as PNG
- Event illustration may stay PNG for this pack to preserve crisp linework
- Do not bake text, counters, rarity, or button chrome into any generated image
