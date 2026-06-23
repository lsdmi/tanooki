# Tanooki

Українська платформа для читання ранобе.

## Функції

- Читання ранобе з розділами
- Google OAuth аутентифікація
- Адмін-панель
- Прогрес читання
- Коментарі
- Пошук (OpenSearch + Searchkick)
- Система битв Покемонів

## Технології

- Ruby 3.4.9 / Rails 8
- MySQL (app DB + Solid Cache + Solid Queue)
- OpenSearch (DO Managed)
- Hotwire (Turbo, Stimulus), Propshaft, Importmap — **без Node/npm**
- Tailwind CSS (`tailwindcss-rails`)

## Встановлення

```bash
git clone <repository>
cd tanooki
cp .env.example .env   # налаштуйте DB_PASSWORD та інші змінні
bundle install
bin/rails db:create db:migrate db:seed
bin/dev                # web + Tailwind watch + Solid Queue worker
```

Локально `bin/dev` запускає через Foreman (`Procfile.dev`):

| Процес | Команда |
|--------|---------|
| Web | `bin/rails server` |
| CSS | `bin/rails tailwindcss:watch` |
| Jobs | `bin/jobs start` (Solid Queue) |

Node/npm не потрібні — JavaScript через Importmap, стилі через Tailwind gem.

### OpenSearch (локально, опційно)

Пошук потребує DO Managed OpenSearch. Додайте `OPENSEARCH_*` з `.env.example`, потім:

```bash
bin/rails runner "Searchkick.callbacks(:inline) { Fiction.reindex; Publication.reindex; YoutubeVideo.reindex }"
```

## Тести та якість

```bash
bin/rails test
bin/rubocop
bin/quality    # RuboCop, Brakeman, bundler-audit, erb_lint
```

## Деплой

Production — [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/) (`baka.in.ua`). Push to `main` on GitHub (`lsdmi/tanooki`) triggers deploy. Env vars — App Platform dashboard (див. `.env.example`).

### Компоненти App Platform

| Component | Run command | Примітки |
|-----------|-------------|----------|
| **Web** | `bin/rails server` | Health check: `GET /up` |
| **Worker** | `bin/jobs start` | Solid Queue; `SOLID_QUEUE_IN_PUMA=false` |

`Aptfile` встановлює libvips для Active Storage thumbnails. Після деплою:

```bash
bundle exec rails runner "puts Attachments::VariantProcessing.available?"
# → true
```

Managed add-ons: MySQL, OpenSearch. Asset CDN — опційно через `ASSET_HOST` (DigitalOcean Spaces).

## Структура

```
app/controllers/     # Контролери
app/models/          # Моделі
app/views/           # Представлення
config/              # Конфігурація
db/                  # Міграції
docs/                # Архітектура та modernization spike
```

## Конфігурація

- `config/database.yml` — MySQL
- `config/cache.yml` / `config/queue.yml` — Solid Cache, Solid Queue
- `config/credentials.yml.enc` — секрети
- `.env` — локально; production — App Platform env vars

## Ліцензія

Приватний проект.
