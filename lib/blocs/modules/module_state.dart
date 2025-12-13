import '../../data/models/module.dart';

class ModuleState {
  final List<CRMModule> modules;
  final bool isLoading;
  final String? error;

  const ModuleState({
    required this.modules,
    required this.isLoading,
    this.error,
  });

  factory ModuleState.initial() => const ModuleState(modules: [], isLoading: true);

  ModuleState copyWith({
    List<CRMModule>? modules,
    bool? isLoading,
    String? error,
  }) {
    return ModuleState(
      modules: modules ?? this.modules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
