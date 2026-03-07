import 'package:flutter/foundation.dart';
import '../data/wallet_repository.dart';
import '../models/wallet.dart';
import '../models/position.dart';
import '../models/sub_position.dart';
import '../models/wallet_action.dart';

/// Equivalent to WalletViewModel in Kotlin — manages the list of wallets and persists changes.
class WalletProvider extends ChangeNotifier {
  final WalletRepository _repo = WalletRepository();

  List<Wallet> _wallets = [];
  List<Wallet> get wallets => List.unmodifiable(_wallets);

  WalletProvider() {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    _wallets = await _repo.loadWallets();
    notifyListeners();
  }

  void _persist() {
    _repo.saveWallets(_wallets);
  }

  // ─── Wallets ───────────────────────────────────────────────────────────────

  void addWallet(String name, double maxRisk, {String currency = '\$'}) {
    final wallet = Wallet(
      name: name,
      balance: 0.0,
      walletMaxRisk: maxRisk,
      currency: currency,
    );
    _wallets = [..._wallets, wallet];
    notifyListeners();
    _persist();
  }

  void addWalletObject(Wallet wallet) {
    _wallets = [..._wallets, wallet];
    notifyListeners();
    _persist();
  }

  void addWalletAt(Wallet wallet, int index) {
    final list = List<Wallet>.from(_wallets);
    final clamped = index.clamp(0, list.length);
    list.insert(clamped, wallet);
    _wallets = list;
    notifyListeners();
    _persist();
  }

