import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/company/company_cubit.dart';
import '../../../blocs/company/company_state.dart';
import '../../../blocs/theme/theme_cubit.dart';
import '../../../data/models/employee.dart';
import '../../../data/models/user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return _ProfileContent(user: state.user);
            }
            return const Center(child: Text('Пользователь не авторизован'));
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final AppUser user;

  const _ProfileContent({required this.user});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  EmployeeStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final companyState = context.watch<CompanyCubit>().state;
    final employee = _findEmployee(companyState);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        final profileCard = Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(widget.user.email),
            subtitle: Text(employee != null ? 'Должность: ${_positionTitle(companyState, employee)}' : 'Рабочая почта'),
          ),
        );

        final infoCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CRM поддерживает офлайн хранение данных и сохранит ваши операции локально.',
                ),
                if (employee != null) ...[
                  const SizedBox(height: 8),
                  Text('Ваш статус: ${_statusLabel(employee.status)}'),
                ],
              ],
            ),
          ),
        );

        final statusCard = employee == null
            ? const SizedBox.shrink()
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Статус сотрудника',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<EmployeeStatus>(
                        value: _selectedStatus ?? employee.status,
                        items: EmployeeStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_statusLabel(s)),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedStatus = value ?? employee.status),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _selectedStatus == null || _selectedStatus == employee.status
                            ? null
                            : () {
                                context.read<CompanyCubit>().updateStatus(employee.id, _selectedStatus!);
                              },
                        child: const Text('Обновить статус'),
                      ),
                    ],
                  ),
                ),
              );

        final settingsTile = Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Настройки'),
            subtitle: const Text('Тема и персональные параметры'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _SettingsPage()),
            ),
          ),
        );

        final logoutButton = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
            label: const Text('Выйти'),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileCard,
              const SizedBox(height: 12),
              infoCard,
              const SizedBox(height: 12),
              statusCard,
              const SizedBox(height: 12),
              settingsTile,
              const Spacer(),
              logoutButton,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileCard,
                      const SizedBox(height: 12),
                      infoCard,
                      const SizedBox(height: 12),
                      statusCard,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: _SettingsPanel()),
              ],
            ),
            const Spacer(),
            logoutButton,
          ],
        );
      },
    );
  }

  Employee? _findEmployee(CompanyState state) {
    try {
      return state.employees.firstWhere(
        (e) => e.email.toLowerCase() == widget.user.email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String _positionTitle(CompanyState state, Employee employee) {
    try {
      return state.positions.firstWhere((p) => p.id == employee.positionId).title;
    } catch (_) {
      return 'Сотрудник';
    }
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: _SettingsPanel(),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Выберите тему приложения'),
            const SizedBox(height: 8),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                return Column(
                  children: [
                    _ThemeModeTile(
                      label: 'Системная',
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: (value) =>
                          context.read<ThemeCubit>().setThemeMode(value),
                    ),
                    _ThemeModeTile(
                      label: 'Светлая',
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: (value) =>
                          context.read<ThemeCubit>().setThemeMode(value),
                    ),
                    _ThemeModeTile(
                      label: 'Тёмная',
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: (value) =>
                          context.read<ThemeCubit>().setThemeMode(value),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: (mode) {
        if (mode != null) onChanged(mode);
      },
      title: Text(label),
    );
  }
}
