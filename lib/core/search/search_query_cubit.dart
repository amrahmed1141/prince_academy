import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight query-only cubit for screens where the list owner is separate
/// (e.g. Home coaches list) or a feature Bloc already owns the source data.
class SearchQueryCubit extends Cubit<String> {
  SearchQueryCubit([super.initial = '']);

  bool get hasQuery => state.isNotEmpty;

  void search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query == state) return;
    emit(query);
  }

  void clear() {
    if (state.isEmpty) return;
    emit('');
  }
}
