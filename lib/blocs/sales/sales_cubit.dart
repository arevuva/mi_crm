import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/sales_record.dart';
import '../../data/repositories/sales_repository.dart';
import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final SalesRepository _repository;
  int? _companyId;

  SalesCubit({required SalesRepository repository})
      : _repository = repository,
        super(SalesState.initial());

  Future<void> load(int companyId) async {
    _companyId = companyId;
    emit(state.copyWith(loading: true, error: null));
    try {
      final categories = await _repository.fetchCategories(companyId);
      final products = await _repository.fetchProducts(companyId);
      final leads = await _repository.fetchLeads(companyId);
      final records = await _repository.fetchSalesRecords(companyId);
      emit(state.copyWith(
        loading: false,
        categories: categories,
        products: products,
        leads: leads,
        records: records,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addCategory(String title) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addCategory(companyId: _companyId!, title: title);
      final categories = await _repository.fetchCategories(_companyId!);
      emit(state.copyWith(loading: false, categories: categories));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addProduct({required int categoryId, required String title, required double price, required int stock}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addProduct(
        companyId: _companyId!,
        categoryId: categoryId,
        title: title,
        price: price,
        stock: stock,
      );
      final products = await _repository.fetchProducts(_companyId!);
      emit(state.copyWith(loading: false, products: products));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addLead({required String name, required String contact, required String status, int? productId}) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addLead(
        companyId: _companyId!,
        name: name,
        contact: contact,
        status: status,
        productId: productId,
      );
      final leads = await _repository.fetchLeads(_companyId!);
      emit(state.copyWith(loading: false, leads: leads));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addRecord({
    required SalesRecordType type,
    required int quantity,
    required double amount,
    String? note,
    int? productId,
  }) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addRecord(
        companyId: _companyId!,
        type: type,
        quantity: quantity,
        amount: amount,
        note: note,
        productId: productId,
      );
      final records = await _repository.fetchSalesRecords(_companyId!);
      emit(state.copyWith(loading: false, records: records));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> updatePrice(int productId, double price) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.updatePrice(productId, price);
      final products = await _repository.fetchProducts(_companyId!);
      emit(state.copyWith(loading: false, products: products));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> updateReservation(int productId, int reserved) async {
    if (_companyId == null) return;
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.reserveProduct(productId, reserved);
      final products = await _repository.fetchProducts(_companyId!);
      emit(state.copyWith(loading: false, products: products));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
