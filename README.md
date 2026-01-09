# mi_crm

Небольшое CRM-приложение на Flutter с офлайн базой данных (sqflite) и менеджером состояния Bloc. Приложение предоставляет вкладки «Главная», «Отчёт» и «Профиль», а также экраны авторизации и регистрации с сохранением сессии.

## Возможности
- Авторизация и регистрация с сохранением состояния пользователя.
- Добавление продаж, закупок и расходов на вкладке «Главная».
- Автоматическое формирование суммарных показателей на вкладке «Отчёт».
- Просмотр профиля и выход из аккаунта.
- Адаптивная навигация: навигационная панель снизу на телефонах и NavigationRail на широких экранах.
- Локальное хранение данных через `sqflite`.

## Запуск
Убедитесь, что установлен Flutter (3.16+). Затем:

```bash
flutter pub get
flutter run
```

### Desktop (Linux/Windows)
В репозитории добавлены заготовки проектов Linux и Windows. Перед первой сборкой выполните генерацию ephemeral-файлов:

```bash
flutter config --enable-linux-desktop --enable-windows-desktop
flutter pub get
flutter build linux   # или flutter run -d linux
flutter build windows # или flutter run -d windows
```

Приложение использует локальную базу данных и не требует удалённых сервисов.


## ER-диаграмма базы данных

```mermaid
erDiagram
    USERS {
        int id PK
        string email "UNIQUE"
        string password
    }

    COMPANIES {
        int id PK
        string name
        datetime created_at
    }

    EMPLOYEES {
        int id PK
        int company_id FK
        string email "UNIQUE"
        string name
        int position_id FK
        int department_id FK
        string status
        int user_id "FK (nullable)"
    }

    EMPLOYEE_MESSAGES {
        int id PK
        int sender_id FK
        int receiver_id FK
        string kind
        string status
    }

    DEPARTMENTS {
        int id PK
        int company_id FK
        string title
        int head_employee_id "FK -> employees.id"
    }

    POSITIONS {
        int id PK
        int company_id FK
        string title
        string modules "csv"
        string submodules "json"
        bool is_head
    }

    PRODUCT_CATEGORIES {
        int id PK
        int company_id FK
        string title
    }

    PRODUCTS {
        int id PK
        int company_id FK
        int category_id FK
        string title
        string price_stock_other
    }

    LEADS {
        int id PK
        int company_id FK
        string name_contact
        string status
        int product_id "FK (nullable)"
    }

    SALES_RECORDS {
        int id PK
        int company_id FK
        int product_id "FK (nullable)"
        string type_qty_amount
        string owner_ids "csv"
        datetime created_at
    }

    DOCUMENTS {
        int id PK
        int company_id FK
        int product_id "FK (nullable)"
        string type
        string title
        string note
        string owner_ids "csv"
        datetime created_at
    }

    PR_ASSETS {
        int id PK
        int company_id FK
        int product_id "FK (nullable)"
        string title
        string note
        datetime created_at
    }

    SMM_POSTS {
        int id PK
        int company_id FK
        int product_id "FK (nullable)"
        string channel
        string message
        string status
        datetime created_at
    }

    ACCOUNTING_ENTRIES {
        int id PK
        int company_id FK
        string target_type
        int target_id
        string delta
        string note
        datetime created_at
    }

    OPERATIONS {
        int id PK
        string type_amount_other
        string owner_ids "csv"
        datetime created_at
    }

    MODULES {
        string id PK "TEXT"
        string title
        string desc
        bool enabled
        int sort
    }

    %% ===== Relationships =====

    COMPANIES ||--|{ EMPLOYEES : employs
    USERS     ||--o| EMPLOYEES : "links (user_id nullable)"

    EMPLOYEES ||--|{ EMPLOYEE_MESSAGES : "sends (sender_id)"
    EMPLOYEES ||--|{ EMPLOYEE_MESSAGES : "receives (receiver_id)"

    COMPANIES ||--|{ DEPARTMENTS : has
    COMPANIES ||--|{ POSITIONS   : has

    DEPARTMENTS ||--o{ EMPLOYEES : contains
    POSITIONS   ||--o{ EMPLOYEES : assigned_to

    DEPARTMENTS }o--|| EMPLOYEES : "headed_by (head_employee_id)"

    COMPANIES ||--|{ PRODUCT_CATEGORIES : has
    PRODUCT_CATEGORIES ||--|{ PRODUCTS : categorizes
    COMPANIES ||--|{ PRODUCTS : owns

    COMPANIES ||--|{ LEADS : has
    PRODUCTS  ||--o{ LEADS : "optional (product_id)"

    COMPANIES ||--|{ SALES_RECORDS : has
    PRODUCTS  ||--o{ SALES_RECORDS : "optional (product_id)"

    COMPANIES ||--|{ DOCUMENTS : has
    PRODUCTS  ||--o{ DOCUMENTS : "optional (product_id)"

    COMPANIES ||--|{ PR_ASSETS : has
    PRODUCTS  ||--o{ PR_ASSETS : "optional (product_id)"

    COMPANIES ||--|{ SMM_POSTS : has
    PRODUCTS  ||--o{ SMM_POSTS : "optional (product_id)"

    COMPANIES ||--|{ ACCOUNTING_ENTRIES : has
