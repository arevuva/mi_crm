import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/navigation/tab_cubit.dart';
import '../admin/admin_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state is Authenticated) {
                      context.read<TabCubit>().selectTab(0);
                    }
                  },
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Вход', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 24),
                        if (state is Unauthenticated && state.message != null)
                          Text(state.message!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (value) =>
                                    value != null && value.contains('@') ? null : 'Введите корректный email',
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(labelText: 'Пароль'),
                                obscureText: true,
                                validator: (value) =>
                                    value != null && value.length >= 6 ? null : 'Минимум 6 символов',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      context.read<AuthBloc>().add(LoginRequested(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ));
                                    }
                                  },
                            child: state is AuthLoading
                                ? const CircularProgressIndicator()
                                : const Text('Войти'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(RegisterRoute());
                          },
                          child: const Text('Создать аккаунт'),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: () => _requestAdminPassword(context),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Режим администратора'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _requestAdminPassword(BuildContext context) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Пароль администратора'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Введите пароль',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'admin') {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Неверный пароль')),
                );
              }
            },
            child: const Text('Войти'),
          ),
        ],
      );
    },
  );
}
