import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyNotifier extends AsyncNotifier<String> {
  static const _currencyKey = 'selected_currency_symbol';
  static const _defaultCurrency = '\$';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? _defaultCurrency;
  }

  Future<void> setCurrency(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, symbol);
      state = AsyncData(symbol);
    } catch (e, st) {
      print('Error setting currency: $e');
      print(st);
      state = AsyncError(e, st);
    }
  }
}

final currencyProvider = AsyncNotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});