  void updateWallet(Wallet updated) {
    _wallets = _wallets.map((w) {
      if (w.id != updated.id) return w;
      final newHistory = List<WalletAction>.from(w.history);
      if (w.walletMaxRisk != updated.walletMaxRisk) {
        newHistory.add(
          WalletAction(
            type: ActionType.updateWalletMax,
            description:
                'Wallet max risk changed from ${w.walletMaxRisk} to ${updated.walletMaxRisk}',
          ),
        );
      }
      return updated.copyWith(history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }

  void deleteWallet(String id) {
    _wallets = _wallets.where((w) => w.id != id).toList();
    notifyListeners();
    _persist();
  }

  // ─── Positions ─────────────────────────────────────────────────────────────

  void addPositionToWallet(String walletId, Position position) {
    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;
      final newPositions = [...w.positions, position];
      final newHistory = [
        ...w.history,
        WalletAction(
          type: ActionType.addPosition,
          description:
              'Added position ${position.ticker} - ${position.timeframe}',
        ),
      ];
      return w.copyWith(positions: newPositions, history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }

  void addPositionAt(String walletId, Position position, int index) {
    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;
      final list = List<Position>.from(w.positions);
      final clamped = index.clamp(0, list.length);
      list.insert(clamped, position);
      return w.copyWith(positions: list);
    }).toList();
    notifyListeners();
    _persist();
  }

  void deletePosition(String walletId, String positionId) {
    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;
      final removed = w.positions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => Position(ticker: '', maximumAllowedRisk: 0),
      );
      final newPositions = w.positions
          .where((p) => p.id != positionId)
          .toList();
      final tf = removed.timeframe.isEmpty ? '' : '-${removed.timeframe}';
      final desc = removed.ticker.isNotEmpty
          ? 'Closed position ${removed.ticker}$tf'
          : 'Closed position $positionId';
      final newHistory = [
        ...w.history,
        WalletAction(type: ActionType.closePosition, description: desc),
      ];
      return w.copyWith(positions: newPositions, history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }

  // ─── Sub-Positions ─────────────────────────────────────────────────────────

  void addSubPositionToPosition(
    String walletId,
    String positionId,
    SubPosition sub,
  ) {
    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;

      final newPositions = w.positions.map((p) {
        if (p.id != positionId) return p;
        return p.copyWith(subPositions: [...p.subPositions, sub]);
      }).toList();

      final pos = w.positions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => Position(ticker: '', maximumAllowedRisk: 0),
      );

      String desc;
      String? extra;
      try {
        if (pos.ticker.isNotEmpty) {
          final posAfter = newPositions.firstWhere((p) => p.id == positionId);
          final afterPct = posAfter.currentSizePercent();
          final beforePct = pos.currentSizePercent();
          final pct = pos.maximumAllowedRisk == 0
              ? 0.0
              : double.parse(
                  (sub.currentRisk() / pos.maximumAllowedRisk * 100)
                      .toStringAsFixed(2),
                );
          final delta = double.parse((afterPct - beforePct).toStringAsFixed(2));
          final deltaSign = delta >= 0 ? '+' : '';
          desc =
              'Added subposition to ${pos.ticker}: entry=${sub.entryPrice}, size=${sub.sizeInAsset}, pct=${pct}% — pos ${beforePct}% -> ${afterPct}% (Δ ${deltaSign}${delta}%)';
          extra =
              'ticker=${pos.ticker};timeframe=${pos.timeframe};subPct=${pct.toStringAsFixed(2)};posBefore=${beforePct.toStringAsFixed(2)};posAfter=${afterPct.toStringAsFixed(2)};delta=${delta.toStringAsFixed(2)}';
        } else {
          desc =
              'Added subposition to $positionId: entry=${sub.entryPrice}, size=${sub.sizeInAsset}';
        }
      } catch (_) {
        desc =
            'Added subposition to $positionId: entry=${sub.entryPrice}, size=${sub.sizeInAsset}';
      }

      final newHistory = [
        ...w.history,
        WalletAction(
          id: '${pos.ticker}_${sub.openedAtMillis}',
          type: ActionType.addSubposition,
          description: desc,
          extra: extra,
        ),
      ];
      return w.copyWith(positions: newPositions, history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }

  void reduceSubposition(
    String walletId,
    String positionId,
    int subIndex,
    double amountInAssetOrPct, {
    bool isPercent = false,
  }) {
    if (amountInAssetOrPct <= 0) return;

    // Capture before state.
    double beforePct = 0.0;
    double spBeforeSize = 0.0;
    int spOpenedAt = DateTime.now().millisecondsSinceEpoch;

    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;
      final newPositions = w.positions.map((p) {
        if (p.id != positionId) return p;
        beforePct = p.currentSizePercent();
        final subs = List<SubPosition>.from(p.subPositions);
        if (subIndex < 0 || subIndex >= subs.length) return p;
        final sp = subs[subIndex];
        spBeforeSize = sp.sizeInAsset;
        spOpenedAt = sp.openedAtMillis;
        final toRemove = isPercent
            ? amountInAssetOrPct / 100.0 * sp.sizeInAsset
            : amountInAssetOrPct;
        if (toRemove >= sp.sizeInAsset) {
          subs.removeAt(subIndex);
        } else {
          final newSize = double.parse(
            (sp.sizeInAsset - toRemove).toStringAsFixed(8),
          );
          subs[subIndex] = sp.copyWith(
            sizeInAsset: newSize,
            sizeInWalletCurrency: double.parse(
              (newSize * sp.entryPrice).toStringAsFixed(2),
            ),
          );
        }
        return p.copyWith(subPositions: subs);
      }).toList();

      // Build history entry.
      final posAfter = newPositions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => Position(ticker: '', maximumAllowedRisk: 0),
      );
      final afterPct = posAfter.currentSizePercent();
      final delta = double.parse((afterPct - beforePct).toStringAsFixed(2));
      final deltaSign = delta >= 0 ? '+' : '';
      final percentRemoved = isPercent
          ? double.parse(amountInAssetOrPct.toStringAsFixed(2))
          : (spBeforeSize == 0
                ? 0.0
                : double.parse(
                    (amountInAssetOrPct / spBeforeSize * 100).toStringAsFixed(
                      2,
                    ),
                  ));
      final toRemoveUnits = isPercent
          ? amountInAssetOrPct / 100.0 * spBeforeSize
          : amountInAssetOrPct;
      final desc =
          'Reduced subposition ${posAfter.ticker}[$subIndex] by ${percentRemoved}% (units=${toRemoveUnits.toStringAsFixed(8)}) — pos ${beforePct}% -> ${afterPct}% (Δ ${deltaSign}${delta}%)';
      final extra =
          'ticker=${posAfter.ticker};timeframe=${posAfter.timeframe};subPct=${percentRemoved.toStringAsFixed(2)};posBefore=${beforePct.toStringAsFixed(2)};posAfter=${afterPct.toStringAsFixed(2)};delta=${delta.toStringAsFixed(2)}';

      final newHistory = [
        ...w.history,
        WalletAction(
          id: '${posAfter.ticker}_$spOpenedAt',
          type: ActionType.reduceSubposition,
          description: desc,
          extra: extra,
        ),
      ];
      return w.copyWith(positions: newPositions, history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }

  void removeSubposition(String walletId, String positionId, int subIndex) {
    _wallets = _wallets.map((w) {
      if (w.id != walletId) return w;
      final newPositions = w.positions.map((p) {
        if (p.id != positionId) return p;
        final subs = List<SubPosition>.from(p.subPositions);
        if (subIndex >= 0 && subIndex < subs.length) subs.removeAt(subIndex);
        return p.copyWith(subPositions: subs);
      }).toList();
      final pos = w.positions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => Position(ticker: '', maximumAllowedRisk: 0),
      );
      final tf = pos.timeframe.isEmpty ? '' : '-${pos.timeframe}';
      final desc = pos.ticker.isNotEmpty
          ? 'Removed subposition ${pos.ticker}$tf[$subIndex]'
          : 'Removed subposition $positionId[$subIndex]';
      final newHistory = [
        ...w.history,
        WalletAction(type: ActionType.removeSubposition, description: desc),
      ];
      return w.copyWith(positions: newPositions, history: newHistory);
    }).toList();
    notifyListeners();
    _persist();
  }
}
