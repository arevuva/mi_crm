import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/company/company_cubit.dart';
import '../../../blocs/company/company_state.dart';
import '../../../blocs/modules/module_cubit.dart';
import '../../../blocs/modules/module_state.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/module.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    context.read<ModuleCubit>().load();
    context.read<CompanyCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конструктор CRM — Администратор'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            _CompanyBlock(),
            SizedBox(height: 16),
            _ModuleConfig(),
            SizedBox(height: 16),
            _PositionBlock(),
            SizedBox(height: 16),
            _EmployeesBlock(),
          ],
        ),
      ),
    );
  }

}

class _CompanyBlock extends StatefulWidget {
  const _CompanyBlock();

  @override
  State<_CompanyBlock> createState() => _CompanyBlockState();
}

class _CompanyBlockState extends State<_CompanyBlock> {
  final _companyController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyCubit, CompanyState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        if (state.company == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Создать компанию', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Укажите название компании, в рамках которой будут вестись операции.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Название компании'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: state.loading
                        ? null
                        : () {
                            final name = _companyController.text.trim();
                            if (name.isNotEmpty) {
                              context.read<CompanyCubit>().createCompany(name);
                            }
                          },
                    icon: const Icon(Icons.business),
                    label: state.loading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Создать'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business_center_outlined),
                    const SizedBox(width: 8),
                    Text(state.company!.name, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Старт работы: ${state.company!.createdAt.toLocal()}'),
                if (state.positions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Добавьте должности, чтобы регистрировать сотрудников.'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleConfig extends StatelessWidget {
  const _ModuleConfig();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleCubit, ModuleState>(
      builder: (context, state) {
        if (state.isLoading && state.modules.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<ModuleCubit>().load(),
                  child: const Text('Повторить попытку'),
                ),
              ],
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Модули', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => context.read<ModuleCubit>().load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...state.modules.map(
                  (module) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(module.title),
                    subtitle: Text(module.description),
                    trailing: Switch(
                      value: module.enabled,
                      onChanged: (value) => context.read<ModuleCubit>().toggleModule(module, value),
                    ),
                    onTap: () => _openEditDialog(context, module),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditDialog(BuildContext context, CRMModule module) {
    final titleController = TextEditingController(text: module.title);
    final descriptionController = TextEditingController(text: module.description);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Настройка модуля', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ModuleCubit>().updateModule(
                          module.copyWith(
                            title: titleController.text.trim().isEmpty
                                ? module.title
                                : titleController.text.trim(),
                            description: descriptionController.text.trim().isEmpty
                                ? module.description
                                : descriptionController.text.trim(),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Сохранить изменения'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _PositionBlock extends StatefulWidget {
  const _PositionBlock();

  @override
  State<_PositionBlock> createState() => _PositionBlockState();
}

class _PositionBlockState extends State<_PositionBlock> {
  final _titleController = TextEditingController();
  final Set<String> _selectedModules = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyState>(
      builder: (context, companyState) {
        if (companyState.company == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Должности и доступы', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                BlocBuilder<ModuleCubit, ModuleState>(
                  builder: (context, moduleState) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: moduleState.modules
                          .map((m) => FilterChip(
                                label: Text(m.title),
                                selected: _selectedModules.contains(m.id),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedModules.add(m.id);
                                    } else {
                                      _selectedModules.remove(m.id);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Название должности'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: companyState.loading
                        ? null
                        : () {
                            final title = _titleController.text.trim();
                            if (title.isNotEmpty) {
                              context
                                  .read<CompanyCubit>()
                                  .addPosition(title, _selectedModules.toList());
                              _titleController.clear();
                              _selectedModules.clear();
                              setState(() {});
                            }
                          },
                    child: companyState.loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Создать должность'),
                  ),
                ),
                const SizedBox(height: 8),
                if (companyState.positions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text('Существующие должности', style: Theme.of(context).textTheme.titleSmall),
                      ...companyState.positions.map(
                        (p) => ListTile(
                          title: Text(p.title),
                          subtitle: Text('Доступы: ${p.modules.join(', ')}'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmployeesBlock extends StatefulWidget {
  const _EmployeesBlock();

  @override
  State<_EmployeesBlock> createState() => _EmployeesBlockState();
}

class _EmployeesBlockState extends State<_EmployeesBlock> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int? _positionId;
  EmployeeStatus _status = EmployeeStatus.onsite;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyCubit, CompanyState>(
      builder: (context, state) {
        if (state.company == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сотрудники', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _positionId,
                  decoration: const InputDecoration(labelText: 'Должность'),
                  items: state.positions
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                      .toList(),
                  onChanged: (value) => setState(() => _positionId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Рабочий email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ФИО сотрудника'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EmployeeStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Статус'),
                  items: const [
                    DropdownMenuItem(value: EmployeeStatus.onsite, child: Text('На работе')),
                    DropdownMenuItem(value: EmployeeStatus.commute, child: Text('В пути')),
                    DropdownMenuItem(value: EmployeeStatus.remote, child: Text('Удалённо')),
                    DropdownMenuItem(value: EmployeeStatus.home, child: Text('Дома')),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? EmployeeStatus.onsite),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: state.loading
                      ? null
                          : () {
                              final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          if (name.isEmpty || email.isEmpty || _positionId == null) return;
                          context.read<CompanyCubit>().addEmployee(
                                email: email,
                                name: name,
                                positionId: _positionId!,
                                status: _status,
                              );
                          _nameController.clear();
                          _emailController.clear();
                            },
                  icon: const Icon(Icons.person_add_alt),
                  label: state.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Добавить сотрудника'),
                ),
                const Divider(height: 24),
                ...state.employees.map(
                  (employee) => ListTile(
                    title: Text(employee.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${employee.email}'),
                        Text('Должность: ${state.positions.firstWhere((p) => p.id == employee.positionId).title}'),
                      ],
                    ),
                    trailing: DropdownButton<EmployeeStatus>(
                      value: employee.status,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<CompanyCubit>().updateStatus(employee.id, value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: EmployeeStatus.onsite, child: Text('На работе')),
                        DropdownMenuItem(value: EmployeeStatus.commute, child: Text('В пути')),
                        DropdownMenuItem(value: EmployeeStatus.remote, child: Text('Удалённо')),
                        DropdownMenuItem(value: EmployeeStatus.home, child: Text('Дома')),
                      ],
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
}
