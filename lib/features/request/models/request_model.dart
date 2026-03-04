// lib/features/request/models/request_model.dart

class RequestModel {
  final String id;
  final String title;          // жұмыс атауы
  final String category;       // категория
  final String price;          // бағасы
  final String location;       // мекенжай
  final String date;           // уақыты
  final String imageUrl;       // суреті (бар болса)
  
  // Қосымша өрістер
  final String area;
  final String description;
  final bool isNegotiable;
  final String materialBy;
  final String duration;
  final String contactMethod;
  final String phoneNumber;

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
  });
}