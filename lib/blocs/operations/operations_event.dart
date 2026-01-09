part of 'operations_bloc.dart';

abstract class OperationsEvent {}

class LoadOperations extends OperationsEvent {}

class AddOperationRequested extends OperationsEvent {
  final Operation operation;

  AddOperationRequested(this.operation);
}
