import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/operation.dart';
import '../../data/repositories/operation_repository.dart';

part 'operations_event.dart';
part 'operations_state.dart';

class OperationsBloc extends Bloc<OperationsEvent, OperationsState> {
  final OperationRepository _repository;

  OperationsBloc({required OperationRepository repository})
      : _repository = repository,
        super(const OperationsState()) {
    on<LoadOperations>(_onLoadOperations);
    on<AddOperationRequested>(_onAddOperationRequested);
  }

  Future<void> _onLoadOperations(
    LoadOperations event,
    Emitter<OperationsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final operations = await _repository.loadOperations();
      emit(state.copyWith(isLoading: false, operations: operations));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddOperationRequested(
    AddOperationRequested event,
    Emitter<OperationsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final savedOperation = await _repository.addOperation(event.operation);
      final updated = [savedOperation, ...state.operations];
      emit(state.copyWith(isLoading: false, operations: updated));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
