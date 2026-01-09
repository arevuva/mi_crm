import 'package:equatable/equatable.dart';

import '../../data/models/accounting_entry.dart';

class AccountingState extends Equatable {
  final bool loading;
  final List<AccountingEntry> entries;
  final String? error;

  const AccountingState({required this.loading, this.entries = const [], this.error});

  factory AccountingState.initial() => const AccountingState(loading: false);

  AccountingState copyWith({bool? loading, List<AccountingEntry>? entries, String? error}) {
    return AccountingState(
      loading: loading ?? this.loading,
      entries: entries ?? this.entries,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, entries, error];
}
