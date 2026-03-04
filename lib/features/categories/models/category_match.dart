enum CategoryMatchType { primary, canDo, other }

extension CategoryMatchTypeX on CategoryMatchType {
  int get rank {
    switch (this) {
      case CategoryMatchType.primary:
        return 0;
      case CategoryMatchType.canDo:
        return 1;
      case CategoryMatchType.other:
        return 2;
    }
  }

  String get badgeLabel {
    switch (this) {
      case CategoryMatchType.primary:
        return 'Негізгі мамандық';
      case CategoryMatchType.canDo:
        return 'Қосымша жасай алады';
      case CategoryMatchType.other:
        return 'Басқа';
    }
  }
}
