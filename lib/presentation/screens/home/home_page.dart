import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/modules/module_cubit.dart';
import '../../../blocs/modules/module_state.dart';
import '../../../blocs/operations/operations_bloc.dart';
import '../../../blocs/report/report_cubit.dart';
import '../../../data/models/operation.dart';
import '../../widgets/operation_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  OperationType _selectedType = OperationType.sale;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<OperationsBloc, OperationsState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const _ModulesOverview(),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWide ? 2 : 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<OperationType>(
                                          value: _selectedType,
                                          decoration: const InputDecoration(labelText: 'Тип операции'),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() => _selectedType = value);
                                            }
                                          },
                                          items: const [
                                            DropdownMenuItem(
                                              value: OperationType.sale,
                                              child: Text('Продажа'),
                                            ),
                                            DropdownMenuItem(
                                              value: OperationType.purchase,
                                              child: Text('Покупка/приход'),
                                            ),
                                            DropdownMenuItem(
                                              value: OperationType.expense,
                                              child: Text('Расход'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isWide) const SizedBox(width: 12),
                                      if (isWide)
                                        Expanded(
                                          child: TextFormField(
                                            controller: _amountController,
                                            decoration: const InputDecoration(labelText: 'Сумма'),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            validator: (value) {
                                              final parsed = double.tryParse(value ?? '');
                                              if (parsed == null || parsed <= 0) {
                                                return 'Введите сумму';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (!isWide) const SizedBox(height: 12),
                                  if (!isWide)
                                    TextFormField(
                                      controller: _amountController,
                                      decoration: const InputDecoration(labelText: 'Сумма'),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        final parsed = double.tryParse(value ?? '');
                                        if (parsed == null || parsed <= 0) {
                                          return 'Введите сумму';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(labelText: 'Описание операции'),
                                    maxLines: 2,
                                    validator: (value) =>
                                        value != null && value.isNotEmpty ? null : 'Введите описание',
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add),
                                      onPressed: state.isLoading
                                          ? null
                                          : () {
                                              if (_formKey.currentState?.validate() ?? false) {
                                                final operation = Operation(
                                                  type: _selectedType,
                                                  amount: double.parse(_amountController.text),
                                                  description: _descriptionController.text,
                                                  createdAt: DateTime.now(),
                                                );
                                                context
                                                    .read<OperationsBloc>()
                                                    .add(AddOperationRequested(operation));
                                                context.read<ReportCubit>().refresh();
                                                _amountController.clear();
                                                _descriptionController.clear();
                                              }
                                            },
                                      label: state.isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Добавить операцию'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Последние операции',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  const Text('Нет записей. Добавьте первую операцию!')
                                else
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: state.operations.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final op = state.operations[index];
                                        return OperationCard(
                                          title: _titleForType(op.type),
                                          subtitle: op.description,
                                          amount: op.amount,
                                          timestamp: DateFormat('dd MMM yyyy, HH:mm').format(op.createdAt),
                                          color: _colorForType(op.type),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
