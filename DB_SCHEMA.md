# Схема базы данных (SQLite) — mi_crm

Источник правды: `lib/data/local/local_database.dart` (создание таблиц + миграции).

## Текст для отчета (Word-ready)

### 1. Назначение базы данных
Локальная база данных SQLite используется для хранения всех основных сущностей CRM (компания, сотрудники, товары, продажи, документы, коммуникации и т.д.). Подход offline-first позволяет работать без сервера и сети; данные живут на устройстве пользователя.

### 2. Выбор хранилища и особенности реализации
- Используется SQLite через `sqflite`; на Linux/Windows включается FFI (`sqflite_common_ffi`) для совместимости.
- Схема создается/обновляется в `LocalDatabase` при первом запуске и при изменении версии БД (миграции).
- В таблицах практически не используются явные `FOREIGN KEY`; связи представлены логически через поля `*_id`.

### 3. Основные домены данных
1) Пользователи и доступ: `users`, связка с `employees.user_id`.  
2) Организационная структура компании: `companies`, `departments`, `positions`, `employees`.  
3) Продажи и товары: `product_categories`, `products`, `leads`, `sales_records`.  
4) Документооборот: `documents`.  
5) PR/SMM: `pr_assets`, `smm_posts`.  
6) Коммуникации и задачи: `employee_messages`.  
7) Финансы: `accounting_entries`, а также глобальная таблица `operations`.

### 4. Важные договоренности (ограничения модели)
- `owner_ids` в некоторых таблицах — строка с ID сотрудников через запятую (без отдельной таблицы связей many-to-many).
- `operations` — глобальные операции без привязки к `company_id` (в текущей реализации).
- `target_type + target_id` в `accounting_entries` — универсальная ссылка на “цель” проводки (полиморфная связь).

Примечания:
- В большинстве таблиц **нет явных FOREIGN KEY** в SQLite, связи ниже — логические (по именам `*_id`).
- Поля `owner_ids` — строка с ID сотрудников через запятую.
- Таблица `operations` не содержит `company_id` (операции глобальные для приложения).

## ER-диаграмма (ASCII)

```
                         +------------------+
                         |     users        |
                         |------------------|
                         | id PK            |
                         | email UNIQUE     |
                         | password         |
                         +------------------+
                                  ^
                                  | employees.user_id (опц.)
                                  |
+------------------+     +------------------+        +---------------------+
|    companies     |<----|    employees     |<-------|  employee_messages  |
|------------------| 1..*|------------------| 1..*   |---------------------|
| id PK            |     | id PK            |        | id PK               |
| name             |     | company_id       |        | sender_id -> emp.id |
| created_at       |     | email UNIQUE     |        | receiver_id -> emp  |
+------------------+     | name             |        | kind/status/...     |
   ^   ^    ^   ^        | position_id      |        +---------------------+
   |   |    |   |        | department_id    |
   |   |    |   |        | status           |
   |   |    |   |        | user_id (опц.)   |
   |   |    |   |        +------------------+
   |   |    |   |              ^      ^
   |   |    |   |              |      |
   |   |    |   |              |      +------------------------------+
   |   |    |   |              |                                     |
   |   |    |   |     +------------------+                   +------------------+
   |   |    +-------->|   departments    |                   |    positions     |
   |   |              |------------------|                   |------------------|
   |   |              | id PK            |                   | id PK            |
   |   |              | company_id       |                   | company_id       |
   |   |              | title            |                   | title            |
   |   |              | head_employee_id |-----> emp.id      | modules (csv)    |
   |   |              +------------------+                   | submodules (json)|
   |   |                                                     | is_head          |
   |   |                                                     +------------------+
   |   |
   |   |    +---------------------+      +------------------+      +------------------+
   |   +--->| product_categories  |<-----|     products     |<-----|      leads       |
   |        |---------------------| 1..* |------------------| 0..* |------------------|
   |        | id PK               |      | id PK            |      | id PK            |
   |        | company_id          |      | company_id       |      | company_id       |
   |        | title               |      | category_id      |      | name/contact     |
   |        +---------------------+      | title            |      | status           |
   |                                     | price/stock/...  |      | product_id (опц) |
   |                                     +------------------+      +------------------+
   |
   |        +------------------+      +------------------+      +------------------+
   +------->|   sales_records  |      |    documents     |      |     pr_assets    |
   |        |------------------|      |------------------|      |------------------|
   |        | id PK            |      | id PK            |      | id PK            |
   |        | company_id       |      | company_id       |      | company_id       |
   |        | product_id (опц) |      | product_id (опц) |      | product_id (опц) |
   |        | type/qty/amount  |      | type/title/note  |      | title/note       |
   |        | owner_ids (csv)  |      | owner_ids (csv)  |      | created_at       |
   |        | created_at       |      | created_at       |      +------------------+
   |        +------------------+      +------------------+
   |
   |        +------------------+      +----------------------+
   +------->|    smm_posts     |      |  accounting_entries  |
            |------------------|      |----------------------|
            | id PK            |      | id PK                |
            | company_id       |      | company_id           |
            | product_id (опц) |      | target_type/target_id|
            | channel/message  |      | delta/note/created_at|
            | status/created_at|      +----------------------+
            +------------------+

  +------------------+ (глобально, без company_id)
  |    operations    |
  |------------------|
  | id PK            |
  | type/amount/...  |
  | owner_ids (csv)  |
  | created_at       |
  +------------------+

  +------------------+
  |     modules      |
  |------------------|
  | id PK (TEXT)     |
  | title/desc       |
  | enabled/sort     |
  +------------------+
```

