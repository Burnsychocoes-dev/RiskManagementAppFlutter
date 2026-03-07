import 'package:uuid/uuid.dart';

enum ActionType {
  addPosition,
  addSubposition,
  reduceSubposition,
  removeSubposition,
  closePosition,
  updateWalletMax;

  String toJson() {
    switch (this) {
      case ActionType.addPosition:
        return 'ADD_POSITION';
      case ActionType.addSubposition:
        return 'ADD_SUBPOSITION';
      case ActionType.reduceSubposition:
        return 'REDUCE_SUBPOSITION';
      case ActionType.removeSubposition:
        return 'REMOVE_SUBPOSITION';
      case ActionType.closePosition:
        return 'CLOSE_POSITION';
      case ActionType.updateWalletMax:
        return 'UPDATE_WALLET_MAX';
    }
  }

  static ActionType fromJson(String value) {
    switch (value) {
      case 'ADD_SUBPOSITION':
        return ActionType.addSubposition;
      case 'REDUCE_SUBPOSITION':
        return ActionType.reduceSubposition;
      case 'REMOVE_SUBPOSITION':
        return ActionType.removeSubposition;
      case 'CLOSE_POSITION':
        return ActionType.closePosition;
      case 'UPDATE_WALLET_MAX':
        return ActionType.updateWalletMax;
      default:
        return ActionType.addPosition;
    }
  }
}

/// Simple wallet action/event record for auditing/history UI.
class WalletAction {
  final String id;
  final ActionType type;
  final int timestampMillis;
  final String description;
  final String? extra;

  WalletAction({
    String? id,
    required this.type,
    int? timestampMillis,
    required this.description,
    this.extra,
  }) : id = id ?? const Uuid().v4(),
       timestampMillis =
           timestampMillis ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'timestampMillis': timestampMillis,
    'description': description,
    'extra': extra,
  };

  factory WalletAction.fromJson(Map<String, dynamic> json) => WalletAction(
    id: json['id'] as String? ?? const Uuid().v4(),
    type: ActionType.fromJson(json['type'] as String? ?? 'ADD_POSITION'),
    timestampMillis:
        json['timestampMillis'] as int? ??
        DateTime.now().millisecondsSinceEpoch,
    description: json['description'] as String? ?? '',
    extra: json['extra'] as String?,
  );
}
