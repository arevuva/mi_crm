import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/company/company_cubit.dart';
import '../../../blocs/company/company_state.dart';
import '../../../blocs/modules/module_cubit.dart';
import '../../../blocs/modules/module_state.dart';
import '../../../data/models/department.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/module.dart';
import '../../../data/models/position.dart';
import '../../constants/module_submodules.dart';
import '../../utils/status_labels.dart';

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
            _DepartmentsBlock(),
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
                    decoration: const InputDecoration(
                      labelText: 'Название компании',
                      prefixIcon: Icon(Icons.business),
                    ),
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
                    Expanded(child: Text(state.company!.name, style: Theme.of(context).textTheme.titleMedium)),
                    IconButton(
                      onPressed: () => _openRenameDialog(context, state),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Переименовать компанию',
                    ),
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

  void _openRenameDialog(BuildContext context, CompanyState state) {
    final controller = TextEditingController(text: state.company?.name ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
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
              Text('Переименовать компанию', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Новое название',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty || state.company == null) return;
                    context.read<CompanyCubit>().renameCompany(name);
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Сохранить'),
                ),
              ),
              const SizedBox(height: 8),
            ],
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
                decoration: const InputDecoration(
                  labelText: 'Название',
                  prefixIcon: Icon(Icons.short_text),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  prefixIcon: Icon(Icons.notes),
                ),
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

class _DepartmentsBlock extends StatefulWidget {
  const _DepartmentsBlock();

  @override
  State<_DepartmentsBlock> createState() => _DepartmentsBlockState();
}

