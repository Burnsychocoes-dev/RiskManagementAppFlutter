import 'package:uuid/uuid.dart';
import 'position.dart';
import 'wallet_action.dart';

/// Wallet model with a unique UUID id and a display name.
class Wallet {
  final String id;
  final String name;
  double balance;
  double walletMaxRisk;
  final String currency;
  final List<Position> positions;
  final List<WalletAction> history;

  Wallet({
    String? id,
    required this.name,
    this.balance = 0.0,
    this.walletMaxRisk = 0.0,
    this.currency = '\$',
    List<Position>? positions,
    List<WalletAction>? history,
  }) : id = id ?? const Uuid().v4(),
       positions = positions ?? [],
       history = history ?? [];

  double totalRisk() {
    final total = positions.fold(0.0, (acc, p) => acc + p.totalCurrentRisk());
    return double.parse(total.toStringAsFixed(2));
  }

  double totalMaxRisk() {
    final total = positions.fold(0.0, (acc, p) => acc + p.maximumAllowedRisk);
    return double.parse(total.toStringAsFixed(2));
  }

  double remainingMaxRisk() {
    return double.parse((walletMaxRisk - totalMaxRisk()).toStringAsFixed(2));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'walletMaxRisk': walletMaxRisk,
    'currency': currency,
    'positions': positions.map((p) => p.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
  };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      walletMaxRisk:
          (json['walletMaxRisk'] as num?)?.toDouble() ??
          (json['balance'] as num?)?.toDouble() ??
          0.0,
      currency: json['currency'] as String? ?? '\$',
      positions: (json['positions'] as List<dynamic>? ?? [])
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => WalletAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    double? walletMaxRisk,
    String? currency,
    List<Position>? positions,
    List<WalletAction>? history,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
    walletMaxRisk: walletMaxRisk ?? this.walletMaxRisk,
    currency: currency ?? this.currency,
    positions: positions ?? List.from(this.positions),
    history: history ?? List.from(this.history),
  );
}