## Таблицы и поля

### `users`
- `id` INTEGER PK AUTOINCREMENT
- `email` TEXT UNIQUE
- `password` TEXT

### `operations` (глобальные)
- `id` INTEGER PK AUTOINCREMENT
- `type` TEXT
- `amount` REAL
- `description` TEXT
- `owner_ids` TEXT (csv)
- `created_at` INTEGER (epoch ms)

### `modules`
- `id` TEXT PK
- `title` TEXT
- `description` TEXT
- `enabled` INTEGER (0/1)
- `sort_order` INTEGER

### `companies`
- `id` INTEGER PK AUTOINCREMENT
- `name` TEXT
- `created_at` INTEGER (epoch ms)

### `positions`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `title` TEXT
- `modules` TEXT (csv, IDs модулей)
- `is_head` INTEGER (0/1)
- `submodules` TEXT (JSON)

### `departments`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `title` TEXT
- `head_employee_id` INTEGER (опц.) -> `employees.id`

### `employees`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `email` TEXT UNIQUE
- `name` TEXT
- `position_id` INTEGER -> `positions.id`
- `status` TEXT
- `department_id` INTEGER -> `departments.id`
- `user_id` INTEGER (опц.) -> `users.id`

### `employee_messages`
- `id` INTEGER PK AUTOINCREMENT
- `sender_id` INTEGER -> `employees.id`
- `receiver_id` INTEGER -> `employees.id`
- `text` TEXT
- `kind` TEXT (`message`/`task`)
- `urgency` TEXT (опц.)
- `due_date` INTEGER (опц., epoch ms)
- `status` TEXT (например `open`)
- `comment` TEXT (опц.)
- `created_at` INTEGER (epoch ms)

### `product_categories`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `title` TEXT

### `products`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `category_id` INTEGER -> `product_categories.id`
- `title` TEXT
- `price` REAL
- `stock` INTEGER
- `reserved` INTEGER

### `leads`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `name` TEXT
- `contact` TEXT
- `status` TEXT
- `product_id` INTEGER (опц.) -> `products.id`

### `sales_records`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `product_id` INTEGER (опц.) -> `products.id`
- `type` TEXT
- `quantity` INTEGER
- `amount` REAL
- `note` TEXT (опц.)
- `owner_ids` TEXT (csv)
- `created_at` INTEGER (epoch ms)

### `documents`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `product_id` INTEGER (опц.) -> `products.id`
- `type` TEXT
- `title` TEXT
- `note` TEXT (опц.)
- `owner_ids` TEXT (csv)
- `created_at` INTEGER (epoch ms)

### `pr_assets`
- `id` INTEGER PK AUTOINCREMENT
- `product_id` INTEGER (опц.) -> `products.id`
- `company_id` INTEGER -> `companies.id`
- `title` TEXT
- `note` TEXT (опц.)
- `created_at` INTEGER (epoch ms)

### `smm_posts`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `product_id` INTEGER (опц.) -> `products.id`
- `channel` TEXT
- `message` TEXT
- `status` TEXT
- `created_at` INTEGER (epoch ms)

### `accounting_entries`
- `id` INTEGER PK AUTOINCREMENT
- `company_id` INTEGER -> `companies.id`
- `target_type` TEXT (например `product`)
- `target_id` INTEGER (ID цели в зависимости от `target_type`)
- `delta` REAL
- `note` TEXT
- `created_at` INTEGER (epoch ms)
