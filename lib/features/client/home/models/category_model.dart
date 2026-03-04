class JobCategory {
  final int id;
  final String name;
  final String icon;
  final String? backendKey; 
  // backendKey → backend-тен фильтрге қолдануға болады

  const JobCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.backendKey,
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      backendKey: json['backendKey'],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "icon": icon,
        "backendKey": backendKey,
      };
}

// ДАЙЫН КАТЕГОРИЯЛАР
const List<JobCategory> jobCategories = [
  JobCategory(id: 1, name: "Крыша жабу", icon: "🏠", backendKey: "roof"),
  JobCategory(id: 2, name: "Электрик", icon: "⚡", backendKey: "electric"),
  JobCategory(id: 3, name: "Сантехник", icon: "💧", backendKey: "plumber"),
  JobCategory(id: 4, name: "Сварка", icon: "🔥", backendKey: "welding"),
  JobCategory(id: 5, name: "Бетон / Стяжка", icon: "🧱", backendKey: "concrete"),
  JobCategory(id: 6, name: "Бұзу жұмыстары", icon: "🔨", backendKey: "demolition"),
];
