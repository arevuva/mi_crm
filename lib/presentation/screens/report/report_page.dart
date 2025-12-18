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
import '../../../blocs/report/report_cubit.dart';
import '../../../blocs/report/report_state.dart';
import '../../../blocs/sales/sales_cubit.dart';
import '../../../blocs/sales/sales_state.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/document_entry.dart';
import '../../../data/models/module.dart';
import '../../../data/models/operation.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sales_record.dart';
import '../../utils/status_labels.dart';
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: availableModules
                        .map(
                          (module) => _ReportTile(
                            module: module,
                            state: state,
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
                  ),
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

  const _ReportTile({required this.module, required this.state, required this.onTap});

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
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          color: _color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment_outlined, color: _color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_value, style: TextStyle(fontSize: 20, color: _color)),
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
                                (d) => ListTile(
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text('${_docLabel(d.type)} — ${d.title}'),
                                  subtitle: Text(d.note ?? ''),
                                  trailing: Text(DateFormat('dd.MM.y HH:mm').format(d.createdAt)),
                                ),
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
                              trailing: Text(companyState.positions
                                  .firstWhere((p) => p.id == e.positionId)
                                  .title),
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
      data[day] = (data[day] ?? 0) + op.amount;
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
        return ops.where((o) => o.type == OperationType.expense || o.type == OperationType.purchase).toList();
      default:
        return ops;
    }
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
