import 'package:equatable/equatable.dart';

import '../../data/models/operation.dart';

class ReportState extends Equatable {
  final double salesTotal;
  final double purchaseTotal;
  final double expenseTotal;
  final int operationsCount;
  final bool isLoading;
  final String? error;

  const ReportState({
    this.salesTotal = 0,
    this.purchaseTotal = 0,
    this.expenseTotal = 0,
    this.operationsCount = 0,
    this.isLoading = false,
    this.error,
  });

  ReportState copyWith({
    double? salesTotal,
    double? purchaseTotal,
    double? expenseTotal,
    int? operationsCount,
    bool? isLoading,
    String? error,
  }) {
    return ReportState(
      salesTotal: salesTotal ?? this.salesTotal,
      purchaseTotal: purchaseTotal ?? this.purchaseTotal,
      expenseTotal: expenseTotal ?? this.expenseTotal,
      operationsCount: operationsCount ?? this.operationsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        salesTotal,
        purchaseTotal,
        expenseTotal,
        operationsCount,
        isLoading,
        error,
      ];
}
