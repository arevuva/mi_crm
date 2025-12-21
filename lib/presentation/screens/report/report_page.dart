import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/company/company_cubit.dart';
import '../../../blocs/company/company_state.dart';
import '../../../blocs/document/document_cubit.dart';
import '../../../blocs/document/document_state.dart';
import '../../../blocs/modules/module_cubit.dart';
import '../../../blocs/modules/module_state.dart';
import '../../../blocs/operations/operations_bloc.dart';
import '../../../blocs/accounting/accounting_cubit.dart';
import '../../../blocs/accounting/accounting_state.dart';
import '../../../blocs/report/report_cubit.dart';
import '../../../blocs/report/report_state.dart';
import '../../../blocs/sales/sales_cubit.dart';
import '../../../blocs/sales/sales_state.dart';
import '../../../data/models/accounting_entry.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/employee_message.dart';
import '../../../data/models/document_entry.dart';
import '../../../data/models/module.dart';
import '../../../data/models/operation.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sales_record.dart';
import '../../../data/repositories/employee_communication_repository.dart';
import '../../utils/status_labels.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

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
  Color moduleColorForIndex(CRMModule module) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.redAccent,
      Colors.indigo,
    ];
    final idHash = module.id.codeUnits.fold<int>(0, (prev, c) => prev + c);
    return palette[idHash % palette.length];
  }
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final companyState = context.watch<CompanyCubit>().state;
    final moduleState = context.watch<ModuleCubit>().state;

    if (companyState.company == null || authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Нет данных для отчётов. Войдите и создайте компанию.')),
      );
    }

    final employee = _findEmployeeForUser(companyState, authState);
    if (employee == null) {
      return const Scaffold(
        body: Center(child: Text('Для вашего аккаунта не найден сотрудник.')),
      );
    }

    if (companyState.positions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Нет настроенных должностей для доступа к отчётам.')),
      );
    }

    final position = companyState.positions.firstWhere(
      (p) => p.id == employee.positionId,
      orElse: () => companyState.positions.first,
    );

    final allowedModules = position.modules.toSet();
    final enabledModules = moduleState.modules.where((m) => m.enabled).toList();
    final availableModules =
        enabledModules.where((m) => allowedModules.contains(m.id)).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RefreshIndicator(
          onRefresh: () => context.read<ReportCubit>().refresh(),
          child: BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(child: Text(state.error!));
              }

              return ListView(
                children: [
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
                        children: availableModules
                            .map(
                          (module) => _ReportTile(
                                module: module,
                                state: state,
                                width: tileWidth,
                                color: moduleColorForIndex(module),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => _ModuleReportPage(
                                      module: module,
                                      state: state,
                                      companyId: companyState.company!.id,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _TasksCalendarSection(companyState: companyState, currentEmployee: employee),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Советы',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(
                              'Следите за балансом между продажами и расходами, чтобы поддерживать положительный денежный поток. Настраивайте регулярное обновление отчётов, чтобы видеть динамику.'),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final CRMModule module;
  final ReportState state;
  final VoidCallback onTap;
  final double width;
  final Color color;

  const _ReportTile({
    required this.module,
    required this.state,
    required this.onTap,
    required this.width,
    required this.color,
  });

  String get _value {
    switch (module.id) {
      case 'sales':
        return '${state.salesTotal.toStringAsFixed(2)} ₽';
      case 'finance':
        return '${state.expenseTotal.toStringAsFixed(2)} ₽';
      default:
        return '${state.operationsCount} записей';
    }
  }

  Color get _color {
    switch (module.id) {
      case 'sales':
        return Colors.green;
      case 'finance':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String get _displayTitle => module.id == 'sales' ? 'Товарооборот' : module.title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        child: Card(
          color: color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment_outlined, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_value, style: TextStyle(fontSize: 20, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleReportPage extends StatefulWidget {
  final CRMModule module;
  final ReportState state;
  final int companyId;

  const _ModuleReportPage({required this.module, required this.state, required this.companyId});

  @override
  State<_ModuleReportPage> createState() => _ModuleReportPageState();
}

class _ModuleReportPageState extends State<_ModuleReportPage> {
  DateTime? _selectedDay;
  bool _showIncome = false;
  bool _docSortDesc = true;
  DocumentType? _docTypeFilter;

  @override
  void initState() {
    super.initState();
    context.read<SalesCubit>().load(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final operationsState = context.watch<OperationsBloc>().state;
    final salesState = context.watch<SalesCubit>().state;
    final documentState = context.watch<DocumentCubit>().state;
    final companyState = context.watch<CompanyCubit>().state;
    final accountingState = context.watch<AccountingCubit>().state;
    final ops = _filterOpsByModule(operationsState.operations, widget.module.id);

    final byDayOps = _aggregateByDay(ops, days: 7);
    final byTypeOps = _aggregateByType(ops);

    final salesRecords = salesState.records.where((r) => r.type == SalesRecordType.sale).toList();
    final incomeRecords =
        salesState.records.where((r) => r.type == SalesRecordType.income).toList();
    final productMap = {for (final p in salesState.products) p.id: p};
    final activeRecords = _showIncome ? incomeRecords : salesRecords;
    final activeByDay = _aggregateSalesByDay(activeRecords, productMap, days: 7);
    final selectedDay = _selectedDay ?? (activeByDay.isNotEmpty ? activeByDay.keys.last : null);
    final pieDataAll = _aggregateSalesByProduct(activeRecords);
    final Map<int, double> pieDataDay =
        selectedDay != null ? _aggregateSalesByProduct(activeRecords, day: selectedDay) : {};
    final summary = widget.module.id == 'sales'
        ? _showIncome
            ? 'Поступления: ${widget.state.purchaseTotal.toStringAsFixed(2)} ₽'
            : 'Продажи: ${widget.state.salesTotal.toStringAsFixed(2)} ₽'
        : widget.module.id == 'finance'
            ? 'Расходы: ${widget.state.expenseTotal.toStringAsFixed(2)} ₽'
            : 'Записей: ${widget.state.operationsCount}';

    return Scaffold(
      appBar: AppBar(title: Text('Отчёт по ${widget.module.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.module.id == 'sales' ? 'Товарооборот' : widget.module.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(summary, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.module.id == 'sales') ...[
                Row(
                  children: [
                    Expanded(
                      child: _ToggleCard(
                        title: 'Продажи',
                        selected: !_showIncome,
                        onTap: () => setState(() {
                          _showIncome = false;
                          _selectedDay = null;
                        }),
                        icon: Icons.point_of_sale_outlined,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToggleCard(
                        title: 'Поступления',
                        selected: _showIncome,
                        onTap: () => setState(() {
                          _showIncome = true;
                          _selectedDay = null;
                        }),
                        icon: Icons.inventory_outlined,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeByDay.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showIncome
                                ? 'Поступления по дням (последние 7)'
                                : 'Продажи по дням (последние 7)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _StackedBarChart(
                            data: activeByDay,
                            productColors: _productColors(productMap),
                            onDaySelected: (day) => setState(() => _selectedDay = day),
                            selectedDay: selectedDay,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDay != null
                                ? '${_showIncome ? 'Поступления' : 'Продажи'} по товарам (${selectedDay!.day}.${selectedDay!.month})'
                                : '${_showIncome ? 'Поступления' : 'Продажи'} по товарам',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: _PieChartProducts(
                              data: selectedDay != null && pieDataDay.isNotEmpty
                                  ? pieDataDay
                                  : pieDataAll,
                              colors: _productColors(productMap),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: (selectedDay != null && pieDataDay.isNotEmpty
                                    ? pieDataDay
                                    : pieDataAll)
                                .entries
                                .map(
                                  (e) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _productColors(productMap)[e.key] ??
                                              Colors.blueGrey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${productMap[e.key]?.title ?? 'Товар'} — ${e.value.toStringAsFixed(0)} ₽',
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const Text('Нет данных по операциям за последние 7 дней.'),
              ] else if (widget.module.id == 'finance') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Операционные расходы по дням (7 дней)',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _ExpensesMiniChart(
                          data: _aggregateByDay(
                            _mergeAccountingExpenses(
                              ops.where((o) => o.type == OperationType.expense).toList(),
                              accountingState.entries,
                            ),
                            days: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Все операции', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ..._financeEntries(ops, accountingState.entries)
                            .map((entry) => _FinanceEntryTile(entry: entry))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ] else if (widget.module.id == 'docs') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Документы',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            Row(
                              children: [
                                DropdownButton<DocumentType?>(
                                  value: _docTypeFilter,
                                  hint: const Text('Все типы'),
                                  onChanged: (value) => setState(() => _docTypeFilter = value),
                                  items: [
                                    const DropdownMenuItem<DocumentType?>(
                                        value: null, child: Text('Все')),
                                    ...DocumentType.values.map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(_docLabel(t)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<bool>(
                                  value: _docSortDesc,
                                  onChanged: (value) =>
                                      setState(() => _docSortDesc = value ?? true),
                                  items: const [
                                    DropdownMenuItem(value: true, child: Text('Сначала новые')),
                                    DropdownMenuItem(value: false, child: Text('Сначала старые')),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (documentState.loading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ..._filteredDocs(documentState.documents)
                              .map(
                                (d) {
                                  final participantNames = d.ownerIds
                                      .map((id) {
                                        final match = companyState.employees.where((e) => e.id == id);
                                        return match.isNotEmpty ? match.first.name : null;
                                      })
                                      .whereType<String>()
                                      .join(', ');
                                  return ListTile(
                                    leading: const Icon(Icons.description_outlined),
                                    title: Text('${_docLabel(d.type)} — ${d.title}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if ((d.note ?? '').isNotEmpty) Text(d.note!),
                                        if (participantNames.isNotEmpty)
                                          Text('Участники: $participantNames',
                                              style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                    trailing: Text(DateFormat('dd.MM.y HH:mm').format(d.createdAt)),
                                  );
                                },
                              )
                              .toList(),
                      ],
                    ),
                  ),
                ),
              ] else if (widget.module.id == 'hr') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Сотрудники', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        if (companyState.employees.isEmpty)
                          const Text('Нет сотрудников для отображения.')
                        else
                          ...companyState.employees.map(
                            (e) => ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(e.name),
                              subtitle: Text(
                                  'Статус: ${statusLabel(e.status)} • Email: ${e.email.isEmpty ? '—' : e.email}'),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(companyState.positions
                                      .firstWhere((p) => p.id == e.positionId)
                                      .title),
                                  Builder(
                                    builder: (_) {
                                      final dept = companyState.departments
                                          .where((d) => d.id == e.departmentId)
                                          .toList();
                                      if (dept.isEmpty) return const SizedBox.shrink();
                                      final position =
                                          companyState.positions.firstWhere((p) => p.id == e.positionId);
                                      final isHead = position.isHead;
                                      return Text(
                                        isHead
                                            ? 'Отдел: ${dept.first.title} (глава)'
                                            : 'Отдел: ${dept.first.title}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                if (byDayOps.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.module.title}: операции по дням (последние 7)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _BarChart(points: byDayOps),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (byTypeOps.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.module.title}: распределение по типам',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(height: 180, child: _PieChart(data: byTypeOps)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: byTypeOps.entries
                                .map((e) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _colorForType(e.key),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${_titleForType(e.key)} — ${e.value.toStringAsFixed(0)} ₽'),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, double> _aggregateByDay(List<Operation> ops, {int days = 7}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final Map<DateTime, double> data = {};
    for (var op in ops) {
      final day = DateTime(op.createdAt.year, op.createdAt.month, op.createdAt.day);
      if (day.isBefore(DateTime(start.year, start.month, start.day))) continue;
      data[day] = (data[day] ?? 0) + op.amount.abs();
    }
    final ordered = <DateTime, double>{};
    for (var i = 0; i < days; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      ordered[d] = data[d] ?? 0;
    }
    return ordered;
  }

  Map<OperationType, double> _aggregateByType(List<Operation> ops) {
    final Map<OperationType, double> data = {};
    for (var op in ops) {
      data[op.type] = (data[op.type] ?? 0) + op.amount.abs();
    }
    return data;
  }

  List<Operation> _filterOpsByModule(List<Operation> ops, String moduleId) {
    switch (moduleId) {
      case 'sales':
        return ops.where((o) => o.type == OperationType.sale || o.type == OperationType.purchase).toList();
      case 'finance':
        return ops;
      default:
        return ops;
    }
  }

  List<_FinanceEntry> _financeEntries(List<Operation> ops, List<AccountingEntry> expenses) {
    final merged = <_FinanceEntry>[
      ...ops.map(
        (o) => _FinanceEntry(
          title: _titleForType(o.type),
          note: o.description,
          amount: o.amount,
          date: o.createdAt,
          color: _colorForType(o.type),
        ),
      ),
      ...expenses.map(
        (e) => _FinanceEntry(
          title: 'Операционный расход',
          note: e.note,
          amount: -e.delta.abs(),
          date: e.createdAt,
          color: Colors.redAccent,
        ),
      ),
    ];
    merged.sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  List<Operation> _mergeAccountingExpenses(List<Operation> ops, List<AccountingEntry> expenses) {
    final expenseOps = expenses
        .map(
          (e) => Operation(
            id: e.id,
            type: OperationType.expense,
            amount: -e.delta.abs(),
            description: e.note,
            createdAt: e.createdAt,
            ownerIds: const [],
          ),
        )
        .toList();
    return [...ops, ...expenseOps];
  }

  List<DocumentEntry> _filteredDocs(List<DocumentEntry> docs) {
    final filtered = _docTypeFilter == null
        ? docs
        : docs.where((d) => d.type == _docTypeFilter).toList();
    filtered.sort((a, b) =>
        _docSortDesc ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  String _docLabel(DocumentType type) {
    switch (type) {
      case DocumentType.receipt:
        return 'Накладная/приход';
      case DocumentType.act:
        return 'Акт';
      case DocumentType.consumable:
        return 'Расходник';
      case DocumentType.contract:
        return 'Договор';
    }
  }

  Map<DateTime, Map<int, double>> _aggregateSalesByDay(
    List<SalesRecord> records,
    Map<int, Product> products, {
    int days = 7,
  }) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    final Map<DateTime, Map<int, double>> data = {};
    for (final r in records) {
      if (r.productId == null) continue;
      final day = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      if (day.isBefore(DateTime(start.year, start.month, start.day))) continue;
      data.putIfAbsent(day, () => {});
      data[day]![r.productId!] = (data[day]![r.productId!] ?? 0) + r.amount;
    }
    final ordered = <DateTime, Map<int, double>>{};
    for (var i = 0; i < days; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      ordered[d] = data[d] ?? {};
    }
    return ordered;
  }

  Map<int, double> _aggregateSalesByProduct(List<SalesRecord> records, {DateTime? day}) {
    final Map<int, double> data = {};
    for (final r in records) {
      if (r.productId == null) continue;
      if (day != null) {
        final recDay = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        final target = DateTime(day.year, day.month, day.day);
        if (recDay != target) continue;
      }
      data[r.productId!] = (data[r.productId!] ?? 0) + r.amount;
    }
    return data;
  }

  Map<int, Color> _productColors(Map<int, Product> products) {
    final colors = <int, Color>{};
    final palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
    ];
    var idx = 0;
    for (final id in products.keys) {
      colors[id] = palette[idx % palette.length].withOpacity(0.85);
      idx++;
    }
    return colors;
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

class _TasksCalendarSection extends StatefulWidget {
  final CompanyState companyState;
  final Employee currentEmployee;

  const _TasksCalendarSection({required this.companyState, required this.currentEmployee});

  @override
  State<_TasksCalendarSection> createState() => _TasksCalendarSectionState();
}

class _TasksCalendarSectionState extends State<_TasksCalendarSection> {
  final EmployeeCommunicationRepository _communicationRepository = EmployeeCommunicationRepository();
  List<EmployeeMessage> _tasks = [];
  bool _tasksLoading = false;
  String? _taskError;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDay;
  bool _localeReady = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru').then((_) {
      if (mounted) setState(() => _localeReady = true);
    });
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _tasksLoading = true;
      _taskError = null;
    });
    try {
      if (widget.companyState.positions.isEmpty) {
        setState(() => _taskError = 'Нет должностей для загрузки поручений');
        return;
      }
      final position = widget.companyState.positions
          .firstWhere((p) => p.id == widget.currentEmployee.positionId, orElse: () => widget.companyState.positions.first);
      final isHead = position.isHead;
      final deptId = widget.currentEmployee.departmentId;
      final receiverIds = <int>{widget.currentEmployee.id};
      if (isHead && deptId != null) {
        receiverIds.addAll(
          widget.companyState.employees.where((e) => e.departmentId == deptId).map((e) => e.id),
        );
      }
      final tasks = await _communicationRepository.fetchTasksForReceivers(receiverIds.toList());
      setState(() {
        _tasks = tasks;
        _selectedCalendarDay ??= DateTime.now();
      });
    } catch (e) {
      setState(() => _taskError = e.toString());
    } finally {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  Map<DateTime, List<EmployeeMessage>> _tasksByDay() {
    final map = <DateTime, List<EmployeeMessage>>{};
    for (final t in _tasks) {
      final date = t.dueDate ?? t.createdAt;
      final day = DateTime(date.year, date.month, date.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final tasksByDay = _tasksByDay();
    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final startPadding = firstDay.weekday - 1;
    final tiles = <Widget>[];
    for (var i = 0; i < startPadding; i++) {
      tiles.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
      final key = DateTime(date.year, date.month, date.day);
      final dayTasks = tasksByDay[key] ?? [];
      final isSelected = _selectedCalendarDay != null &&
          _selectedCalendarDay!.year == key.year &&
          _selectedCalendarDay!.month == key.month &&
          _selectedCalendarDay!.day == key.day;
      final hasCompleted = dayTasks.any((t) => t.status == 'completed');
      final hasOpen = dayTasks.any((t) => t.status != 'completed');
      tiles.add(GestureDetector(
        onTap: () {
          setState(() => _selectedCalendarDay = key);
          if (dayTasks.isNotEmpty) {
            _openTasksForDay(dayTasks);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                : dayTasks.isNotEmpty
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.08)
                    : null,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day.toString().padLeft(2, '0')),
              const Spacer(),
              Row(
                children: [
                  if (hasOpen)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    ),
                  if (hasCompleted) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ));
    }

    final selectedDay = _selectedCalendarDay ?? DateTime.now();
    final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final selectedTasks = tasksByDay[dayKey] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Календарь поручений', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                      }),
                    ),
                    Text(
                      _localeReady
                          ? DateFormat('LLLL yyyy', 'ru').format(_calendarMonth)
                          : DateFormat.yMMM().format(_calendarMonth),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_taskError != null)
              Text(_taskError!, style: const TextStyle(color: Colors.red)),
            if (_tasksLoading)
              const Center(child: CircularProgressIndicator()),
            GridView.count(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: tiles,
            ),
            const SizedBox(height: 12),
            if (selectedTasks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedTasks
                    .map(
                      (t) => ListTile(
                        title: Text(t.text),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'От: ${_employeeName(t.senderId)}'
                                  '${t.dueDate != null ? ' • Срок: ${DateFormat('dd.MM.yyyy').format(t.dueDate!)}' : ''}',
                            ),
                            Text('Статус: ${t.status == 'completed' ? 'завершено' : 'в работе'}'),
                          ],
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _openTaskDetails(t),
                      ),
                    )
                    .toList(),
              )
            else
              const Text('Нет поручений на выбранный день.'),
          ],
        ),
      ),
    );
  }

  String _employeeName(int id) {
    final match = widget.companyState.employees.where((e) => e.id == id);
    return match.isNotEmpty ? match.first.name : 'Сотрудник';
  }

  Future<void> _openTaskDetails(EmployeeMessage task) async {
    final commentController = TextEditingController(text: task.comment ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var status = task.status;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Поручение', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(task.text),
              const SizedBox(height: 6),
              Text('От: ${_employeeName(task.senderId)}'),
              if (task.dueDate != null)
                Text('Срок: ${DateFormat('dd.MM.yyyy').format(task.dueDate!)}'),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий',
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _communicationRepository.updateTask(
                        taskId: task.id,
                        comment: commentController.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                      await _loadTasks();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Сохранить'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: status == 'completed'
                        ? null
                        : () async {
                            status = 'completed';
                            await _communicationRepository.updateTask(
                              taskId: task.id,
                              status: 'completed',
                              comment: commentController.text.trim(),
                            );
                            Navigator.of(ctx).pop();
                            await _loadTasks();
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Завершить'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    commentController.dispose();
  }

  Future<void> _openTasksForDay(List<EmployeeMessage> tasks) async {
    if (tasks.isEmpty) return;
    if (tasks.length == 1) {
      await _openTaskDetails(tasks.first);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tasks
                .map(
                  (t) => ListTile(
                    title: Text(t.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'От: ${_employeeName(t.senderId)}'
                      '${t.dueDate != null ? ' • Срок: ${DateFormat('dd.MM.yyyy').format(t.dueDate!)}' : ''}',
                    ),
                    trailing: Text(t.status == 'completed' ? 'Завершено' : 'Активно'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _openTaskDetails(t);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ExpensesMiniChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const _ExpensesMiniChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Нет данных для отображения.');
    }
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxValue = entries.map((e) => e.value).fold<double>(0, (prev, v) => v > prev ? v : prev);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries
            .map(
              (e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: maxValue == 0 ? 0 : (e.value / maxValue) * 110,
                            width: 14,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${e.key.day}.${e.key.month}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FinanceEntry {
  final String title;
  final String note;
  final double amount;
  final DateTime date;
  final Color color;

  _FinanceEntry({
    required this.title,
    required this.note,
    required this.amount,
    required this.date,
    required this.color,
  });
}

class _FinanceEntryTile extends StatelessWidget {
  final _FinanceEntry entry;

  const _FinanceEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.swap_horiz, color: entry.color),
      title: Text(entry.title),
      subtitle: Text(entry.note),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${entry.amount.toStringAsFixed(2)} ₽'),
          Text(
            DateFormat('dd.MM.y HH:mm').format(entry.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _ToggleCard({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.icon,
    this.color = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: color, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : color.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedBarChart extends StatelessWidget {
  final Map<DateTime, Map<int, double>> data;
  final Map<int, Color> productColors;
  final void Function(DateTime) onDaySelected;
  final DateTime? selectedDay;

  const _StackedBarChart({
    required this.data,
    required this.productColors,
    required this.onDaySelected,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values
        .map((m) => m.values.fold<double>(0, (sum, v) => sum + v))
        .fold<double>(0, (max, v) => math.max(max, v));
    final days = data.entries.toList();
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((entry) {
          final total = entry.value.values.fold<double>(0, (sum, v) => sum + v);
          final double height = maxValue == 0 ? 0 : (total / maxValue) * 160;
          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(entry.key),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                      border: selectedDay != null &&
                              DateTime(entry.key.year, entry.key.month, entry.key.day) ==
                                  DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day)
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: entry.value.entries.map((segment) {
                        final double segHeight = total == 0 ? 0 : (segment.value / total) * height;
                        return Container(
                          height: segHeight,
                          width: double.infinity,
                          color: productColors[segment.key] ?? Colors.blueGrey,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${entry.key.day}.${entry.key.month}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PieChartProducts extends StatelessWidget {
  final Map<int, double> data;
  final Map<int, Color> colors;

  const _PieChartProducts({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PieChartProductsPainter(data, colors),
      child: const SizedBox.expand(),
    );
  }
}

class _PieChartProductsPainter extends CustomPainter {
  final Map<int, double> data;
  final Map<int, Color> colors;

  _PieChartProductsPainter(this.data, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.min(size.width, size.height) * 0.8,
      height: math.min(size.width, size.height) * 0.8,
    );
    double startAngle = -math.pi / 2;
    data.forEach((productId, value) {
      final sweep = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[productId] ?? Colors.blueGrey;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChart extends StatelessWidget {
  final Map<DateTime, double> points;

  const _BarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.values.fold<double>(0, (max, v) => math.max(max, v));
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.entries.map((entry) {
          final double height = maxValue == 0 ? 0 : (entry.value / maxValue) * 160;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.key.day}.${entry.key.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<OperationType, double> data;

  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PieChartPainter(data),
      child: const SizedBox.expand(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<OperationType, double> data;

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.min(size.width, size.height) * 0.8,
      height: math.min(size.width, size.height) * 0.8,
    );
    double startAngle = -math.pi / 2;
    data.forEach((type, value) {
      final sweep = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = _colorForType(type);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    });
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
