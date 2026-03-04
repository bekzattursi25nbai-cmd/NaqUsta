import 'package:flutter/material.dart';

// МАҢЫЗДЫ: Егер файлдарыңыз "features/client/request/models" ішінде болса:
import '../../client/request/models/request_model.dart';
// НЕМЕСЕ жай ғана "features/client/models" ішінде болса:
// import '../../client/models/request_model.dart'; 

class RequestService {
  static final RequestService _instance = RequestService._internal();
  factory RequestService() => _instance;
  RequestService._internal();

  final ValueNotifier<List<RequestModel>> requestsNotifier = ValueNotifier([
    RequestModel(
      id: "1",
      title: "Крыша жабу",
      category: "Құрылыс",
      price: "450 000 ₸",
      location: "Абай ауылы, 2км",
      date: "Қазір",
      imageUrl: "",
      area: "120 м2",
      description: "Профнастил жабу керек",
      isNegotiable: false,
      materialBy: "worker",
      duration: "5 күн",
      contactMethod: "call",
      phoneNumber: "87770000000",
    ),
  ]);

  void addRequest(RequestModel request) {
    final currentList = requestsNotifier.value;
    requestsNotifier.value = [request, ...currentList];
  }
}