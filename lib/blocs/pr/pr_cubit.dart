import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/pr_repository.dart';
import 'pr_state.dart';

class PrCubit extends Cubit<PrState> {
  final PrRepository _repository;
  int? _companyId;

  PrCubit({required PrRepository repository})
      : _repository = repository,
        super(PrState.initial());

  Future<void> load(int companyId) async {
    _companyId = companyId;
    emit(state.copyWith(loading: true, error: null));
    try {
      final assets = await _repository.fetchAssets(companyId);
      final posts = await _repository.fetchPosts(companyId);
      emit(state.copyWith(loading: false, assets: assets, posts: posts));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addAsset({required String title, String? note, int? productId}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addAsset(
        companyId: _companyId!,
        title: title,
        note: note,
        productId: productId,
      );
      final assets = await _repository.fetchAssets(_companyId!);
      emit(state.copyWith(loading: false, assets: assets));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addPost({required String channel, required String message, String status = 'draft', int? productId}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addPost(
        companyId: _companyId!,
        channel: channel,
        message: message,
        status: status,
        productId: productId,
      );
      final posts = await _repository.fetchPosts(_companyId!);
      emit(state.copyWith(loading: false, posts: posts));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
