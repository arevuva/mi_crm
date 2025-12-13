import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/operation.dart';
import '../../data/repositories/operation_repository.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final OperationRepository _repository;

  ReportCubit({required OperationRepository repository})
      : _repository = repository,
        super(const ReportState());

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final operations = await _repository.loadOperations();
      emit(_buildReport(operations));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  ReportState _buildReport(List<Operation> operations) {
    double sales = 0;
    double purchases = 0;
    double expenses = 0;
    for (final op in operations) {
      switch (op.type) {
        case OperationType.sale:
          sales += op.amount;
          break;
        case OperationType.purchase:
          purchases += op.amount;
          break;
        case OperationType.expense:
          expenses += op.amount;
          break;
      }
    }

    return state.copyWith(
      isLoading: false,
      operationsCount: operations.length,
      salesTotal: sales,
      purchaseTotal: purchases,
      expenseTotal: expenses,
      error: null,
    );
  }
}
