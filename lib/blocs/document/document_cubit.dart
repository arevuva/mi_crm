import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/document_entry.dart';
import '../../data/repositories/document_repository.dart';
import 'document_state.dart';

class DocumentCubit extends Cubit<DocumentState> {
  final DocumentRepository _repository;
  int? _companyId;

  DocumentCubit({required DocumentRepository repository})
      : _repository = repository,
        super(DocumentState.initial());

  Future<void> load(int companyId) async {
    _companyId = companyId;
    emit(state.copyWith(loading: true, error: null));
    try {
      final docs = await _repository.fetchDocuments(companyId);
      emit(state.copyWith(loading: false, documents: docs));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addDocument({required DocumentType type, required String title, String? note, int? productId}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addDocument(
        companyId: _companyId!,
        type: type,
        title: title,
        note: note,
        productId: productId,
      );
      final docs = await _repository.fetchDocuments(_companyId!);
      emit(state.copyWith(loading: false, documents: docs));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
