# Genre badge masters (not served)

Full-size WebP sources (~500×500). **Not** in `app/assets` — Propshaft must not digest these.

Runtime UI uses `app/assets/images/badges/thumbs/{slug}.webp` (104×104).

## Regenerate thumbs

```bash
cd "$(git rev-parse --show-toplevel)"
mkdir -p app/assets/images/badges/thumbs
for f in design/badge-masters/*.webp; do
  magick "$f" -resize 104x104^ -gravity center -extent 104x104 -strip -quality 78 \
    "app/assets/images/badges/thumbs/$(basename "$f")"
done
```

## Other sizes (e.g. medium ~200px)

Same loop with a different `-resize` / output dir under `app/assets/images/badges/`, then point the honors card (or other UI) at that path.
