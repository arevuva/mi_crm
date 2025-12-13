import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/company/company_cubit.dart';
import 'blocs/modules/module_cubit.dart';
import 'blocs/navigation/tab_cubit.dart';
import 'blocs/operations/operations_bloc.dart';
import 'blocs/pr/pr_cubit.dart';
import 'blocs/report/report_cubit.dart';
import 'blocs/sales/sales_cubit.dart';
import 'blocs/document/document_cubit.dart';
import 'blocs/accounting/accounting_cubit.dart';
import 'blocs/theme/theme_cubit.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/accounting_repository.dart';
import 'data/repositories/module_repository.dart';
import 'data/repositories/operation_repository.dart';
import 'data/repositories/company_repository.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/pr_repository.dart';
import 'data/repositories/sales_repository.dart';
import 'presentation/screens/auth/login_page.dart';
import 'presentation/screens/auth/register_page.dart';
import 'presentation/screens/home/home_page.dart';
import 'presentation/screens/profile/profile_page.dart';
import 'presentation/screens/report/report_page.dart';
import 'presentation/widgets/responsive_scaffold.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final operationRepository = OperationRepository();
    final moduleRepository = ModuleRepository();
    final companyRepository = CompanyRepository();
    final salesRepository = SalesRepository();
    final documentRepository = DocumentRepository();
    final prRepository = PrRepository();
    final accountingRepository = AccountingRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: operationRepository),
        RepositoryProvider.value(value: moduleRepository),
        RepositoryProvider.value(value: companyRepository),
        RepositoryProvider.value(value: salesRepository),
        RepositoryProvider.value(value: documentRepository),
        RepositoryProvider.value(value: prRepository),
        RepositoryProvider.value(value: accountingRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository)..add(AppStarted()),
          ),
          BlocProvider(
            create: (_) => OperationsBloc(repository: operationRepository)..add(LoadOperations()),
          ),
          BlocProvider(
            create: (_) => ReportCubit(repository: operationRepository)..refresh(),
          ),
          BlocProvider(
            create: (_) => ModuleCubit(repository: moduleRepository)..load(),
          ),
          BlocProvider(
            create: (_) => CompanyCubit(repository: companyRepository)..load(),
          ),
          BlocProvider(
            create: (_) => SalesCubit(repository: salesRepository),
          ),
          BlocProvider(
            create: (_) => DocumentCubit(repository: documentRepository),
          ),
          BlocProvider(
            create: (_) => PrCubit(repository: prRepository),
          ),
          BlocProvider(
            create: (_) => AccountingCubit(repository: accountingRepository),
          ),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => TabCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'mi_crm',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: const _RootPage(),
            );
          },
        ),
      ),
    );
  }
}

class _RootPage extends StatelessWidget {
  const _RootPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is Authenticated) {
          return const _MainTabs();
        }

        if (state is Unauthenticated) {
          return const LoginPage();
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _MainTabs extends StatelessWidget {
  const _MainTabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabCubit, int>(
      builder: (context, index) {
        return ResponsiveScaffold(
          selectedIndex: index,
          onItemSelected: (value) => context.read<TabCubit>().selectTab(value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), label: 'Главная'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Отчёт'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
          ],
          body: IndexedStack(
            index: index,
            children: const [
              HomePage(),
              ReportPage(),
              ProfilePage(),
            ],
          ),
        );
      },
    );
  }
}

class LoginRoute extends MaterialPageRoute<void> {
  LoginRoute({super.settings}) : super(builder: (_) => const LoginPage());
}

class RegisterRoute extends MaterialPageRoute<void> {
  RegisterRoute({super.settings}) : super(builder: (_) => const RegisterPage());
}
