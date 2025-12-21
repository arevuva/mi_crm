Точка входа — инициализация платформы и запуск корневого виджета.
Алгоритм функции main()
Начало
    1. Инициализировать Flutter bindings (WidgetsFlutterBinding.ensureInitialized).
    2. Если приложение запущено НЕ в Web и платформа Linux или Windows:
        1. Инициализировать SQLite FFI (sqfliteFfiInit).
        2. Установить databaseFactory = databaseFactoryFfi.
    3. Запустить корневой виджет приложения: runApp(App()).
Конец

Собирает dependency injection (репозитории) и state management (Bloc/Cubit), возвращает MaterialApp.
Алгоритм функции App.build(BuildContext context)
Начало
    1. Создать экземпляры репозиториев:
        1. AuthRepository
        2. OperationRepository
        3. ModuleRepository
        4. CompanyRepository
        5. SalesRepository
        6. DocumentRepository
        7. PrRepository
        8. AccountingRepository
    2. Передать репозитории в DI-контейнер (MultiRepositoryProvider).
    3. Зарегистрировать state-менеджеры (MultiBlocProvider):
        1. AuthBloc и отправить событие AppStarted.
        2. OperationsBloc и отправить событие LoadOperations.
        3. ReportCubit и вызвать refresh.
        4. ModuleCubit и вызвать load.
        5. CompanyCubit и вызвать load.
        6. SalesCubit, DocumentCubit, PrCubit, AccountingCubit (без немедленной загрузки до выбора компании/экрана).
        7. ThemeCubit, TabCubit (локальное состояние UI).
    4. Построить MaterialApp:
        1. Применить темы (light/dark) и текущий ThemeMode из ThemeCubit.
        2. Установить home = _RootPage.
    5. Вернуть MaterialApp.
Конец

Выбирает стартовый экран по состоянию аутентификации (loading/auth/unauth).
Алгоритм функции _RootPage.build(BuildContext context)
Начало
    1. Получить состояние аутентификации из AuthBloc.
    2. Если состояние AuthLoading или AuthInitial:
        1. Показать экран загрузки (CircularProgressIndicator).
    3. Иначе если состояние Authenticated:
        1. Показать основной интерфейс вкладок (_MainTabs).
    4. Иначе если состояние Unauthenticated:
        1. Показать экран входа (LoginPage).
    5. Иначе:
        1. Показать пустой виджет (SizedBox.shrink).
Конец

Выполняет вход по email/паролю и обеспечивает привязку пользователя к сотруднику по email.
Алгоритм функции AuthRepository.login({required String email, required String password})
Начало
    1. Найти пользователя в таблице users по email.
    2. Если пользователь не найден:
        1. Сгенерировать ошибку "Пользователь не найден".
    3. Если пароль не совпадает:
        1. Сгенерировать ошибку "Неверный пароль".
    4. Найти сотрудника (employee) по email.
    5. Если сотрудник не найден:
        1. Сгенерировать ошибку "Email не зарегистрирован администратором".
    6. Если у сотрудника уже есть user_id и он не совпадает с найденным пользователем:
        1. Сгенерировать ошибку "Аккаунт для этой почты привязан к другому пользователю".
    7. Если user_id у сотрудника пустой:
        1. Привязать пользователя к сотруднику (attachUserToEmployee).
    8. Сохранить user_id в локальном кеше (SharedPreferences).
    9. Вернуть объект AppUser(id, email).
Конец

Открывает/создаёт SQLite БД и выполняет миграции до актуальной версии.
Алгоритм функции LocalDatabase._initDb()
Начало
    1. Получить директорию документов приложения.
    2. Сформировать путь к файлу БД (например, mi_crm.db).
    3. Открыть БД openDatabase(path) с version = 10.
    4. Если БД создаётся впервые (onCreate):
        1. Создать таблицы базового доступа:
            - users
            - operations
        2. Создать таблицу modules и заполнить дефолтными модулями (seed).
        3. Создать таблицы компании (companies, positions, departments, employees, и т.д.).
    5. Если выполняется обновление версии (onUpgrade):
        1. Для каждой версии N (если oldVersion < N):
            - создать новые таблицы/колонки, которых не было,
            - выполнить точечные миграции (например, добавить owner_ids, submodules, status/comment для задач).
    6. Вернуть объект Database.
Конец