class _DepartmentsBlockState extends State<_DepartmentsBlock> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
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
                Text('Отделы', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название отдела',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: state.loading
                      ? null
                      : () {
                          final title = _titleController.text.trim();
                          if (title.isEmpty) return;
                          context.read<CompanyCubit>().addDepartment(title);
                          _titleController.clear();
                        },
                  icon: const Icon(Icons.add_business_outlined),
                  label: state.loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Создать отдел'),
                ),
                const SizedBox(height: 8),
                if (state.departments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text('Существующие отделы', style: Theme.of(context).textTheme.titleSmall),
                      ...state.departments.map((d) {
                        final headCandidates = state.employees.where((e) {
                          if (e.departmentId != d.id) return false;
                          final pos = state.positions.firstWhere((p) => p.id == e.positionId);
                          return pos.isHead;
                        }).toList();
                        final headName = headCandidates.isEmpty ? null : headCandidates.first.name;
                        final count = state.employees.where((e) => e.departmentId == d.id).length;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(d.title),
                          subtitle: Text(
                            headName == null ? 'Руководитель ещё не назначен' : 'Руководитель: $headName',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$count сотрудн.'),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Удалить отдел',
                                onPressed: () => _confirmDeleteDepartment(context, state, d),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteDepartment(BuildContext context, CompanyState state, Department department) {
    final employeesInDepartment = state.employees.where((e) => e.departmentId == department.id).toList();
    final otherDepartments = state.departments.where((d) => d.id != department.id).toList();

    if (employeesInDepartment.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить отдел?'),
          content: Text('Вы действительно хотите удалить отдел "${department.title}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                context
                    .read<CompanyCubit>()
                    .deleteDepartment(department.id, employeeReassignments: const <int, int>{});
                Navigator.of(ctx).pop();
              },
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      return;
    }

    if (otherDepartments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Создайте ещё один отдел, чтобы перенести сотрудников.')),
      );
      return;
    }

    final Map<int, int> assignments = {
      for (final employee in employeesInDepartment) employee.id: otherDepartments.first.id,
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Распределите сотрудников', style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Отдел "${department.title}" будет удалён. Выберите, куда перенести сотрудников.'),
                    const SizedBox(height: 12),
                    ...employeesInDepartment.map(
                      (employee) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(employee.name)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: assignments[employee.id],
                                items: otherDepartments
                                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.title)))
                                    .toList(),
                                onChanged: (value) =>
                                    setSheetState(() => assignments[employee.id] = value ?? assignments[employee.id]!),
                                decoration: const InputDecoration(
                                  labelText: 'Новый отдел',
                                  prefixIcon: Icon(Icons.apartment_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.read<CompanyCubit>().deleteDepartment(
                                department.id,
                                employeeReassignments: assignments,
                              );
                        },
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Удалить отдел и перенести сотрудников'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
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
  final Map<String, Set<String>> _selectedSubmodules = {};
  bool _isHead = false;

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
                    final availableModules = moduleState.modules.where((m) => m.enabled).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableModules
                              .map((m) => FilterChip(
                                    label: Text(m.title),
                                    selected: _selectedModules.contains(m.id),
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          _selectedModules.add(m.id);
                                          final submods = moduleSubmodules[m.id] ?? const [];
                                          _selectedSubmodules[m.id] =
                                              submods.isEmpty ? <String>{} : submods.map((s) => s.id).toSet();
                                        } else {
                                          _selectedModules.remove(m.id);
                                          _selectedSubmodules.remove(m.id);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        ..._selectedModules
                            .where((moduleId) => (moduleSubmodules[moduleId] ?? []).isNotEmpty)
                            .map(
                              (moduleId) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Подмодули: ${moduleState.modules.firstWhere((m) => m.id == moduleId).title}'),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (moduleSubmodules[moduleId] ?? [])
                                          .map(
                                            (sub) => FilterChip(
                                              label: Text(sub.title),
                                              selected: _selectedSubmodules[moduleId]?.contains(sub.id) ?? false,
                                              onSelected: (value) {
                                                setState(() {
                                                  final set = _selectedSubmodules[moduleId] ?? <String>{};
                                                  if (value) {
                                                    set.add(sub.id);
                                                  } else {
                                                    set.remove(sub.id);
                                                  }
                                                  _selectedSubmodules[moduleId] = set;
                                                });
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название должности',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isHead,
                  onChanged: (value) => setState(() => _isHead = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Это должность главы отдела'),
                  subtitle: const Text('В каждом отделе может быть только один сотрудник с этой должностью'),
                  secondary: const Icon(Icons.workspace_premium_outlined),
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
                              final Map<String, List<String>> selectedSubmodules = {
                                for (final entry in _selectedSubmodules.entries)
                                  if (_selectedModules.contains(entry.key))
                                    entry.key: entry.value.toList(),
                              };
                              context
                                  .read<CompanyCubit>()
                                  .addPosition(
                                    title,
                                    _selectedModules.toList(),
                                    isHead: _isHead,
                                    submodules: selectedSubmodules,
                                  );
                              _titleController.clear();
                              _selectedModules.clear();
                              _selectedSubmodules.clear();
                              _isHead = false;
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
                          subtitle: Text([
                            'Доступы: ${p.modules.join(', ')}',
                            if (p.submodules.isNotEmpty)
                              'Подмодули: ${p.submodules.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join(' | ')}',
                          ].join('\n')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.isHead) const Chip(label: Text('Глава отдела')),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDeletePosition(context, p),
                                tooltip: 'Удалить должность',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditPosition(context, p),
                              ),
                            ],
                          ),
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

  void _confirmDeletePosition(BuildContext context, Position position) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить должность?'),
        content: Text('Вы уверены, что хотите удалить должность "${position.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              context.read<CompanyCubit>().deletePosition(position);
              Navigator.of(ctx).pop();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _openEditPosition(BuildContext context, Position position) {
    final titleController = TextEditingController(text: position.title);
    final modules = {...position.modules};
    final Map<String, Set<String>> submodules = {
      for (final entry in position.submodules.entries) entry.key: entry.value.toSet(),
    };
    for (final moduleId in modules) {
      if (!submodules.containsKey(moduleId) && (moduleSubmodules[moduleId] ?? []).isNotEmpty) {
        submodules[moduleId] = moduleSubmodules[moduleId]!.map((s) => s.id).toSet();
      }
    }
    bool isHead = position.isHead;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Редактировать должность', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                BlocBuilder<ModuleCubit, ModuleState>(
                  builder: (context, moduleState) {
                    final availableModules = moduleState.modules.where((m) => m.enabled).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableModules
                              .map((m) => FilterChip(
                                    label: Text(m.title),
                                    selected: modules.contains(m.id),
                                    onSelected: (value) {
                                      setState(() {
                                        if (value) {
                                          modules.add(m.id);
                                          final submods = moduleSubmodules[m.id] ?? const [];
                                          submodules[m.id] =
                                              submods.isEmpty ? <String>{} : submods.map((s) => s.id).toSet();
                                        } else {
                                          modules.remove(m.id);
                                          submodules.remove(m.id);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        ...modules
                            .where((moduleId) => (moduleSubmodules[moduleId] ?? []).isNotEmpty)
                            .map(
                              (moduleId) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Подмодули: ${moduleState.modules.firstWhere((m) => m.id == moduleId).title}'),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (moduleSubmodules[moduleId] ?? [])
                                          .map(
                                            (sub) => FilterChip(
                                              label: Text(sub.title),
                                              selected: submodules[moduleId]?.contains(sub.id) ?? false,
                                              onSelected: (value) {
                                                setState(() {
                                                  final set = submodules[moduleId] ?? <String>{};
                                                  if (value) {
                                                    set.add(sub.id);
                                                  } else {
                                                    set.remove(sub.id);
                                                  }
                                                  submodules[moduleId] = set;
                                                });
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название должности',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                SwitchListTile(
                  value: isHead,
                  onChanged: (value) => setState(() => isHead = value),
                  title: const Text('Это должность главы отдела'),
                  secondary: const Icon(Icons.workspace_premium_outlined),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      final Map<String, List<String>> selectedSubmodules = {
                        for (final entry in submodules.entries)
                          if (modules.contains(entry.key)) entry.key: entry.value.toList(),
                      };
                      context.read<CompanyCubit>().updatePositionEntry(
                            Position(
                              id: position.id,
                              companyId: position.companyId,
                              title: title,
                              modules: modules.toList(),
                              isHead: isHead,
                              submodules: selectedSubmodules,
                            ),
                          );
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Сохранить изменения'),
                  ),
                ),
                const SizedBox(height: 16),
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
  int? _departmentId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _confirmDeleteEmployee(BuildContext context, Employee employee) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить сотрудника?'),
        content: Text('Вы уверены, что хотите удалить ${employee.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              context.read<CompanyCubit>().deleteEmployee(employee.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
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
                if (state.departments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Сначала создайте отдел, чтобы добавить сотрудников.'),
                  ),
                DropdownButtonFormField<int>(
                  value: _departmentId,
                  decoration: const InputDecoration(
                    labelText: 'Отдел',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  items: state.departments
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.title)))
                      .toList(),
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _positionId,
                  decoration: const InputDecoration(
                    labelText: 'Должность',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: state.positions
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                      .toList(),
                  onChanged: (value) => setState(() => _positionId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Рабочий email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ФИО сотрудника',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: state.loading
                      ? null
                      : () {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          if (name.isEmpty || email.isEmpty || _positionId == null || _departmentId == null) return;
                          context.read<CompanyCubit>().addEmployee(
                                email: email,
                                name: name,
                                positionId: _positionId!,
                                departmentId: _departmentId!,
                                status: EmployeeStatus.onsite,
                              );
                          _nameController.clear();
                          _emailController.clear();
                          _departmentId = null;
                          _positionId = null;
                          setState(() {});
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
                        Builder(
                          builder: (_) {
                            final deptCandidates =
                                state.departments.where((d) => d.id == employee.departmentId).toList();
                            final deptTitle = deptCandidates.isNotEmpty ? deptCandidates.first.title : 'не назначен';
                            final pos = state.positions.firstWhere((p) => p.id == employee.positionId);
                            final isHead = pos.isHead;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Отдел: $deptTitle'),
                                if (isHead) const Text('Роль: Руководитель отдела'),
                              ],
                            );
                          },
                        ),
                        Row(
                          children: [
                            const Text('Аккаунт: '),
                            Chip(
                              label: Text(employee.userId != null ? 'зарегистрирован' : 'не зарегистрирован'),
                              avatar: Icon(
                                employee.userId != null ? Icons.check_circle_outline : Icons.error_outline,
                                color: employee.userId != null ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        Text('Статус сотрудника: ${statusLabel(employee.status)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Удалить сотрудника',
                          onPressed: () => _confirmDeleteEmployee(context, employee),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openEditEmployee(context, state, employee),
                        ),
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

void _openEditEmployee(BuildContext context, CompanyState state, Employee employee) {
  final nameController = TextEditingController(text: employee.name);
  final emailController = TextEditingController(text: employee.email);
  int positionId = employee.positionId;
  int? departmentId = employee.departmentId ?? (state.departments.isNotEmpty ? state.departments.first.id : null);
  EmployeeStatus status = employee.status;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Редактировать сотрудника', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: departmentId,
                decoration: const InputDecoration(
                  labelText: 'Отдел',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: state.departments
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.title)))
                    .toList(),
                onChanged: (value) => departmentId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: positionId,
                decoration: const InputDecoration(
                  labelText: 'Должность',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: state.positions
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                    .toList(),
                onChanged: (value) => positionId = value ?? positionId,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Рабочий email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ФИО сотрудника',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EmployeeStatus>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  prefixIcon: Icon(Icons.emoji_people_outlined),
                ),
                items: EmployeeStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(statusLabel(s)),
                        ))
                    .toList(),
                onChanged: (value) => status = value ?? status,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty || departmentId == null) return;
                    context.read<CompanyCubit>().updateEmployeeEntry(
                          Employee(
                            id: employee.id,
                            companyId: employee.companyId,
                            positionId: positionId,
                            departmentId: departmentId,
                            email: email,
                            name: name,
                            status: status,
                            userId: employee.userId,
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Сохранить'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
