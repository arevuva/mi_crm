import 'package:equatable/equatable.dart';

import '../../data/models/lead.dart';
import '../../data/models/product.dart';
import '../../data/models/product_category.dart';
import '../../data/models/sales_record.dart';

class SalesState extends Equatable {
  final bool loading;
  final List<ProductCategory> categories;
  final List<Product> products;
  final List<Lead> leads;
  final List<SalesRecord> records;
  final String? error;

  const SalesState({
    required this.loading,
    this.error,
    this.categories = const [],
    this.products = const [],
    this.leads = const [],
    this.records = const [],
  });

  factory SalesState.initial() => const SalesState(loading: false);

  SalesState copyWith({
    bool? loading,
    List<ProductCategory>? categories,
    List<Product>? products,
    List<Lead>? leads,
    List<SalesRecord>? records,
    String? error,
  }) {
    return SalesState(
      loading: loading ?? this.loading,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      leads: leads ?? this.leads,
      records: records ?? this.records,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, categories, products, leads, records, error];
}
