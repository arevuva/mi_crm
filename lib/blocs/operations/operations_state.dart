part of 'operations_bloc.dart';

class OperationsState extends Equatable {
  final List<Operation> operations;
  final bool isLoading;
  final String? error;

  const OperationsState({
    this.operations = const [],
    this.isLoading = false,
    this.error,
  });

  OperationsState copyWith({
    List<Operation>? operations,
    bool? isLoading,
    String? error,
  }) {
    return OperationsState(
      operations: operations ?? this.operations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [operations, isLoading, error];
}
