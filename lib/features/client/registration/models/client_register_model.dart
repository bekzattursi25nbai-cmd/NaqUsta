import 'package:kuryl_kz/features/location/models/kato_models.dart';

class ClientRegisterModel {
  String name = '';
  String phone = '';
  String city = '';
  String address = '';
  String addressType = '';
  String floor = '';
  int age = 0;
  List<String> interests = [];
  LocationBreakdown? location;

  Map<String, dynamic> toMap() {
    final payload = <String, dynamic>{
      'name': name,
      'fullName': name,
      'phone': phone,
      'city': location?.shortLabel ?? city,
      'address': address,
      'address_type': addressType,
      'floor': floor,
      'age': age,
      'interests': interests,
    };

    final selectedLocation = location;
    if (selectedLocation != null && selectedLocation.isValid) {
      payload['location'] = selectedLocation.toFirestoreMap();
      payload.addAll(selectedLocation.toDenormalizedFields());
      payload['city'] = selectedLocation.shortLabel;
    }

    return payload;
  }

  @override
  String toString() {
    return 'ClientData(name: $name, phone: $phone, city: $city, age: $age, interests: $interests, address: $address)';
  }
}
