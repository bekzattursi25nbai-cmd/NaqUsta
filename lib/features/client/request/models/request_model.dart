// lib/features/request/models/request_model.dart

class RequestModel {
  final String id;

  // UI fields
  final String title;          // жұмыс атауы
  final String category;       // категория аты
  final String price;          // 450 000 ₸
  final String location;       // Алматы, Медеу
  final String date;           // 2 сағат бұрын
  final String imageUrl;       // карточка суреті

  // Extra details (for RequestDetailsScreen)
  final String area;           // көлемі / саны
  final String description;    // сипаттама
  final bool isNegotiable;     // келісімді
  final String materialBy;     // worker/client
  final String duration;       // 5 күн
  final String contactMethod;  // call / chat / whatsapp
  final String phoneNumber;    // 8700...

  // Worker feed extra fields
  final String distance;       // 5 км
  final String responses;      // 12 ұсыныс

  RequestModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.date,
    required this.imageUrl,

    required this.area,
    required this.description,
    required this.isNegotiable,
    required this.materialBy,
    required this.duration,
    required this.contactMethod,
    required this.phoneNumber,

    this.distance = "0 км",
    this.responses = "0",
  });

  // -----------------------------
  // Convert to Map (API үшін)
  // -----------------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "category": category,
      "price": price,
      "location": location,
      "date": date,
      "imageUrl": imageUrl,
      "area": area,
      "description": description,
      "isNegotiable": isNegotiable,
      "materialBy": materialBy,
      "duration": duration,
      "contactMethod": contactMethod,
      "phoneNumber": phoneNumber,
      "distance": distance,
      "responses": responses,
    };
  }

  // -----------------------------
  // Convert from Map
  // -----------------------------
  factory RequestModel.fromMap(Map<String, dynamic> json) {
    return RequestModel(
      id: json["id"],
      title: json["title"],
      category: json["category"],
      price: json["price"],
      location: json["location"],
      date: json["date"],
      imageUrl: json["imageUrl"],
      area: json["area"],
      description: json["description"],
      isNegotiable: json["isNegotiable"],
      materialBy: json["materialBy"],
      duration: json["duration"],
      contactMethod: json["contactMethod"],
      phoneNumber: json["phoneNumber"],
      distance: json["distance"] ?? "0 км",
      responses: json["responses"] ?? "0",
    );
  }
}