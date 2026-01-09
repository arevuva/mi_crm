# Архитектура mi_crm

## Текст для отчета (Word-ready)

### 1. Назначение системы
`mi_crm` — приложение класса CRM для ведения базовых процессов компании (продажи, документы, PR/SMM, HR, бухгалтерия) с упором на локальное хранение данных (offline-first). Доступ к функциональности определяется ролью сотрудника (должностью) и включенными администратором модулями.

### 2. Технологический стек
- Клиент: Flutter (Dart), UI на Material.
- Управление состоянием: `flutter_bloc` (Bloc/Cubit).
- Хранилище: SQLite через `sqflite` (на Linux/Windows — `sqflite_common_ffi`).
- Локальные настройки: `shared_preferences` (кеш `user_id`).

### 3. Архитектурный стиль
Проект организован по слоям:
1) Presentation (экраны/виджеты) — отображение данных и обработка пользовательских действий.  
2) State (Bloc/Cubit) — управление состоянием, оркестрация сценариев.  
3) Data (Repositories/Models/LocalDatabase) — доступ к данным и их хранение.

Ключевой принцип: UI не работает напрямую с SQLite; UI общается только со state-слоем, state-слой — с репозиториями, репозитории — с `LocalDatabase`.

## Краткий обзор
mi_crm — офлайн-first CRM на Flutter. Данные хранятся локально в SQLite (через `sqflite`/`sqflite_common_ffi`), UI управляется через Bloc/Cubit. Приложение строится вокруг модулей CRM, доступ к ним ограничивается должностями сотрудников.

```
                    +---------------------------+
                    |         Flutter UI        |
                    |  (screens/widgets/utils)  |
                    +---------------------------+
                      |        |        |
                      |        |        +------------------+
                      |        |                           |
                      v        v                           v
               +-----------+  +-----------+          +-----------+
               |  Auth UI  |  | HomePage  |          | ReportPage|
               | (Login/   |  | (Modules) |          | (Reports) |
               | Register) |  +-----------+          +-----------+
               +-----------+       |   |   \               |
                    |              |   |    \              |
                    v              |   |     \             v
             +--------------+      |   |      \     +--------------+
             |   AuthBloc   |      |   |       +--->|  ReportCubit |
             +--------------+      |   |             +--------------+
                    |              |   |
                    v              |   |
           +----------------+      |   |
           | AuthRepository |      |   |
           +----------------+      |   |
                    |              |   |
                    v              |   |
             +------------+        |   |
             | users      |        |   |
             +------------+        |   |
                                   |   |
  +---------------------------------------------------------------+
  |                 Остальные модули на главной                    |
  +---------------------------------------------------------------+
     |              |              |             |            |
     v              v              v             v            v
 +-----------+  +-----------+  +-----------+  +--------+  +-------------+
 |Operations |  |  Company  |  |  Modules  |  | Sales  |  | Documents   |
 |   Bloc    |  |   Cubit   |  |   Cubit   |  | Cubit  |  |   Cubit     |
 +-----------+  +-----------+  +-----------+  +--------+  +-------------+
     |              |              |             |            |
     v              v              v             v            v
 +----------------+ +----------------+ +----------------+ +-----------+ +------------------+
 |OperationRepo   | |CompanyRepo     | |ModuleRepo       | |SalesRepo  | |DocumentRepo      |
 +----------------+ +----------------+ +----------------+ +-----------+ +------------------+
     |              |    |    |       |             |            |
     v              v    v    v       v             v            v
 +------------+  +----------+ +----------+ +----------+      +-----------+
 |operations  |  |companies | |positions | |departments|     |documents  |
 +------------+  +----------+ +----------+ +----------+      +-----------+
                   |
                   v
              +-----------+
              | employees |
              +-----------+

  +------------------+    +--------------------------+    +-------------------+
  |     PR/SMM        |    | Employee communications  |    |    Accounting     |
  +------------------+    +--------------------------+    +-------------------+
  |     PrCubit       |    |  (Home/Report use)       |    |  AccountingCubit  |
  |     -> PrRepo     |    |  -> CommRepo             |    |  -> AccountingRepo|
  |     -> pr_assets  |    |  -> employee_messages    |    |  -> accounting_   |
  |     -> smm_posts  |    |                          |    |     entries       |
  +------------------+    +--------------------------+    +-------------------+

                   Все репозитории работают через:
                 +------------------------------+
                 |   LocalDatabase (SQLite)     |
                 |  schema + migrations + CRUD  |
                +------------------------------+
```

### 4. Компоненты приложения (кратко)
- `App` (`lib/app.dart`) — composition root: создание репозиториев и регистрация Bloc/Cubit.
- `Auth` — вход/регистрация и выбор стартового экрана.
- `Home` — рабочие модули и основные операции (фильтрация по правам сотрудника).
- `Report` — агрегированные показатели и отчеты (фильтрация по правам).
- `Admin` — конструктор CRM: компания, модули, отделы, должности, сотрудники.

### 5. Навигация
- При старте приложение выбирает UI-ветку по состоянию `AuthBloc` (не авторизован → Login, авторизован → вкладки).
- Основная часть приложения — 3 вкладки (Главная/Отчёт/Профиль), каждая со своим `Navigator` (независимый стек).

