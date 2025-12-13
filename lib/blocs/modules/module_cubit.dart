import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/module.dart';
import '../../data/repositories/module_repository.dart';
import 'module_state.dart';

class ModuleCubit extends Cubit<ModuleState> {
  final ModuleRepository _repository;

  ModuleCubit({required ModuleRepository repository})
      : _repository = repository,
        super(ModuleState.initial());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final modules = await _repository.fetchModules();
      emit(state.copyWith(modules: modules, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> toggleModule(CRMModule module, bool enabled) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.toggleModule(module, enabled);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> updateModule(CRMModule module) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.updateModule(module);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}
