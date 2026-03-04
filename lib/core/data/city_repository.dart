class CityRepository {
  static const List<String> _cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Қарағанды',
    'Ақтөбе',
    'Тараз',
    'Павлодар',
    'Өскемен',
    'Атырау',
    'Ақтау',
    'Қостанай',
    'Қызылорда',
    'Түркістан',
    'Семей',
    'Көкшетау',
    'Талдықорған',
    'Петропавл',
    'Жезқазған',
    'Орал',
    'Екібастұз',
  ];

  static List<String> all() => List<String>.from(_cities);

  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all();
    return _cities.where((c) => c.toLowerCase().contains(q)).toList();
  }
}
