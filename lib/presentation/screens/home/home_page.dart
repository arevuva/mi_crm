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
import '../../../data/models/employee.dart';
import '../../../data/models/module.dart';
import '../../../data/models/operation.dart';
import '../../../data/models/product.dart';
import '../../../data/models/position.dart';
import '../../../data/models/sales_record.dart';
import '../../widgets/operation_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _productTitleController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productStockController = TextEditingController();
  final _recordQuantityController = TextEditingController(text: '1');
  final _leadNameController = TextEditingController();
  final _leadContactController = TextEditingController();
  final _salesNoteController = TextEditingController();
  final _docTitleController = TextEditingController();
  final _docNoteController = TextEditingController();
  final _assetTitleController = TextEditingController();
  final _assetNoteController = TextEditingController();
  final _postChannelController = TextEditingController(text: 'VK');
  final _postMessageController = TextEditingController();
  final _accountingDeltaController = TextEditingController();
  final _accountingNoteController = TextEditingController();
  SalesRecordType _salesRecordType = SalesRecordType.sale;
  DocumentType _documentType = DocumentType.receipt;
  String _leadStatus = 'new';
  int? _selectedCategoryId;
  int? _selectedProductId;
  int? _selectedDocProductId;
  int? _selectedPrProductId;
  int? _accountingTargetId;
  String _accountingTargetType = 'product';
  int? _loadedCompanyId;
  String? _activeModuleId;

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _productTitleController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _recordQuantityController.dispose();
    _leadNameController.dispose();
    _leadContactController.dispose();
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

        _ensureModuleData(companyState.company!.id);
        final enabledModules = moduleState.modules
            .where((m) => m.enabled)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final availableModules = enabledModules
            .where((m) => allowedModules.contains(m.id))
            .toList();

        if (_activeModuleId == null ||
            !availableModules.any((m) => m.id == _activeModuleId)) {
          _activeModuleId = availableModules.isNotEmpty ? availableModules.first.id : null;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Главная')),
          body: Padding(
            padding: const EdgeInsets.all(16),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableModules
                        .map(
                          (module) => _ModuleCard(
                            module: module,
                            isSelected: module.id == _activeModuleId,
                            onTap: () => setState(() => _activeModuleId = module.id),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_activeModuleId ?? 'overview'),
                      child: _buildModuleContent(
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
              ],
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

  Widget _buildModuleContent({
    required String? moduleId,
    required OperationsState operationsState,
    required SalesState salesState,
    required DocumentState docState,
    required PrState prState,
    required AccountingState accountingState,
    required CompanyState companyState,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isCompact = screenWidth < 640;

    switch (moduleId) {
      case 'sales':
        return _ModuleShell(
          title: 'Продажи',
          tabs: const ['Справочники', 'Операции'],
          children: [
            _buildSalesReferences(salesState, companyState, isWide, isCompact),
            _buildSalesOperations(salesState, companyState, isWide),
          ],
        );
      case 'docs':
        return _ModuleShell(
          title: 'Документация',
          tabs: const ['Товарооборот', 'Документы'],
          children: [
            _buildDocsCard(docState, companyState, allowedTypes: const [DocumentType.receipt, DocumentType.consumable]),
            _buildDocsCard(docState, companyState, allowedTypes: const [DocumentType.act, DocumentType.contract]),
          ],
        );
      case 'pr_smm':
        return _ModuleShell(
          title: 'PR / SMM',
          tabs: const ['Соцсети', 'Коммуникации'],
          children: [
            _buildPrSocial(prState, companyState),
            _buildPrCommunication(prState, companyState),
          ],
        );
      case 'finance':
        return _ModuleShell(
          title: 'Бухгалтерия',
          tabs: const ['Персонал', 'Операционные расходы'],
          children: [
            _buildAccountingCard(accountingState, companyState, targetType: 'employee'),
            _buildAccountingCard(accountingState, companyState, targetType: 'expense'),
          ],
        );
      case 'hr':
        return _ModuleShell(
          title: 'Управление персоналом',
          tabs: const ['Сотрудники'],
          children: [
            _buildHrCard(companyState),
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

  Widget _buildSalesReferences(
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
                    const Text('Номенклатура и лиды',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      onPressed: () => context.read<SalesCubit>().load(companyState.company!.id),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: isCompact ? 8 : 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Категория товара'),
                        onSubmitted: (_) => _createCategory(context),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Категория для товара'),
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
                        decoration: const InputDecoration(labelText: 'Название товара'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 160 : double.infinity,
                      child: TextField(
                        controller: _productPriceController,
                        decoration: const InputDecoration(labelText: 'Цена'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 160 : double.infinity,
                      child: TextField(
                        controller: _productStockController,
                        decoration: const InputDecoration(labelText: 'Количество на складе'),
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
                const Divider(height: 24),
                Text('Лиды', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _leadNameController,
                        decoration: const InputDecoration(labelText: 'Имя лида'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: TextField(
                        controller: _leadContactController,
                        decoration: const InputDecoration(labelText: 'Контакты'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 180 : double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: _leadStatus,
                        decoration: const InputDecoration(labelText: 'Статус'),
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
                        value: _selectedProductId,
                        decoration: const InputDecoration(labelText: 'Интерес к товару'),
                        items: state.products
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedProductId = value),
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isWide ? 360 : double.infinity,
                      child: DropdownButtonFormField<int>(
                        value: _selectedProductId,
                        decoration: const InputDecoration(labelText: 'Товар для операции'),
                        items: state.products
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.title} — ${p.price.toStringAsFixed(0)}'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedProductId = value),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 200 : double.infinity,
                      child: DropdownButtonFormField<SalesRecordType>(
                        value: _salesRecordType,
                        decoration: const InputDecoration(labelText: 'Тип операции'),
                        items: const [
                          DropdownMenuItem(value: SalesRecordType.sale, child: Text('Продажа')),
                          DropdownMenuItem(value: SalesRecordType.income, child: Text('Поступление')),
                          DropdownMenuItem(value: SalesRecordType.reservation, child: Text('Резерв')), 
                        ],
                        onChanged: (value) => setState(() => _salesRecordType = value ?? SalesRecordType.sale),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 120 : double.infinity,
                      child: TextField(
                        controller: _recordQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Кол-во'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 160 : double.infinity,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Сумма/доход'),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 260 : double.infinity,
                      child: TextField(
                        controller: _salesNoteController,
                        decoration: const InputDecoration(labelText: 'Комментарий'),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.loading ? null : () => _submitSalesRecord(context),
                      icon: const Icon(Icons.save_outlined),
                      label: state.loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Зафиксировать'),
                    ),
                  ],
                ),
                if (state.records.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Последние операции', style: Theme.of(context).textTheme.titleSmall),
                  ...state.records.take(5).map(
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
                  decoration: const InputDecoration(labelText: 'Тип документа'),
                  items: allowedTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(_docTitle(type))))
                      .toList(),
                  onChanged: (value) => setState(() => _documentType = value ?? allowedTypes.first),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _docTitleController,
                  decoration: const InputDecoration(labelText: 'Название / номер документа'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedDocProductId,
                  decoration: const InputDecoration(labelText: 'Связанный товар (необязательно)'),
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
                  decoration: const InputDecoration(labelText: 'Комментарий'),
                ),
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
                (e) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(e.name),
                  subtitle: Text('Статус: ${_statusLabel(e.status)}'),
                  trailing:
                      Text(state.positions.firstWhere((p) => p.id == e.positionId).title),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _EmployeeDetailsPage(
                        employee: e,
                        position: state.positions.firstWhere((p) => p.id == e.positionId),
                      ),
                    ),
                  ),
                ),
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

  String _statusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.onsite:
        return 'На работе';
      case EmployeeStatus.commute:
        return 'В пути';
      case EmployeeStatus.remote:
        return 'Удаленно';
      case EmployeeStatus.home:
        return 'Дома';
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

  Future<void> _submitSalesRecord(BuildContext context) async {
    final quantity = int.tryParse(_recordQuantityController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (quantity <= 0 || amount <= 0) return;

    await context.read<SalesCubit>().addRecord(
          type: _salesRecordType,
          quantity: quantity,
          amount: amount,
          note: _salesNoteController.text,
          productId: _selectedProductId,
        );

    if (_salesRecordType == SalesRecordType.reservation && _selectedProductId != null) {
      final salesState = context.read<SalesCubit>().state;
      final product = salesState.products.firstWhere((p) => p.id == _selectedProductId);
      final newReserved = product.reserved + quantity;
      await context.read<SalesCubit>().updateReservation(product.id, newReserved);
    }

    // Пробрасываем запись в фин. учёт
    final operation = Operation(
      type: _salesRecordType == SalesRecordType.sale
          ? OperationType.sale
          : OperationType.purchase,
      amount: amount,
      description: 'Модуль продаж: ${_salesRecordType.name}${_selectedProductId != null ? ' по товару $_selectedProductId' : ''}',
      createdAt: DateTime.now(),
    );
    context.read<OperationsBloc>().add(AddOperationRequested(operation));
    context.read<ReportCubit>().refresh();

    _recordQuantityController.text = '1';
    _amountController.clear();
    _salesNoteController.clear();
  }

  Future<void> _createLead(BuildContext context) async {
    final name = _leadNameController.text.trim();
    if (name.isEmpty) return;
    await context.read<SalesCubit>().addLead(
          name: name,
          contact: _leadContactController.text.trim(),
          status: _leadStatus,
          productId: _selectedProductId,
        );
    _leadNameController.clear();
    _leadContactController.clear();
  }

  Future<void> _createDocument(BuildContext context) async {
    final title = _docTitleController.text.trim();
    if (title.isEmpty) return;
    await context.read<DocumentCubit>().addDocument(
          type: _documentType,
          title: title,
          note: _docNoteController.text,
          productId: _selectedDocProductId,
        );
    _docTitleController.clear();
    _docNoteController.clear();
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

class _ModuleShell extends StatelessWidget {
  final String title;
  final List<String> tabs;
  final List<Widget> children;

  const _ModuleShell({required this.title, required this.tabs, required this.children});

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
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: children
                    .map((child) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: child,
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
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(module.title, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Icon(isSelected ? Icons.visibility : Icons.visibility_outlined),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  module.description ?? 'Модуль CRM',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
              title: Text(_statusLabel(employee.status)),
              subtitle: const Text('Статус сотрудника'),
            ),
          ],
        ),
      ),
    );
  }
}
