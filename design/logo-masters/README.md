# Site logo masters (not served)

Full-size WebP (~945×360). **Not** in the Propshaft pipeline.

Runtime:

| Surface | Asset |
|---|---|
| Navbar (+ theme toggle) | `app/assets/images/logo-{default,dark}-nav.webp` (280w) |
| Footer | `app/assets/images/logo-dark.webp` (600w; footer is always on dark zinc) |

`logo-*.svg` in `app/assets/images/` are tiny stubs used as **test upload fixtures**, not art masters.

## Regenerate runtime sizes

```bash
cd "$(git rev-parse --show-toplevel)"
magick design/logo-masters/logo-default.webp -resize 280x -strip -quality 82 \
  app/assets/images/logo-default-nav.webp
magick design/logo-masters/logo-dark.webp -resize 280x -strip -quality 82 \
  app/assets/images/logo-dark-nav.webp
magick design/logo-masters/logo-dark.webp -resize 600x -strip -quality 82 \
  app/assets/images/logo-dark.webp
```

Light full-size footer logo is unused (footer stays dark); regenerate `logo-default.webp` only if a light footer appears.
