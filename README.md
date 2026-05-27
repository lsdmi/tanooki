# Tanooki

Українська платформа для читання ранобе.

## Функції

- Читання ранобе з розділами
- Google OAuth аутентифікація
- Адмін-панель
- Прогрес читання
- Коментарі
- Пошук (OpenSearch)
- Система битв Покемонів

## Технології

- Ruby on Rails 7
- MySQL
- OpenSearch
- Tailwind CSS

## Встановлення

```bash
git clone <repository>
cd tanooki
bundle install
npm install
rails db:create db:migrate db:seed
rails server
```

## Деплой

Production runs on [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/). Push to `main` on GitHub (`lsdmi/tanooki`) to trigger a deploy. Set environment variables in the App Platform dashboard (see `.env.example`).

## Структура

```
app/controllers/     # Контролери
app/models/         # Моделі
app/views/          # Представлення
config/             # Конфігурація
db/                 # Міграції
```

## 🔧 Конфігурація

- `config/database.yml` - налаштування БД
- `config/credentials.yml.enc` - секрети
- `.env` - змінні середовища (локально; production — App Platform env vars)

## 📝 Ліцензія

Приватний проект.
