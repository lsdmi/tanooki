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

```bash
cap production deploy
```

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
- `.env` - змінні середовища
- `config/deploy.rb` - налаштування деплою

## 📝 Ліцензія

Приватний проект.
