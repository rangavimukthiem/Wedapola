import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/home_repository.dart';

class SelectedCategoryNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? categoryId) {
    state = categoryId;
  }
}

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, int?>(SelectedCategoryNotifier.new);
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  return ref.watch(homeRepositoryProvider).getCategories();
});

final availableTechniciansProvider = FutureProvider<List<TechnicianItem>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider);
  return ref.watch(homeRepositoryProvider).getAvailableTechnicians(
        categoryId: categoryId,
        search: search,
      );
});