Возвращает контент выбранного модуля HomePage (и его вкладок), учитывая права должности и ширину экрана.
Алгоритм функции HomePage._buildModuleContent(
    BuildContext viewContext,
    {required String? moduleId,
     required OperationsState operationsState,
     required SalesState salesState,
     required DocumentState docState,
     required PrState prState,
     required AccountingState accountingState,
     required CompanyState companyState,
     required Position position,
     required Employee currentEmployee}
)
Начало
    1. Определить параметры экрана (широкий/компактный) по ширине.
    2. Если moduleId == 'sales':
        1. Сформировать список вкладок:
            - sales ("Продажи")
            - intake ("Приёмка")
            - product_registration ("Регистрация товара")
            - leads ("Лиды и поставщики")
        2. Отфильтровать вкладки по правам должности (position.submodules['sales']).
        3. Если вкладок нет:
            - Показать уведомление "нет доступных подмодулей".
        4. Иначе:
            - Показать оболочку модуля (ModuleShell) с вкладками.
    3. Иначе если moduleId == 'docs':
        1. Сформировать вкладки:
            - operations ("Операции")
            - documents ("Документы")
        2. Отфильтровать вкладки по правам должности.
        3. Вернуть ModuleShell или уведомление.
    4. Иначе если moduleId == 'pr_smm':
        1. Сформировать вкладки: social, communications.
        2. Отфильтровать вкладки по правам должности.
        3. Вернуть ModuleShell или уведомление.
    5. Иначе если moduleId == 'finance':
        1. Сформировать вкладки: employee, expense.
        2. Отфильтровать вкладки по правам должности.
        3. Вернуть ModuleShell или уведомление.
    6. Иначе если moduleId == 'hr':
        1. Сформировать вкладку: employees.
        2. Отфильтровать вкладки по правам должности.
        3. Вернуть ModuleShell или уведомление.
    7. Иначе (обзор):
        1. Показать обзор модулей + снэпшот операций.
Конец

Пересчитывает ключевые показатели отчёта по списку операций (sale/purchase/expense).
Алгоритм функции ReportCubit.refresh()
Начало
    1. Установить state.isLoading = true и очистить state.error.
    2. Загрузить список операций через OperationRepository.loadOperations().
    3. Посчитать агрегаты:
        1. salesTotal = сумма операций типа sale
        2. purchaseTotal = сумма операций типа purchase
        3. expenseTotal = сумма операций типа expense
        4. operationsCount = количество операций
    4. Записать агрегаты в state и установить state.isLoading = false.
    5. Если при загрузке/подсчете произошла ошибка:
        1. Установить state.isLoading = false.
        2. Записать state.error = текст ошибки.
Конец

Загружает список задач для календаря (для сотрудника и, если он руководитель, для всего отдела).
Алгоритм функции _TasksCalendarSectionState._loadTasks()
Начало
    1. Установить флаг загрузки tasksLoading = true и очистить taskError.
    2. Определить должность текущего сотрудника.
        1. Если должностей нет:
            - Установить taskError и завершить.
    3. Собрать список получателей receiverIds:
        1. Всегда добавить текущего сотрудника.
        2. Если сотрудник является руководителем (position.isHead) и известен departmentId:
            - добавить всех сотрудников отдела в receiverIds.
    4. Запросить задачи через EmployeeCommunicationRepository.fetchTasksForReceivers(receiverIds).
    5. Сохранить список задач в состоянии виджета и, если день не выбран, установить выбранный день = сегодня.
    6. В конце установить tasksLoading = false.
    7. Если возникла ошибка:
        1. Записать taskError = текст ошибки.
        2. Установить tasksLoading = false.
Конец

---

Определяет “автовход”: проверяет кеш пользователя и устанавливает начальное состояние авторизации.
Алгоритм функции AuthBloc._onAppStarted(AppStarted event, Emitter<AuthState> emit)
Начало
    1. Установить состояние AuthLoading.
    2. Попробовать получить текущего пользователя через AuthRepository.getCurrentUser().
    3. Если пользователь найден:
        1. Установить состояние Authenticated(user).
    4. Иначе:
        1. Установить состояние Unauthenticated().
    5. Если произошла ошибка:
        1. Установить состояние Unauthenticated(message = текст ошибки).
Конец

Регистрирует пользователя, только если администратор уже завёл сотрудника с таким email, и связывает аккаунт с сотрудником.
Алгоритм функции AuthRepository.register({required String email, required String password})
Начало
    1. Найти сотрудника (employee) по email.
    2. Если сотрудник не найден:
        1. Сгенерировать ошибку "Email не зарегистрирован администратором".
    3. Если у сотрудника уже заполнен user_id:
        1. Сгенерировать ошибку "Для этой почты уже есть аккаунт".
    4. Создать запись пользователя в таблице users (insertUser).
    5. Привязать пользователя к сотруднику (attachUserToEmployee).
    6. Сохранить user_id в локальном кеше (SharedPreferences).
    7. Вернуть объект AppUser(id, email).
Конец

Добавляет операцию (продажа/приход/расход) и обновляет список операций в состоянии.
Алгоритм функции OperationsBloc._onAddOperationRequested(AddOperationRequested event, Emitter<OperationsState> emit)
Начало
    1. Установить state.isLoading = true и очистить state.error.
    2. Попробовать сохранить операцию через OperationRepository.addOperation(event.operation).
    3. Если сохранение успешно:
        1. Добавить сохранённую операцию в начало списка state.operations.
        2. Установить state.isLoading = false и обновить state.operations.
    4. Если произошла ошибка:
        1. Установить state.isLoading = false.
        2. Записать state.error = текст ошибки.
Конец

