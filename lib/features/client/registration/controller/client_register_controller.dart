import 'package:flutter/foundation.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';
import '../models/client_register_model.dart';

class ClientRegisterController {
  final ClientRegisterModel data = ClientRegisterModel();

  void setName(String value) => data.name = value.trim();
  void setPhone(String value) => data.phone = value.trim();
  void setCity(String value) => data.city = value.trim();
  void setAddress(String value) => data.address = value.trim();
  void setAddressType(String value) => data.addressType = value;
  void setFloor(String value) => data.floor = value.trim();
  void setAge(int value) => data.age = value;
  void setInterests(List<String> value) => data.interests = value;
  void setLocation(LocationBreakdown? value) => data.location = value;

  ClientRegisterModel get model => data;

  void logData() {
    if (kDebugMode) {
      // ignore: avoid_print
      print("\n--------------------------------------------------");
      // ignore: avoid_print
      print("🚀 ЖАҢА КЛИЕНТ ТІРКЕЛДІ:");
      // ignore: avoid_print
      print("👤 Аты-жөні: ${data.name}");
      // ignore: avoid_print
      print("📞 Телефон: ${data.phone}");
      // ignore: avoid_print
      print("🏙 Қала: ${data.location?.shortLabel ?? data.city}");
      // ignore: avoid_print
      print("🎯 Қызығушылықтар: ${data.interests}");
      // ignore: avoid_print
      print("📍 Мекенжай: ${data.address}");
      // ignore: avoid_print
      print("--------------------------------------------------\n");
    }
  }
}
