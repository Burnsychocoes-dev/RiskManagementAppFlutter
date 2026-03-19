import 'package:uuid/uuid.dart';
import 'direction.dart';
import 'sub_position.dart';

/// Represents an aggregated position composed of multiple sub-positions.
/// [maximumAllowedRisk] is expressed in wallet fiat currency (2 decimal places).
class Position {
  final String id;
  final String ticker;
  final String timeframe;
  final int createdAtMillis;
  final Direction direction;
  final List<SubPosition> subPositions;
  final double? stopLossPrice;
  final double maximumAllowedRisk;
  final double? targetPrice;

  Position({
    String? id,
    required this.ticker,
    this.timeframe = '',
    int? createdAtMillis,
    this.direction = Direction.long,
    List<SubPosition>? subPositions,
    this.stopLossPrice,
    required this.maximumAllowedRisk,
    this.targetPrice,
  }) : id = id ?? const Uuid().v4(),
       createdAtMillis =
           createdAtMillis ?? DateTime.now().millisecondsSinceEpoch,
       subPositions = subPositions ?? [];

  /// Weighted average entry price across sub-positions.
  double averageEntryPrice() {
    final totalUnits = subPositions.fold(0.0, (acc, s) => acc + s.sizeInAsset);
    if (totalUnits == 0.0) return 0.0;
    final totalCost = subPositions.fold(
      0.0,
      (acc, s) => acc + s.entryPrice * s.sizeInAsset,
    );
    return double.parse((totalCost / totalUnits).toStringAsFixed(2));
  }

  /// Lower bound for stop-loss on a LONG:
  /// the stop at which totalCurrentRisk would equal maximumAllowedRisk.
  /// Returns null if no subpositions exist.
  double? minStopLossLong() {
    final totalUnits = subPositions.fold(0.0, (acc, s) => acc + s.sizeInAsset);
    if (totalUnits == 0.0) return null;
    final avg = averageEntryPrice();
    return double.parse(
      (avg - maximumAllowedRisk / totalUnits).toStringAsFixed(8),
    );
  }

  /// Upper bound for stop-loss on a SHORT:
  /// the stop at which totalCurrentRisk would equal maximumAllowedRisk.
  /// Returns null if no subpositions exist.
  double? maxStopLossShort() {
    final totalUnits = subPositions.fold(0.0, (acc, s) => acc + s.sizeInAsset);
    if (totalUnits == 0.0) return null;
    final avg = averageEntryPrice();
    return double.parse(
      (avg + maximumAllowedRisk / totalUnits).toStringAsFixed(8),
    );
  }

  double totalCurrentRisk() {
    final total = subPositions.fold(0.0, (acc, s) => acc + s.currentRisk());
    return double.parse(total.toStringAsFixed(2));
  }

  /// Current used risk as a percentage of [maximumAllowedRisk] (0..100).
  double currentSizePercent() {
    if (maximumAllowedRisk == 0.0) return 0.0;
    return double.parse(
      (totalCurrentRisk() / maximumAllowedRisk * 100).toStringAsFixed(2),
    );
  }

  /// Reward-to-risk ratio based on position-level targetPrice and average entry.
  double? rr() {
    final avg = averageEntryPrice();
    if (targetPrice == null || stopLossPrice == null) return null;
    final rewardPerUnit = (targetPrice! - avg).abs();
    final riskPerUnit = (avg - stopLossPrice!).abs();
    if (riskPerUnit == 0.0) return null;
    return double.parse((rewardPerUnit / riskPerUnit).toStringAsFixed(4));
  }

  void addSubPosition(SubPosition sub) {
    subPositions.add(sub);
  }

  /// Estimate the size (asset units, wallet currency) for a desired absolute risk.
  static (double sizeInAsset, double sizeInWalletCurrency) estimateSizeForRisk(
    double entryPrice,
    double stopLossPrice,
    double riskAmount,
  ) {
    final riskPerUnit = (entryPrice - stopLossPrice).abs();
    if (riskPerUnit == 0.0) return (0.0, 0.0);
    final sizeAsset = riskAmount / riskPerUnit;
    final sizeWallet = sizeAsset * entryPrice;
    return (
      double.parse(sizeAsset.toStringAsFixed(8)),
      double.parse(sizeWallet.toStringAsFixed(2)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticker': ticker,
    'timeframe': timeframe,
    'createdAtMillis': createdAtMillis,
    'direction': direction.toJson(),
    'subPositions': subPositions.map((s) => s.toJson()).toList(),
    'stopLossPrice': stopLossPrice,
    'maximumAllowedRisk': maximumAllowedRisk,
    'targetPrice': targetPrice,
  };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: json['id'] as String? ?? const Uuid().v4(),
    ticker: json['ticker'] as String? ?? '',
    timeframe: json['timeframe'] as String? ?? '',
    createdAtMillis:
        json['createdAtMillis'] as int? ??
        DateTime.now().millisecondsSinceEpoch,
    direction: Direction.fromJson(json['direction'] as String? ?? 'LONG'),
    subPositions: (json['subPositions'] as List<dynamic>? ?? [])
        .map((e) => SubPosition.fromJson(e as Map<String, dynamic>))
        .toList(),
    stopLossPrice: json['stopLossPrice'] != null
        ? (json['stopLossPrice'] as num).toDouble()
        : null,
    maximumAllowedRisk: (json['maximumAllowedRisk'] as num).toDouble(),
    targetPrice: json['targetPrice'] != null
        ? (json['targetPrice'] as num).toDouble()
        : null,
  );

  Position copyWith({
    String? id,
    String? ticker,
    String? timeframe,
    int? createdAtMillis,
    Direction? direction,
    List<SubPosition>? subPositions,
    double? stopLossPrice,
    double? maximumAllowedRisk,
    double? targetPrice,
  }) => Position(
    id: id ?? this.id,
    ticker: ticker ?? this.ticker,
    timeframe: timeframe ?? this.timeframe,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    direction: direction ?? this.direction,
    subPositions: subPositions ?? List.from(this.subPositions),
    stopLossPrice: stopLossPrice ?? this.stopLossPrice,
    maximumAllowedRisk: maximumAllowedRisk ?? this.maximumAllowedRisk,
    targetPrice: targetPrice ?? this.targetPrice,
  );
}