Переключает включенность CRM-модуля (enabled) и обновляет список модулей.
Алгоритм функции ModuleCubit.toggleModule(CRMModule module, bool enabled)
Начало
    1. Установить state.isLoading = true.
    2. Попробовать выполнить ModuleRepository.toggleModule(module, enabled).
    3. После успешного обновления:
        1. Перезагрузить список модулей (load).
    4. Если произошла ошибка:
        1. Установить state.isLoading = false.
        2. Записать state.error = текст ошибки.
Конец

Удаляет отдел, предварительно проверяя перенос сотрудников и ограничения на руководителей отделов.
Алгоритм функции CompanyCubit.deleteDepartment(int departmentId, {required Map<int, int> employeeReassignments})
Начало
    1. Если company отсутствует в state:
        1. Завершить выполнение.
    2. Собрать список employeesInDepartment = все сотрудники отдела departmentId.
    3. Если в отделе есть сотрудники:
        1. Проверить, что для каждого сотрудника задан новый отдел в employeeReassignments:
            - если нет → записать error "Укажите новый отдел для каждого сотрудника" и завершить.
        2. Для каждого сотрудника из employeesInDepartment:
            1. Проверить, что целевой отдел существует и не равен departmentId:
                - если целевой отдел невалиден → записать error и завершить.
            2. Если сотрудник является руководителем (position.isHead):
                - проверить, что в целевом отделе нет другого руководителя,
                - и что среди переносимых сотрудников не переносится второй руководитель в тот же целевой отдел,
                - иначе → записать error "В выбранном отделе уже есть руководитель" и завершить.
    4. Установить loading = true и очистить error.
    5. Попробовать выполнить перенос сотрудников:
        1. Для каждого сотрудника из employeesInDepartment:
            - обновить departmentId сотрудника на назначенный (CompanyRepository.updateEmployee).
    6. Удалить отдел (CompanyRepository.deleteDepartment).
    7. Перезагрузить departments и employees и записать в state, loading = false.
    8. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец

Добавляет сотрудника в компанию, проверяя правило “в отделе может быть только один руководитель”.
Алгоритм функции CompanyCubit.addEmployee({required String email, required String name, required int positionId, required int departmentId, required EmployeeStatus status})
Начало
    1. Если company отсутствует в state:
        1. Завершить выполнение.
    2. Найти должность position по positionId.
    3. Если position.isHead == true:
        1. Проверить, есть ли уже руководитель в departmentId:
            - если есть → записать error "В отделе уже есть Глава отдела..." и завершить.
    4. Установить loading = true и очистить error.
    5. Попробовать создать сотрудника через CompanyRepository.addEmployee(..., setAsHead = position.isHead).
    6. Перезагрузить employees и departments.
    7. Обновить state: loading = false, employees/departments = новые.
    8. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец

Загружает данные модуля “Продажи” для выбранной компании (категории, товары, лиды, записи).
Алгоритм функции SalesCubit.load(int companyId)
Начало
    1. Сохранить companyId во внутреннем поле (_companyId).
    2. Установить loading = true и очистить error.
    3. Попробовать загрузить данные из SalesRepository:
        1. categories = fetchCategories(companyId)
        2. products = fetchProducts(companyId)
        3. leads = fetchLeads(companyId)
        4. records = fetchSalesRecords(companyId)
    4. Записать данные в state и установить loading = false.
    5. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец

Создает запись продаж/прихода/поступления и затем обновляет список записей продаж в состоянии.
Алгоритм функции SalesCubit.addRecord({required SalesRecordType type, required int quantity, required double amount, String? note, int? productId, List<int> ownerIds = const []})
Начало
    1. Если _companyId не задан:
        1. Завершить выполнение.
    2. Установить loading = true и очистить error.
    3. Попробовать вызвать SalesRepository.addRecord(companyId = _companyId, type, quantity, amount, note, productId, ownerIds).
    4. После успешного добавления:
        1. Перезагрузить records = fetchSalesRecords(_companyId).
        2. Обновить state.records и установить loading = false.
    5. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец

Добавляет документ и обновляет список документов по компании.
Алгоритм функции DocumentCubit.addDocument({required DocumentType type, required String title, String? note, int? productId, List<int> ownerIds = const []})
Начало
    1. Если _companyId не задан:
        1. Завершить выполнение.
    2. Установить loading = true и очистить error.
    3. Попробовать вызвать DocumentRepository.addDocument(companyId = _companyId, type, title, note, productId, ownerIds).
    4. После успешного добавления:
        1. Перезагрузить documents = fetchDocuments(_companyId).
        2. Обновить state.documents и установить loading = false.
    5. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец

Добавляет финансовую проводку (дельту) и обновляет список проводок по компании.
Алгоритм функции AccountingCubit.addEntry({required String targetType, required int targetId, required double delta, required String note})
Начало
    1. Если _companyId не задан:
        1. Завершить выполнение.
    2. Установить loading = true и очистить error.
    3. Попробовать вызвать AccountingRepository.addEntry(companyId = _companyId, targetType, targetId, delta, note).
    4. После успешного добавления:
        1. Перезагрузить entries = fetchEntries(_companyId).
        2. Обновить state.entries и установить loading = false.
    5. Если произошла ошибка:
        1. Установить loading = false.
        2. Записать error = текст ошибки.
Конец
