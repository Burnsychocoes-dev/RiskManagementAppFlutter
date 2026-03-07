import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet.dart';

/// File-backed (SharedPreferences) repository that stores the list of wallets as JSON.
class WalletRepository {
  static const _key = 'wallets_json';

  Future<List<Wallet>> loadWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(wallets.map((w) => w.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
