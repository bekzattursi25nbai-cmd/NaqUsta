class UserModel {
  final String id;
  final String name;
  final String role; // 'worker' or 'client'
  final bool isVerified;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.isVerified = false,
    this.avatarUrl,
  });

  // Кейін Firebase-пен жұмыс істегенде керек болады
  factory UserModel.dummy() {
    return UserModel(
      id: '123',
      name: 'Бекзат Аманов',
      role: 'worker',
      isVerified: true,
    );
  }
}