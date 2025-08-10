# UltraStore - WordPress бэкенд

WordPress с WooCommerce для управления товарами и обработки заказов.

## Быстрый старт

```bash
# Запуск WordPress и базы данных
docker compose up wp db
```

Админка: http://localhost:8080/wp-admin

## Структура

```
backend/
├─ plugins/     # Плагины
├─ themes/      # Темы
└─ uploads/     # Загруженные файлы
```

## Полезные команды

```bash
# Выполнение WP-CLI команд
docker compose exec wordpress wp --help

# Просмотр логов
docker compose logs wordpress
```
