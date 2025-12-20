import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/accounting/accounting_cubit.dart';
import '../../../blocs/accounting/accounting_state.dart';
import '../../../blocs/company/company_cubit.dart';
import '../../../blocs/company/company_state.dart';
import '../../../blocs/document/document_cubit.dart';
import '../../../blocs/document/document_state.dart';
import '../../../blocs/modules/module_cubit.dart';
import '../../../blocs/modules/module_state.dart';
import '../../../blocs/operations/operations_bloc.dart';
import '../../../blocs/pr/pr_cubit.dart';
import '../../../blocs/pr/pr_state.dart';
import '../../../blocs/report/report_cubit.dart';
import '../../../blocs/sales/sales_cubit.dart';
import '../../../blocs/sales/sales_state.dart';
import '../../../data/models/document_entry.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/module.dart';
import '../../../data/models/operation.dart';
import '../../../data/models/product.dart';
import '../../../data/models/position.dart';
import '../../../data/models/sales_record.dart';
import '../../utils/status_labels.dart';
import '../../widgets/operation_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _categoryController = TextEditingController();
  final _productTitleController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productStockController = TextEditingController();
  final _recordQuantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _leadNameController = TextEditingController();
  final _leadContactController = TextEditingController();
  final _intakePhotoUrlController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _supplierContactController = TextEditingController();
  final _salesNoteController = TextEditingController();
  final _docTitleController = TextEditingController();
  final _docNoteController = TextEditingController();
  SalesRecordType _docOperationTypeFilter = SalesRecordType.sale;
  int? _selectedDocRecordId;
  final _assetTitleController = TextEditingController();
  final _assetNoteController = TextEditingController();
  final _postChannelController = TextEditingController(text: 'VK');
  final _postMessageController = TextEditingController();
  final _accountingDeltaController = TextEditingController();
  final _accountingNoteController = TextEditingController();
  final Set<int> _recordOwnerIds = {};
  final Set<int> _docOwnerIds = {};
  DocumentType _documentType = DocumentType.receipt;
  final Set<int> _expandedEmployeeIds = {};
  String _leadStatus = 'new';
  int? _selectedCategoryId;
  int? _selectedProductId;
  int? _selectedLeadProductId;
  int? _selectedSupplierProductId;
  int? _selectedSaleLeadId;
  int? _selectedIntakeSupplierId;
  int? _selectedDocProductId;
  int? _selectedPrProductId;
  int? _accountingTargetId;
  String _accountingTargetType = 'product';
  int? _loadedCompanyId;
  String? _activeModuleId;

  @override
  void dispose() {
    _categoryController.dispose();
    _productTitleController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _recordQuantityController.dispose();
    _unitPriceController.dispose();
    _totalPriceController.dispose();
    _leadNameController.dispose();
    _leadContactController.dispose();
    _intakePhotoUrlController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _salesNoteController.dispose();
    _docTitleController.dispose();
    _docNoteController.dispose();
    _assetTitleController.dispose();
    _assetNoteController.dispose();
    _postChannelController.dispose();
    _postMessageController.dispose();
    _accountingDeltaController.dispose();
    _accountingNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    return BlocBuilder<CompanyCubit, CompanyState>(
      builder: (context, companyState) {
        if (companyState.loading && companyState.company == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (companyState.company == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Создайте компанию в режиме администратора, чтобы начать работу со всеми модулями.'),
              ),
            ),
          );
        }

        final currentEmployee = _findEmployeeForUser(companyState, authState);
        if (currentEmployee == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Для входа в CRM администратор должен привязать ваш email к сотруднику.'),
              ),
            ),
          );
        }

        final position = companyState.positions.firstWhere(
          (p) => p.id == currentEmployee.positionId,
          orElse: () => companyState.positions.isNotEmpty
              ? companyState.positions.first
              : throw Exception('Нет доступных должностей'),
        );

        final allowedModules = position.modules.toSet();
        final moduleState = context.watch<ModuleCubit>().state;
        final salesState = context.watch<SalesCubit>().state;
        final docState = context.watch<DocumentCubit>().state;
        final prState = context.watch<PrCubit>().state;
        final accountingState = context.watch<AccountingCubit>().state;
        final operationsState = context.watch<OperationsBloc>().state;
        final screenWidth = MediaQuery.of(context).size.width;
        final useInlineModuleLayout = screenWidth >= 900;

        _ensureModuleData(companyState.company!.id);
        final enabledModules = moduleState.modules
            .where((m) => m.enabled)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final availableModules = enabledModules
            .where((m) => allowedModules.contains(m.id))
            .toList();

        if (useInlineModuleLayout) {
          if (_activeModuleId == null ||
              !availableModules.any((m) => m.id == _activeModuleId)) {
            _activeModuleId = availableModules.isNotEmpty ? availableModules.first.id : null;
          }
        } else {
          _activeModuleId = null;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Главная')),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Модули CRM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (availableModules.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Нет доступных модулей. Обратитесь к администратору или включите модули.'),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 12.0;
                            const minTileWidth = 240.0;
                            final columns = math.max(
                              1,
                              math.min(
                                availableModules.length,
                                (constraints.maxWidth / (minTileWidth + spacing)).floor(),
                              ),
                            );
                            final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: availableModules.asMap().entries.map((entry) {
                                final module = entry.value;
                                final accentColor = _moduleColorForIndex(entry.key);
                                return _ModuleCard(
                                  module: module,
                                  isSelected: useInlineModuleLayout && module.id == _activeModuleId,
                                  width: tileWidth,
                                  accentColor: accentColor,
                                  backgroundColor: accentColor.withOpacity(0.08),
                                  leadingIcon: _iconForModule(module.id),
                                  onTap: () {
                                    if (useInlineModuleLayout) {
                                      setState(() => _activeModuleId = module.id);
                                    } else {
                                      _openModulePage(
                                        moduleId: module.id,
                                        moduleTitle: module.title,
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_activeModuleId ?? 'overview'),
                  child: _buildModuleContent(
                    context,
                    moduleId: _activeModuleId,
                    operationsState: operationsState,
                    salesState: salesState,
                    docState: docState,
                    prState: prState,
                    accountingState: accountingState,
                    companyState: companyState,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Employee? _findEmployeeForUser(CompanyState companyState, AuthState authState) {
    if (authState is! Authenticated) return null;
    try {
      return companyState.employees.firstWhere(
        (e) => e.email.toLowerCase() == authState.user.email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _openModulePage({
    required String moduleId,
    required String moduleTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) {
          final operationsState = pageContext.watch<OperationsBloc>().state;
          final salesState = pageContext.watch<SalesCubit>().state;
          final docState = pageContext.watch<DocumentCubit>().state;
          final prState = pageContext.watch<PrCubit>().state;
          final accountingState = pageContext.watch<AccountingCubit>().state;
          final companyState = pageContext.watch<CompanyCubit>().state;
          return Scaffold(
            appBar: AppBar(title: Text(moduleTitle)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildModuleContent(
                pageContext,
                moduleId: moduleId,
                operationsState: operationsState,
                salesState: salesState,
                docState: docState,
                prState: prState,
                accountingState: accountingState,
                companyState: companyState,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleContent(
    BuildContext viewContext, {
    required String? moduleId,
    required OperationsState operationsState,
    required SalesState salesState,
    required DocumentState docState,
    required PrState prState,
    required AccountingState accountingState,
    required CompanyState companyState,
  }) {
    final screenWidth = MediaQuery.of(viewContext).size.width;
    final isWide = screenWidth > 900;
    final isCompact = screenWidth < 640;

    switch (moduleId) {
      case 'sales':
        return _ModuleShell(
          title: 'Товарооборот',
          tabs: [
            _ModuleTab(
              label: 'Продажи',
              icon: Icons.point_of_sale_outlined,
              child: _buildSalesOperations(salesState, companyState, isWide),
            ),
            _ModuleTab(
              label: 'Приёмка',
              icon: Icons.inventory_outlined,
              child: _buildSalesIntake(salesState, companyState, isWide),
            ),
            _ModuleTab(
              label: 'Регистрация товара',
              icon: Icons.playlist_add,
              child: _buildSalesRegistration(salesState, companyState, isWide, isCompact),
            ),
            _ModuleTab(
              label: 'Лиды и поставщики',
              icon: Icons.group_add_outlined,
              child: _buildLeadsAndSuppliers(salesState, companyState, isWide),
            ),
          ],
        );
      case 'docs':
        return _ModuleShell(
          title: 'Документация',
          tabs: [
            _ModuleTab(
              label: 'Операции',
              icon: Icons.swap_horiz,
              child: _buildDocsForOperations(docState, salesState, companyState),
            ),
            _ModuleTab(
              label: 'Документы',
              icon: Icons.description_outlined,
              child: _buildDocsCard(docState, companyState,
                  allowedTypes: const [DocumentType.act, DocumentType.contract]),
            ),
          ],
        );
      case 'pr_smm':
        return _ModuleShell(
          title: 'PR / SMM',
          tabs: [
            _ModuleTab(
              label: 'Соцсети',
              icon: Icons.share_outlined,
              child: _buildPrSocial(prState, companyState),
            ),
            _ModuleTab(
              label: 'Коммуникации',
              icon: Icons.chat_bubble_outline,
              child: _buildPrCommunication(prState, companyState),
            ),
          ],
        );
      case 'finance':
        return _ModuleShell(
          title: 'Бухгалтерия',
          tabs: [
            _ModuleTab(
              label: 'Персонал',
              icon: Icons.people_outline,
              child: _buildAccountingCard(accountingState, companyState, targetType: 'employee'),
            ),
            _ModuleTab(
              label: 'Операционные расходы',
              icon: Icons.receipt_long_outlined,
              child: _buildAccountingCard(accountingState, companyState, targetType: 'expense'),
            ),
          ],
        );
      case 'hr':
        return _ModuleShell(
          title: 'Управление персоналом',
          tabs: [
            _ModuleTab(
              label: 'Сотрудники',
              icon: Icons.badge_outlined,
              child: _buildHrCard(companyState),
            ),
          ],
        );
      default:
        return _buildOverviewTab(operationsState);
    }
  }

  Widget _buildOverviewTab(OperationsState operationsState) {
    return ListView(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(8),
      children: [
        const _ModulesOverview(),
        const SizedBox(height: 12),
        _buildOperationsSnapshot(context, operationsState),
      ],
    );
  }

  Widget _moduleGuard({
    required String moduleId,
    required String label,
    required Set<String> enabledModules,
    required Set<String> allowedModules,
    required Widget child,
  }) {
    if (!enabledModules.contains(moduleId)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Модуль "$label" отключён администратором.'),
        ),
      );
    }
    if (!allowedModules.contains(moduleId)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Для вашей должности нет доступа к модулю "$label".'),
        ),
      );
    }
    return child;
  }

  void _ensureModuleData(int companyId) {
    if (_loadedCompanyId == companyId) return;
    _loadedCompanyId = companyId;
    context.read<SalesCubit>().load(companyId);
    context.read<DocumentCubit>().load(companyId);
    context.read<PrCubit>().load(companyId);
    context.read<AccountingCubit>().load(companyId);
  }

  Widget _buildSalesRegistration(
    SalesState state,
    CompanyState companyState,
    bool isWide,
    bool isCompact,
  ) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Регистрация товара',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<SalesCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Категории', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: isCompact ? 8 : 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Новая категория',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        onSubmitted: (_) => _createCategory(context),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.loading ? null : () => _createCategory(context),
                      icon: const Icon(Icons.add),
                      label: state.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Добавить категорию'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Регистрация товара', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (state.categories.isEmpty)
                  const Text('Нет категорий. Сначала добавьте категорию.')
                else
                  Wrap(
                    spacing: isCompact ? 8 : 12,
                    runSpacing: 12,
                    children: [
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Категория для товара',
                          prefixIcon: Icon(Icons.category),
                        ),
                          items: state.categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.title)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                        ),
                      ),
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: TextField(
                        controller: _productTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Название товара',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        ),
                      ),
                    SizedBox(
                      width: isWide ? 160 : double.infinity,
                      child: TextField(
                        controller: _productPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Цена',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 160 : double.infinity,
                      child: TextField(
                        controller: _productStockController,
                        decoration: const InputDecoration(
                          labelText: 'Количество на складе',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                      ElevatedButton.icon(
                        onPressed: state.loading ? null : () => _createProduct(context),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: state.loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Сохранить товар'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadsAndSuppliers(
    SalesState state,
    CompanyState companyState,
    bool isWide,
  ) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Лиды и поставщики',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<SalesCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Лиды', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _leadNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя лида',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _leadContactController,
                        decoration: const InputDecoration(
                          labelText: 'Контакты',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 180 : double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _leadStatus,
                        decoration: const InputDecoration(
                          labelText: 'Статус',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'new', child: Text('Новый')),
                          DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
                          DropdownMenuItem(value: 'won', child: Text('Успешно')),
                          DropdownMenuItem(value: 'lost', child: Text('Закрыт')),
                        ],
                        onChanged: (value) => setState(() => _leadStatus = value ?? 'new'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedLeadProductId,
                        decoration: const InputDecoration(
                          labelText: 'Интерес к товару',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        items: state.products
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedLeadProductId = value),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: state.loading ? null : () => _createLead(context),
                      child: state.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Добавить лида'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Поставщики', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _supplierNameController,
                        decoration: const InputDecoration(
                          labelText: 'Название поставщика',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _supplierContactController,
                        decoration: const InputDecoration(
                          labelText: 'Контакты',
                          prefixIcon: Icon(Icons.contact_mail_outlined),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 220 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedSupplierProductId,
                        decoration: const InputDecoration(
                          labelText: 'Поставляет товар',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: state.products
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedSupplierProductId = value),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: state.loading ? null : () => _createSupplier(context),
                      child: state.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Добавить поставщика'),
                    ),
                  ],
                ),
                if (state.leads.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Последние лиды и поставщики', style: Theme.of(context).textTheme.titleSmall),
                  ...state.leads.take(6).map(
                        (l) => ListTile(
                          leading: Icon(
                            l.status == 'supplier' ? Icons.local_shipping_outlined : Icons.person_outline,
                          ),
                          title: Text(l.name),
                          subtitle: Text(l.contact),
                          trailing: Text(l.status),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesOperations(
    SalesState state,
    CompanyState companyState,
    bool isWide,
  ) {
    final leads = state.leads.where((l) => l.status != 'supplier').toList();
    final saleRecords = state.records.where((r) => r.type == SalesRecordType.sale).toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Фиксация продаж и поступлений',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<SalesCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.sell_outlined),
                    label: const Text('Тип операции: Продажа'),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 360 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Товар для операции',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: state.products
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.title} — ${p.price.toStringAsFixed(0)}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                            if (value != null) {
                              final product = state.products.firstWhere((p) => p.id == value);
                              _unitPriceController.text = product.price.toStringAsFixed(2);
                              _updateSalesTotals();
                            }
                          });
                        },
                      ),
                    ),
                    if (_selectedProductId != null) ...[
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                      child: DropdownButtonFormField<int?>(
                        value: _selectedSaleLeadId,
                        decoration: const InputDecoration(
                          labelText: 'Лид (необязательно)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Без лида'),
                            ),
                            ...leads.map(
                              (l) => DropdownMenuItem<int?>(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _selectedSaleLeadId = value),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCreateLeadDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Создать нового лида'),
                      ),
                      SizedBox(
                        width: isWide ? 140 : double.infinity,
                      child: TextField(
                        controller: _recordQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Кол-во',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                          onChanged: (_) => setState(_updateSalesTotals),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _unitPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Цена за единицу',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                onChanged: (_) => setState(_updateSalesTotals),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _totalPriceController,
                                readOnly: true,
                                enableInteractiveSelection: false,
                                decoration: const InputDecoration(
                                  labelText: 'Итог за выбранное кол-во',
                                  prefixIcon: Icon(Icons.calculate_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                      child: TextField(
                        controller: _salesNoteController,
                        decoration: const InputDecoration(
                          labelText: 'Комментарий',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        maxLines: 2,
                      ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: TextField(
                          controller: _intakePhotoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Ссылка на фото (опционально)',
                            prefixIcon: Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_selectedProductId != null) ...[
                  const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: state.loading ? null : _resetSalesForm,
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить ещё товар'),
                          ),
                          ElevatedButton.icon(
                        onPressed: state.loading
                            ? null
                            : () => _submitSalesRecord(context, recordType: SalesRecordType.sale),
                        icon: const Icon(Icons.save_outlined),
                        label: state.loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Зафиксировать операцию'),
                      ),
                    ],
                  ),
                ],
                if (saleRecords.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Последние операции', style: Theme.of(context).textTheme.titleSmall),
                  ...saleRecords.take(5).map(
                        (r) => ListTile(
                          leading: Icon(_iconForRecord(r.type)),
                          title: Text('${r.type.name} — ${r.amount.toStringAsFixed(2)}'),
                          subtitle: Text(r.note ?? ''),
                          trailing: Text(DateFormat('dd.MM HH:mm').format(r.createdAt)),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesIntake(
    SalesState state,
    CompanyState companyState,
    bool isWide,
  ) {
    final suppliers = state.leads.where((l) => l.status == 'supplier').toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Приёмка и поступления',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<SalesCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.inventory_outlined),
                    label: const Text('Тип операции: Поступление'),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 360 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Товар для поступления',
                          prefixIcon: Icon(Icons.inventory_outlined),
                        ),
                        items: state.products
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.title} — ${p.price.toStringAsFixed(0)}'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                            if (value != null) {
                              final product = state.products.firstWhere((p) => p.id == value);
                              _unitPriceController.text = product.price.toStringAsFixed(2);
                              _updateSalesTotals();
                            }
                          });
                        },
                      ),
                    ),
                    if (_selectedProductId != null) ...[
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: DropdownButtonFormField<int?>(
                        value: _selectedIntakeSupplierId,
                        decoration: const InputDecoration(
                          labelText: 'Поставщик (необязательно)',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Без поставщика'),
                            ),
                            ...suppliers.map(
                              (l) => DropdownMenuItem<int?>(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _selectedIntakeSupplierId = value),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCreateSupplierDialog(context),
                        icon: const Icon(Icons.add_business),
                        label: const Text('Создать поставщика'),
                      ),
                    SizedBox(
                      width: isWide ? 140 : double.infinity,
                      child: TextField(
                        controller: _recordQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Кол-во',
                          prefixIcon: Icon(Icons.confirmation_number_outlined),
                        ),
                        onChanged: (_) => setState(_updateSalesTotals),
                      ),
                    ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _unitPriceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Цена закупки',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                onChanged: (_) => setState(_updateSalesTotals),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _totalPriceController,
                                readOnly: true,
                                enableInteractiveSelection: false,
                                decoration: const InputDecoration(
                                  labelText: 'Итог за выбранное кол-во',
                                  prefixIcon: Icon(Icons.calculate_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: TextField(
                          controller: _salesNoteController,
                          decoration: const InputDecoration(
                            labelText: 'Комментарий',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: TextField(
                          controller: _intakePhotoUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Ссылка на фото (опционально)',
                            prefixIcon: Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_selectedProductId != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.loading ? null : _resetSalesForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить ещё товар'),
                      ),
                      ElevatedButton.icon(
                        onPressed: state.loading
                            ? null
                            : () => _submitSalesRecord(context, recordType: SalesRecordType.income),
                        icon: const Icon(Icons.archive_outlined),
                        label: state.loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Зарегистрировать поступление'),
                      ),
                    ],
                  ),
                ],
                if (state.records.where((r) => r.type == SalesRecordType.income).isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Последние поступления', style: Theme.of(context).textTheme.titleSmall),
                  ...state.records
                      .where((r) => r.type == SalesRecordType.income)
                      .take(5)
                      .map(
                        (r) => ListTile(
                          leading: Icon(_iconForRecord(r.type)),
                          title: Text('${r.type.name} — ${r.amount.toStringAsFixed(2)}'),
                          subtitle: Text(r.note ?? ''),
                          trailing: Text(DateFormat('dd.MM HH:mm').format(r.createdAt)),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocsCard(DocumentState state, CompanyState companyState,
      {required List<DocumentType> allowedTypes}) {
    final filteredDocs = state.documents.where((d) => allowedTypes.contains(d.type)).toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      allowedTypes.contains(DocumentType.receipt)
                          ? 'Контроль товарооборота'
                          : 'Договоры и акты',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: () => context.read<DocumentCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DocumentType>(
                  value: allowedTypes.contains(_documentType) ? _documentType : allowedTypes.first,
                  decoration: const InputDecoration(
                    labelText: 'Тип документа',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  items: allowedTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(_docTitle(type))))
                      .toList(),
                  onChanged: (value) => setState(() => _documentType = value ?? allowedTypes.first),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _docTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Название / номер документа',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedDocProductId,
                  decoration: const InputDecoration(
                    labelText: 'Связанный товар (необязательно)',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: context
                      .read<SalesCubit>()
                      .state
                      .products
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedDocProductId = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _docNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                if (companyState.employees.isNotEmpty) ...[
                  Text('Участники', style: Theme.of(context).textTheme.titleSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: companyState.employees
                        .map(
                          (e) => FilterChip(
                            label: Text(e.name),
                            selected: _docOwnerIds.contains(e.id),
                            onSelected: (value) => setState(() {
                              if (value) {
                                _docOwnerIds.add(e.id);
                              } else {
                                _docOwnerIds.remove(e.id);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: state.loading ? null : () => _createDocument(context),
                  icon: const Icon(Icons.file_copy_outlined),
                  label: state.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Сохранить запись'),
                ),
                if (filteredDocs.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...filteredDocs.take(5).map(
                        (d) => ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text('${_docTitle(d.type)} — ${d.title}'),
                          subtitle: Text(d.note ?? ''),
                          trailing: Text(DateFormat('dd.MM').format(d.createdAt)),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocsForOperations(
    DocumentState docState,
    SalesState salesState,
    CompanyState companyState,
  ) {
    final records = salesState.records
        .where((r) => r.type == _docOperationTypeFilter)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filteredDocs = docState.documents
        .where((d) => d.type == DocumentType.receipt || d.type == DocumentType.consumable)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Документы по операциям',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () {
                        context.read<DocumentCubit>().load(companyState.company!.id);
                        context.read<SalesCubit>().load(companyState.company!.id);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<SalesRecordType>(
                        value: _docOperationTypeFilter,
                        decoration: const InputDecoration(
                          labelText: 'Тип операции',
                          prefixIcon: Icon(Icons.swap_horiz),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: SalesRecordType.sale,
                            child: Text('Продажа'),
                          ),
                          DropdownMenuItem(
                            value: SalesRecordType.income,
                            child: Text('Поступление'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _docOperationTypeFilter = value;
                            _selectedDocRecordId = null;
                            _selectedDocProductId = null;
                            _documentType = value == SalesRecordType.income
                                ? DocumentType.receipt
                                : DocumentType.consumable;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int>(
                        value: _selectedDocRecordId,
                        decoration: InputDecoration(
                          labelText: records.isEmpty
                              ? 'Нет операций'
                              : 'Операция (${records.length})',
                          prefixIcon: const Icon(Icons.history),
                        ),
                        items: records
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(
                                    '#${r.id} • ${r.type.name} • ${r.amount.toStringAsFixed(0)} • ${DateFormat('dd.MM').format(r.createdAt)}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDocRecordId = value;
                          });
                          if (value != null) {
                            final record = records.firstWhere((r) => r.id == value);
                            _prefillDocumentFromRecord(record);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<DocumentType>(
                        value: _documentType,
                        decoration: const InputDecoration(
                          labelText: 'Тип документа',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DocumentType.receipt,
                            child: Text('Накладная/приход'),
                          ),
                          DropdownMenuItem(
                            value: DocumentType.consumable,
                            child: Text('Расходный документ'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _documentType = value ?? _documentType;
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _docTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Название / номер документа',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<int>(
                        value: _selectedDocProductId,
                        decoration: const InputDecoration(
                          labelText: 'Связанный товар',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        items: salesState.products
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedDocProductId = value),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _docNoteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Комментарий',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: docState.loading || records.isEmpty ? null : () => _createDocument(context),
                      icon: const Icon(Icons.file_copy_outlined),
                      label: docState.loading
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Оформить документ'),
                    ),
                  ],
                ),
                if (filteredDocs.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Последние документы по операциям',
                      style: Theme.of(context).textTheme.titleSmall),
                  ...filteredDocs.take(5).map(
                        (d) => ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text('${_docTitle(d.type)} — ${d.title}'),
                          subtitle: Text(d.note ?? ''),
                          trailing: Text(DateFormat('dd.MM').format(d.createdAt)),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrSocial(PrState state, CompanyState companyState) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ведение соцсетей',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<PrCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _postChannelController,
                  decoration: const InputDecoration(labelText: 'Канал публикации'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _postMessageController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Пост (заглушка контента)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: state.loading ? null : () => _createSmmPost(context),
                  icon: const Icon(Icons.send_outlined),
                  label: state.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Запланировать пост'),
                ),
                if (state.posts.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...state.posts.take(3).map(
                        (p) => ListTile(
                          leading: const Icon(Icons.campaign_outlined),
                          title: Text('${p.channel}: ${p.message}'),
                          subtitle: Text('Статус: ${p.status}'),
                          trailing: Text(DateFormat('dd.MM').format(p.createdAt)),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrCommunication(PrState state, CompanyState companyState) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Коммуникации с клиентами',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<PrCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _assetTitleController,
                  decoration: const InputDecoration(labelText: 'Документация к товару'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedPrProductId,
                  decoration: const InputDecoration(labelText: 'Товар (опционально)'),
                  items: context
                      .read<SalesCubit>()
                      .state
                      .products
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPrProductId = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _assetNoteController,
                  decoration: const InputDecoration(labelText: 'Пояснение'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: state.loading ? null : () => _createPrAsset(context),
                  child: state.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Добавить документ'),
                ),
                if (state.assets.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...state.assets.take(3).map(
                        (a) => ListTile(
                          leading: const Icon(Icons.folder_shared_outlined),
                          title: Text(a.title),
                          subtitle: Text(a.note ?? ''),
                          trailing: a.productId != null
                              ? Text('Товар: ${a.productId}')
                              : const SizedBox.shrink(),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHrCard(CompanyState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Управление персоналом', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (state.employees.isEmpty)
              const Text('Нет сотрудников. Добавьте их в режиме администратора.')
            else
              ...state.employees.map(
                (e) {
                  final position = state.positions.firstWhere((p) => p.id == e.positionId);
                  final isExpanded = _expandedEmployeeIds.contains(e.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () => _toggleEmployeeExpanded(e.id),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.person_outline),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                                        Text(position.title,
                                            style: Theme.of(context).textTheme.bodySmall),
                                        Text('Статус: ${statusLabel(e.status)}',
                                            style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 10),
                                Text('Почта: ${e.email}', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openChatWithEmployee(e),
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Написать'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.task_alt),
                                      label: const Text('Поручить'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountingCard(
    AccountingState state,
    CompanyState companyState, {
    required String targetType,
  }) {
    _accountingTargetType = targetType;
    final salesState = context.read<SalesCubit>().state;
    final isExpense = targetType == 'expense';
    _accountingTargetId ??= isExpense ? companyState.company?.id : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Бухгалтерия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (!isExpense)
              DropdownButtonFormField<int>(
                value: _accountingTargetId,
                decoration: InputDecoration(
                    labelText: _accountingTargetType == 'product' ? 'Товар' : 'Сотрудник'),
                items: (_accountingTargetType == 'product' ? salesState.products : companyState.employees)
                    .map(
                      (item) => DropdownMenuItem(
                        value: _accountingTargetType == 'product' ? (item as Product).id : (item as Employee).id,
                        child: Text(_accountingTargetType == 'product'
                            ? (item as Product).title
                            : (item as Employee).name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _accountingTargetId = value),
              )
            else
              const Text('Операционные расходы будут зафиксированы на компанию.'),
            const SizedBox(height: 8),
            TextField(
              controller: _accountingDeltaController,
              decoration: InputDecoration(
                labelText: isExpense
                    ? 'Сумма операционного расхода'
                    : (_accountingTargetType == 'product' ? 'Новая цена/дельта' : 'Корректировка зп'),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountingNoteController,
              decoration: const InputDecoration(labelText: 'Комментарий'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: state.loading ? null : () => _createAccountingEntry(context),
              icon: const Icon(Icons.calculate_outlined),
              label: state.loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Зафиксировать изменение'),
            ),
            if (state.entries.isNotEmpty) ...[
              const Divider(height: 24),
              ...state.entries.take(3).map(
                    (e) => ListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text('${e.targetType}: ${e.delta}'),
                      subtitle: Text(e.note),
                      trailing: Text(DateFormat('dd.MM').format(e.createdAt)),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsSnapshot(BuildContext context, OperationsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Финансовые движения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    context.read<OperationsBloc>().add(LoadOperations());
                    context.read<ReportCubit>().refresh();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.operations.isEmpty)
              const Text('Нет записей. Добавьте операции на вкладке Продажи или вручную.')
            else
              ...state.operations.take(5).map(
                    (op) => OperationCard(
                      title: _titleForType(op.type),
                      subtitle: op.description,
                      amount: op.amount,
                      timestamp: DateFormat('dd MMM yyyy, HH:mm').format(op.createdAt),
                      color: _colorForType(op.type),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Color _moduleColorForIndex(int index) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.redAccent,
      Colors.indigo,
    ];
    return palette[index % palette.length];
  }

  IconData _iconForModule(String moduleId) {
    switch (moduleId) {
      case 'sales':
        return Icons.point_of_sale_outlined;
      case 'docs':
        return Icons.description_outlined;
      case 'pr_smm':
        return Icons.campaign_outlined;
      case 'finance':
        return Icons.receipt_long_outlined;
      case 'hr':
        return Icons.badge_outlined;
      default:
        return Icons.apps_outlined;
    }
  }

  String _docTitle(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return 'Приход товара';
      case DocumentType.act:
        return 'Акт';
      case DocumentType.consumable:
        return 'Расходник';
      case DocumentType.contract:
        return 'Договор';
    }
  }

  IconData _iconForRecord(SalesRecordType type) {
    switch (type) {
      case SalesRecordType.sale:
        return Icons.shopping_cart_checkout_outlined;
      case SalesRecordType.income:
        return Icons.attach_money;
      case SalesRecordType.reservation:
        return Icons.bookmark_add_outlined;
    }
  }

  Future<void> _createCategory(BuildContext context) async {
    final title = _categoryController.text.trim();
    if (title.isEmpty) return;
    await context.read<SalesCubit>().addCategory(title);
    _categoryController.clear();
  }

  Future<void> _createProduct(BuildContext context) async {
    if (_selectedCategoryId == null) return;
    final name = _productTitleController.text.trim();
    final price = double.tryParse(_productPriceController.text) ?? 0;
    final stock = int.tryParse(_productStockController.text) ?? 0;
    if (name.isEmpty || price <= 0) return;
    await context.read<SalesCubit>().addProduct(
          categoryId: _selectedCategoryId!,
          title: name,
          price: price,
          stock: stock,
        );
    _productTitleController.clear();
    _productPriceController.clear();
    _productStockController.clear();
  }

  Future<void> _submitSalesRecord(
    BuildContext context, {
    required SalesRecordType recordType,
  }) async {
    final quantity = int.tryParse(_recordQuantityController.text) ?? 0;
    final unitAmount = double.tryParse(_unitPriceController.text) ?? 0;
    if (quantity <= 0 || unitAmount <= 0 || _selectedProductId == null) return;
    final amount = unitAmount * quantity;
    final companyState = context.read<CompanyCubit>().state;
    final authState = context.read<AuthBloc>().state;
    final currentEmployee = companyState.company == null
        ? null
        : _findEmployeeForUser(companyState, authState);
    final noteParts = <String>[];
    if (recordType == SalesRecordType.sale && _selectedSaleLeadId != null) {
      noteParts.add('Лид: $_selectedSaleLeadId');
    }
    if (recordType == SalesRecordType.income && _selectedIntakeSupplierId != null) {
      noteParts.add('Поставщик: $_selectedIntakeSupplierId');
    }
    if (recordType == SalesRecordType.income) {
      final photo = _intakePhotoUrlController.text.trim();
      if (photo.isNotEmpty) {
        noteParts.add('Фото: $photo');
      }
    }
    final userNote = _salesNoteController.text.trim();
    if (userNote.isNotEmpty) noteParts.add(userNote);
    final combinedNote = noteParts.isNotEmpty ? noteParts.join(' | ') : null;
    final ownerIds = _recordOwnerIds.isNotEmpty
        ? _recordOwnerIds.toList()
        : currentEmployee != null
            ? [currentEmployee.id]
            : <int>[];

    await context.read<SalesCubit>().addRecord(
          type: recordType,
          quantity: quantity,
          amount: amount,
          note: combinedNote,
          productId: _selectedProductId,
          ownerIds: ownerIds,
        );

    // Пробрасываем запись в фин. учёт
    final operation = Operation(
      type: recordType == SalesRecordType.sale ? OperationType.sale : OperationType.purchase,
      amount: amount,
      description:
          'Модуль продаж: ${recordType.name}${_selectedProductId != null ? ' по товару $_selectedProductId' : ''}',
      ownerIds: ownerIds,
      createdAt: DateTime.now(),
    );
    context.read<OperationsBloc>().add(AddOperationRequested(operation));
    context.read<ReportCubit>().refresh();

    setState(() {
      _recordQuantityController.text = '1';
      _unitPriceController.clear();
      _totalPriceController.clear();
      _selectedProductId = null;
      _selectedSaleLeadId = null;
      _selectedIntakeSupplierId = null;
      _salesNoteController.clear();
      _intakePhotoUrlController.clear();
      _recordOwnerIds.clear();
    });
  }

  void _prefillDocumentFromRecord(SalesRecord record) {
    _documentType =
        record.type == SalesRecordType.income ? DocumentType.receipt : DocumentType.consumable;
    _selectedDocProductId = record.productId;
    _selectedDocRecordId = record.id;
    if (_docTitleController.text.isEmpty) {
      _docTitleController.text = 'Документ по ${record.type.name} #${record.id}';
    }
    if (_docNoteController.text.isEmpty && record.note?.isNotEmpty == true) {
      _docNoteController.text = record.note!;
    }
    setState(() {});
  }

  void _updateSalesTotals() {
    final quantity = int.tryParse(_recordQuantityController.text) ?? 0;
    final unit = double.tryParse(_unitPriceController.text) ?? 0;
    final total = quantity > 0 && unit > 0 ? quantity * unit : 0;
    if (total > 0) {
      _totalPriceController.text = total.toStringAsFixed(2);
    } else {
      _totalPriceController.clear();
    }
  }

  void _resetSalesForm() {
    setState(() {
      _selectedProductId = null;
      _selectedLeadProductId = null;
      _selectedSupplierProductId = null;
      _selectedSaleLeadId = null;
      _selectedIntakeSupplierId = null;
      _recordQuantityController.text = '1';
      _unitPriceController.clear();
      _totalPriceController.clear();
      _salesNoteController.clear();
    });
  }

  Future<void> _createLead(BuildContext context) async {
    final name = _leadNameController.text.trim();
    if (name.isEmpty) return;
    await context.read<SalesCubit>().addLead(
          name: name,
          contact: _leadContactController.text.trim(),
          status: _leadStatus,
          productId: _selectedLeadProductId,
        );
    setState(() {
      _leadNameController.clear();
      _leadContactController.clear();
      _selectedLeadProductId = null;
    });
  }

  Future<void> _createSupplier(BuildContext context) async {
    final name = _supplierNameController.text.trim();
    if (name.isEmpty) return;
    await context.read<SalesCubit>().addLead(
          name: name,
          contact: _supplierContactController.text.trim(),
          status: 'supplier',
          productId: _selectedSupplierProductId,
        );
    setState(() {
      _supplierNameController.clear();
      _supplierContactController.clear();
      _selectedSupplierProductId = null;
    });
  }

  Future<void> _showCreateLeadDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новый лид'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Контакт'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await context.read<SalesCubit>().addLead(
                    name: name,
                    contact: contactController.text.trim(),
                    status: 'new',
                    productId: null,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    nameController.dispose();
    contactController.dispose();
  }

  Future<void> _showCreateSupplierDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новый поставщик'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Контакты'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await context.read<SalesCubit>().addLead(
                    name: name,
                    contact: contactController.text.trim(),
                    status: 'supplier',
                    productId: null,
                  );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    nameController.dispose();
    contactController.dispose();
  }

  Future<void> _createDocument(BuildContext context) async {
    final title = _docTitleController.text.trim();
    if (title.isEmpty) return;
    SalesRecord? linkedRecord;
    if (_selectedDocRecordId != null) {
      try {
        linkedRecord =
            context.read<SalesCubit>().state.records.firstWhere((r) => r.id == _selectedDocRecordId);
      } catch (_) {}
    }
    final noteParts = <String>[];
    if (linkedRecord != null) {
      noteParts.add('Операция #${linkedRecord.id} (${linkedRecord.type.name})');
    }
    final userNote = _docNoteController.text.trim();
    if (userNote.isNotEmpty) noteParts.add(userNote);
    final combinedNote = noteParts.isNotEmpty ? noteParts.join(' | ') : null;
    final productId = _selectedDocProductId ?? linkedRecord?.productId;

    await context.read<DocumentCubit>().addDocument(
          type: _documentType,
          title: title,
          note: combinedNote,
          productId: productId,
          ownerIds: _docOwnerIds.toList(),
        );
    _docTitleController.clear();
    _docNoteController.clear();
    _selectedDocRecordId = null;
    _selectedDocProductId = null;
    _docOwnerIds.clear();
  }

  Future<void> _createPrAsset(BuildContext context) async {
    final title = _assetTitleController.text.trim();
    if (title.isEmpty) return;
    await context.read<PrCubit>().addAsset(
          title: title,
          note: _assetNoteController.text,
          productId: _selectedPrProductId,
        );
    _assetTitleController.clear();
    _assetNoteController.clear();
  }

  Future<void> _createSmmPost(BuildContext context) async {
    final message = _postMessageController.text.trim();
    if (message.isEmpty) return;
    await context.read<PrCubit>().addPost(
          channel: _postChannelController.text.trim().isEmpty ? 'social' : _postChannelController.text.trim(),
          message: message,
          productId: _selectedPrProductId,
        );
    _postMessageController.clear();
  }

  Future<void> _createAccountingEntry(BuildContext context) async {
    if (_accountingTargetId == null) return;
    final delta = double.tryParse(_accountingDeltaController.text) ?? 0;
    if (delta == 0) return;

    await context.read<AccountingCubit>().addEntry(
          targetType: _accountingTargetType,
          targetId: _accountingTargetId!,
          delta: delta,
          note: _accountingNoteController.text.trim().isEmpty
              ? 'Корректировка'
              : _accountingNoteController.text.trim(),
        );

    if (_accountingTargetType == 'product') {
      await context.read<SalesCubit>().updatePrice(_accountingTargetId!, delta);
    }

    _accountingDeltaController.clear();
    _accountingNoteController.clear();
  }

  String _titleForType(OperationType type) {
    switch (type) {
      case OperationType.sale:
        return 'Продажа';
      case OperationType.purchase:
        return 'Покупка/приход';
      case OperationType.expense:
        return 'Расход';
    }
  }

  Color _colorForType(OperationType type) {
    switch (type) {
      case OperationType.sale:
        return Colors.green;
      case OperationType.purchase:
        return Colors.blue;
      case OperationType.expense:
        return Colors.redAccent;
    }
  }

  void _toggleEmployeeExpanded(int employeeId) {
    setState(() {
      if (_expandedEmployeeIds.contains(employeeId)) {
        _expandedEmployeeIds.remove(employeeId);
      } else {
        _expandedEmployeeIds.add(employeeId);
      }
    });
  }

  void _openChatWithEmployee(Employee employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EmployeeChatPage(employee: employee),
      ),
    );
  }
}

class _ModulesOverview extends StatelessWidget {
  const _ModulesOverview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleCubit, ModuleState>(
      builder: (context, state) {
        if (state.isLoading && state.modules.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('Загружаем конфигурацию модулей...'),
                ],
              ),
            ),
          );
        }

        if (state.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!)),
                  TextButton(
                    onPressed: () => context.read<ModuleCubit>().load(),
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            ),
          );
        }

        final enabledModules = state.modules.where((m) => m.enabled).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Модули CRM',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                      label: Text('${enabledModules.length}/${state.modules.length} активны'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.modules
                      .map(
                        (module) => InputChip(
                          label: Text(module.title),
                          avatar: Icon(
                            module.enabled ? Icons.toggle_on : Icons.toggle_off_outlined,
                            color: module.enabled ? Colors.green : Colors.grey,
                          ),
                          selected: module.enabled,
                          onPressed: null,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Управление конфигурацией доступно в режиме администратора на экране входа.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleTab {
  final String label;
  final IconData icon;
  final Widget child;

  const _ModuleTab({required this.label, required this.icon, required this.child});
}

class _ModuleShell extends StatelessWidget {
  final String title;
  final List<_ModuleTab> tabs;

  const _ModuleShell({required this.title, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DefaultTabController(
        length: tabs.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            TabBar(
              isScrollable: true,
              tabs: tabs.map((t) => Tab(icon: Icon(t.icon), text: t.label)).toList(),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: tabs
                    .map((tab) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tab.child,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final CRMModule module;
  final bool isSelected;
  final double width;
  final Color backgroundColor;
  final Color accentColor;
  final IconData leadingIcon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.isSelected,
    required this.width,
    required this.backgroundColor,
    required this.accentColor,
    required this.leadingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardHeight = 220.0;
    final cardColor = isSelected ? accentColor.withOpacity(0.18) : backgroundColor;
    final borderSide = isSelected ? BorderSide(color: accentColor, width: 1.4) : BorderSide.none;

    return SizedBox(
      width: width,
      height: cardHeight,
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          side: borderSide,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: cardHeight,
              maxHeight: cardHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(leadingIcon, color: accentColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text('Модуль CRM', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.visibility : Icons.chevron_right,
                        color: accentColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    module.description.isNotEmpty ? module.description : 'Модуль CRM',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeDetailsPage extends StatelessWidget {
  final Employee employee;
  final Position position;

  const _EmployeeDetailsPage({required this.employee, required this.position});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(employee.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(position.title),
              subtitle: const Text('Должность'),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(employee.email),
              subtitle: const Text('Рабочая почта'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(statusLabel(employee.status)),
              subtitle: const Text('Статус сотрудника'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeChatPage extends StatefulWidget {
  final Employee employee;

  const _EmployeeChatPage({required this.employee});

  @override
  State<_EmployeeChatPage> createState() => _EmployeeChatPageState();
}

class _EmployeeChatPageState extends State<_EmployeeChatPage> {
  final _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат с ${widget.employee.name}')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(message),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Сообщение',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
