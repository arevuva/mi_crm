import 'package:equatable/equatable.dart';

import '../../data/models/document_entry.dart';

class DocumentState extends Equatable {
  final bool loading;
  final List<DocumentEntry> documents;
  final String? error;

  const DocumentState({required this.loading, this.documents = const [], this.error});

  factory DocumentState.initial() => const DocumentState(loading: false);

  DocumentState copyWith({bool? loading, List<DocumentEntry>? documents, String? error}) {
    return DocumentState(
      loading: loading ?? this.loading,
      documents: documents ?? this.documents,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, documents, error];
}
