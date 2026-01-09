import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/accounting_repository.dart';
import 'accounting_state.dart';

class AccountingCubit extends Cubit<AccountingState> {
  final AccountingRepository _repository;
  int? _companyId;

  AccountingCubit({required AccountingRepository repository})
      : _repository = repository,
        super(AccountingState.initial());

  Future<void> load(int companyId) async {
    _companyId = companyId;
    emit(state.copyWith(loading: true, error: null));
    try {
      final entries = await _repository.fetchEntries(companyId);
      emit(state.copyWith(loading: false, entries: entries));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addEntry({required String targetType, required int targetId, required double delta, required String note}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addEntry(
        companyId: _companyId!,
        targetType: targetType,
        targetId: targetId,
        delta: delta,
        note: note,
      );
      final entries = await _repository.fetchEntries(_companyId!);
      emit(state.copyWith(loading: false, entries: entries));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
