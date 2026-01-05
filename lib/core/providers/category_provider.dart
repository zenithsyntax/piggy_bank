import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'database_provider.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<TransactionCategory>>(() {
  return CategoriesNotifier();
});

class CategoriesNotifier extends AsyncNotifier<List<TransactionCategory>> {
  @override
  Future<List<TransactionCategory>> build() async {
    return loadCategories();
  }

  Future<List<TransactionCategory>> loadCategories() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('categories');
      final categories = maps.map((e) => TransactionCategory.fromMap(e)).toList();
      state = AsyncValue.data(categories);
      return categories;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> addCategory(String name, CategoryType type) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final newCategory = TransactionCategory(
        id: const Uuid().v4(),
        name: name,
        type: type,
      );
      await db.insert('categories', newCategory.toMap());
      await loadCategories();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      await loadCategories();
    } catch (e) {
      // Handle error
    }
  }
}
