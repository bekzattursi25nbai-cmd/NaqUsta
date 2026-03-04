enum AuthRole {
  client,
  worker;

  String get value => this == AuthRole.client ? 'client' : 'worker';

  bool get isWorker => this == AuthRole.worker;

  String get label => this == AuthRole.client ? 'Тапсырыс беруші' : 'Шебер';

  static AuthRole? fromValue(String? raw) {
    switch (raw) {
      case 'client':
        return AuthRole.client;
      case 'worker':
        return AuthRole.worker;
      default:
        return null;
    }
  }

  static AuthRole fromIsWorker(bool isWorker) {
    return isWorker ? AuthRole.worker : AuthRole.client;
  }
}
