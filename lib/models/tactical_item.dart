import 'dart:ui';

/// Enum representing the different types of items that can be placed on the tactical board.
enum ItemType {
  redPlayer,
  whitePlayer,
  cone,
  ball,
  text,
}

/// Enum for text sizes.
enum TextSize {
  small,
  medium,
  large,
}

/// Data model for items placed on the tactical board.
class TacticalItem {
  final String id;
  final ItemType type;
  Offset position;
  String label;
  String name;  // Player name displayed above the token
  TextSize textSize;

  TacticalItem({
    required this.id,
    required this.type,
    required this.position,
    this.label = '',
    this.name = '',
    this.textSize = TextSize.medium,
  });

  /// Creates a copy of this item with optional new values.
  TacticalItem copyWith({
    String? id,
    ItemType? type,
    Offset? position,
    String? label,
    String? name,
    TextSize? textSize,
  }) {
    return TacticalItem(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      label: label ?? this.label,
      name: name ?? this.name,
      textSize: textSize ?? this.textSize,
    );
  }
}
