class ModuleSubmodule {
  final String id;
  final String title;

  const ModuleSubmodule({required this.id, required this.title});
}

const Map<String, List<ModuleSubmodule>> moduleSubmodules = {
  'sales': [
    ModuleSubmodule(id: 'sales', title: 'Продажи'),
    ModuleSubmodule(id: 'intake', title: 'Приёмка'),
    ModuleSubmodule(id: 'product_registration', title: 'Регистрация товара'),
    ModuleSubmodule(id: 'leads', title: 'Лиды и поставщики'),
  ],
  'docs': [
    ModuleSubmodule(id: 'operations', title: 'Операции'),
    ModuleSubmodule(id: 'documents', title: 'Документы'),
  ],
  'pr_smm': [
    ModuleSubmodule(id: 'social', title: 'Соцсети'),
    ModuleSubmodule(id: 'communications', title: 'Коммуникации'),
  ],
  'finance': [
    ModuleSubmodule(id: 'employee', title: 'Персонал'),
    ModuleSubmodule(id: 'expense', title: 'Операционные расходы'),
  ],
  'hr': [
    ModuleSubmodule(id: 'employees', title: 'Сотрудники'),
  ],
};
