import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/report/report_cubit.dart';
import '../../../blocs/report/report_state.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    children: [
                      _ReportTile(
                        title: 'Продажи',
                        value: '${state.salesTotal.toStringAsFixed(2)} ₽',
                        color: Colors.green,
                      ),
                      _ReportTile(
                        title: 'Покупки',
                        value: '${state.purchaseTotal.toStringAsFixed(2)} ₽',
                        color: Colors.blue,
                      ),
                      _ReportTile(
                        title: 'Расходы',
                        value: '${state.expenseTotal.toStringAsFixed(2)} ₽',
                        color: Colors.redAccent,
                      ),
                      _ReportTile(
                        title: 'Записей',
                        value: state.operationsCount.toString(),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Советы',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
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
  final String title;
  final String value;
  final Color color;

  const _ReportTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 20, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
