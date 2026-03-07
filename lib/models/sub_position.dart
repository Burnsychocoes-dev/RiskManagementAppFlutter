import 'direction.dart';

/// Represents a single sub-position (part of a position).
/// All monetary values are doubles rounded to 2 decimal places where appropriate.
/// Stop-loss is represented as an absolute price per asset unit.
class SubPosition {
  final double entryPrice;
  final Direction direction;
  double sizeInAsset;
  double sizeInWalletCurrency;
  final double? targetPrice;
  final double stopLossPrice;
  final int openedAtMillis;

  SubPosition({
    required this.entryPrice,
    required this.direction,
    required this.sizeInAsset,
    required this.sizeInWalletCurrency,
    this.targetPrice,
    required this.stopLossPrice,
    int? openedAtMillis,
  }) : openedAtMillis = openedAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  /// Current risk in wallet fiat currency:
  /// sizeInAsset * abs(entryPrice - stopLossPrice)
  double currentRisk() {
    return double.parse(
      (sizeInAsset * (entryPrice - stopLossPrice).abs()).toStringAsFixed(2),
    );
  }

  Map<String, dynamic> toJson() => {
    'entryPrice': entryPrice,
    'direction': direction.toJson(),
    'sizeInAsset': sizeInAsset,
    'sizeInWalletCurrency': sizeInWalletCurrency,
    'targetPrice': targetPrice,
    'stopLossPrice': stopLossPrice,
    'openedAtMillis': openedAtMillis,
  };

  factory SubPosition.fromJson(Map<String, dynamic> json) => SubPosition(
    entryPrice: (json['entryPrice'] as num).toDouble(),
    direction: Direction.fromJson(json['direction'] as String? ?? 'LONG'),
    sizeInAsset: (json['sizeInAsset'] as num).toDouble(),
    sizeInWalletCurrency: (json['sizeInWalletCurrency'] as num).toDouble(),
    targetPrice: json['targetPrice'] != null
        ? (json['targetPrice'] as num).toDouble()
        : null,
    stopLossPrice: (json['stopLossPrice'] as num).toDouble(),
    openedAtMillis:
        json['openedAtMillis'] as int? ?? DateTime.now().millisecondsSinceEpoch,
  );

  SubPosition copyWith({
    double? entryPrice,
    Direction? direction,
    double? sizeInAsset,
    double? sizeInWalletCurrency,
    double? targetPrice,
    double? stopLossPrice,
    int? openedAtMillis,
  }) => SubPosition(
    entryPrice: entryPrice ?? this.entryPrice,
    direction: direction ?? this.direction,
    sizeInAsset: sizeInAsset ?? this.sizeInAsset,
    sizeInWalletCurrency: sizeInWalletCurrency ?? this.sizeInWalletCurrency,
    targetPrice: targetPrice ?? this.targetPrice,
    stopLossPrice: stopLossPrice ?? this.stopLossPrice,
    openedAtMillis: openedAtMillis ?? this.openedAtMillis,
  );
}