### 6. Потоки данных (типовой сценарий)
Пользовательское действие (например, создание документа) проходит путь:
`Screen` → `Cubit/Bloc` → `Repository` → `LocalDatabase` → обновление state → перерисовка UI.

```
UI (screens/widgets)
  -> Bloc/Cubit (state)
    -> Repository (data access)
      -> LocalDatabase (SQLite)
        -> Tables
```

## Точки входа и запуск
- `lib/main.dart` — инициализация Flutter, включение SQLite FFI для Linux/Windows, запуск `App`.
- `lib/app.dart` — DI для репозиториев и Bloc/Cubit, MaterialApp + тема, root-роутинг.

## Навигация
- Root-страница выбирается по состоянию `AuthBloc`:
  - AuthLoading/AuthInitial -> прогресс
  - Authenticated -> вкладки
  - Unauthenticated -> логин
- Вкладки (`_MainTabs`) используют `IndexedStack` с отдельным `Navigator` на вкладку.
  - Главная -> `HomePage`
  - Отчет -> `ReportPage`
  - Профиль -> `ProfilePage`
- Адаптивная оболочка — `ResponsiveScaffold`.

## Слои и ответственность
1. Presentation (`lib/presentation`)
   - Экраны: `home`, `report`, `profile`, `admin`, `auth`
   - Виджеты: `operation_card`, `responsive_scaffold`
   - Константы/утилиты: `module_submodules.dart`, `status_labels.dart`
2. State (`lib/blocs`)
   - Bloc/Cubit: управление состоянием и оркестрация use-case.
3. Data (`lib/data`)
   - Репозитории: абстракция доступа к данным.
   - Модели: DTO для SQLite и UI.
   - LocalDatabase: единая точка работы с SQLite.

## State management (Bloc/Cubit)
Связка "Bloc/Cubit -> Repository -> LocalDatabase":
- Auth: `AuthBloc` + `AuthRepository` (users, employee binding).
- Operations: `OperationsBloc` + `OperationRepository` (таблица `operations`).
- Report: `ReportCubit` + `OperationRepository` (агрегации операций).
- Modules: `ModuleCubit` + `ModuleRepository` (таблица `modules`).
- Company: `CompanyCubit` + `CompanyRepository` (company/positions/departments/employees).
- Sales: `SalesCubit` + `SalesRepository` (categories/products/leads/sales_records).
- Documents: `DocumentCubit` + `DocumentRepository` (documents).
- PR/SMM: `PrCubit` + `PrRepository` (pr_assets, smm_posts).
- Accounting: `AccountingCubit` + `AccountingRepository` (accounting_entries).
- Theme: `ThemeCubit` (local UI state).
- Tabs: `TabCubit` (local UI state).

## Data layer
### LocalDatabase
`lib/data/local/local_database.dart` — singleton, держит схему БД, миграции и CRUD.

Основные таблицы:
- users
- operations
- modules
- companies
- positions
- departments
- employees
- employee_messages
- product_categories
- products
- leads
- sales_records
- documents
- pr_assets
- smm_posts
- accounting_entries

### Репозитории и сущности
- Auth: `AppUser`, привязка к `Employee` через email.
- Company: `Company`, `Position`, `Department`, `Employee`.
- Sales: `ProductCategory`, `Product`, `Lead`, `SalesRecord`.
- Docs: `DocumentEntry`.
- PR/SMM: `PrAsset`, `SmmPost`.
- Accounting: `AccountingEntry`.
- Operations: `Operation`.
- Employee communications: `EmployeeMessage`.

## Модули CRM и доступ
Конфигурация модулей хранится в таблице `modules` и управляется в админке.
Базовые модули (`CRMModule.defaultModules`):
- sales (Продажи)
- docs (Документация)
- pr_smm (PR/SMM)
- hr (Управление персоналом)
- finance (Бухгалтерия)

Права доступа:
- `Position.modules` — список доступных модулей.
- `Position.submodules` — список доступных подмодулей (см. `module_submodules.dart`).
- Home/Report фильтруют доступные модули по должности сотрудника.

## Ключевые пользовательские потоки
1) Аутентификация
```
Login/Register UI -> AuthBloc -> AuthRepository
  -> LocalDatabase (users + employees)
  -> AuthState (Authenticated/Unauthenticated)
```

2) Загрузка модулей и прав доступа
```
HomePage -> CompanyCubit + ModuleCubit
  -> CompanyRepository/ModuleRepository
  -> LocalDatabase
  -> UI показывает только разрешенные модули
```

3) Операции и отчеты
```
Operation UI -> OperationsBloc -> OperationRepository -> LocalDatabase
ReportPage -> ReportCubit -> OperationRepository -> LocalDatabase
```

## Экран администратора
`AdminPage` управляет:
- созданием/переименованием компании,
- включением модулей,
- отделами, должностями и сотрудниками,
и напрямую влияет на доступность функциональности в `HomePage`/`ReportPage`.

## Точки расширения
- Добавить новый модуль CRM:
  1. Обновить `CRMModule.defaultModules`.
  2. Добавить подмодули в `module_submodules.dart` (если нужны).
  3. Добавить таблицы/репозитории/Bloc при необходимости.
  4. Отразить в UI Home/Report.
- Перенос с локальной БД на API:
  - Сохранить API контракт в репозиториях, заменить реализацию `LocalDatabase`.
