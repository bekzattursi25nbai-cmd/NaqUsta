// lib/features/request/controllers/request_form_state.dart

import 'package:flutter/material.dart';
import '../models/category_model.dart';

class RequestFormState extends ChangeNotifier {
  // --------------------------
  // 1) CATEGORY
  // --------------------------
  JobCategory? selectedCategory;

  void setCategory(JobCategory category) {
    selectedCategory = category;
    notifyListeners();
  }

  // --------------------------
  // 2) JOB TITLE
  // --------------------------
  String jobTitle = "";
  void setJobTitle(String v) {
    jobTitle = v;
    notifyListeners();
  }

  // --------------------------
  // 3) AREA / QUANTITY
  // --------------------------
  String area = "";
  void setArea(String v) {
    area = v;
    notifyListeners();
  }

  // --------------------------
  // 4) DESCRIPTION
  // --------------------------
  String description = "";
  void setDescription(String v) {
    description = v;
    notifyListeners();
  }

  // --------------------------
  // 5) PRICE
  // --------------------------
  String price = "";
  bool isNegotiable = false;

  void setPrice(String v) {
    price = v;
    notifyListeners();
  }

  void toggleNegotiable() {
    isNegotiable = !isNegotiable;
    notifyListeners();
  }

  // --------------------------
  // 6) MATERIALS
  // --------------------------
  String materialBy = "worker"; // worker or client

  void setMaterialBy(String v) {
    materialBy = v;
    notifyListeners();
  }

  // --------------------------
  // 7) DURATION
  // --------------------------
  String duration = ""; // days

  void setDuration(String v) {
    duration = v;
    notifyListeners();
  }

  // --------------------------
  // 8) LOCATION
  // --------------------------
  String address = ""; 

  void setAddress(String v) {
    address = v;
    notifyListeners();
  }

  // --------------------------
  // 9) CONTACT METHOD
  // --------------------------
  String contactMethod = "call"; // call / chat / whatsapp
  String phoneNumber = "";

  void setContactMethod(String m) {
    contactMethod = m;
    notifyListeners();
  }

  void setPhone(String v) {
    phoneNumber = v;
    notifyListeners();
  }

  // --------------------------
  // 10) VALIDATION (Қажет болса)
  // --------------------------
  bool isValid() {
    return selectedCategory != null &&
        jobTitle.isNotEmpty &&
        description.isNotEmpty &&
        (isNegotiable || price.isNotEmpty) &&
        address.isNotEmpty &&
        (contactMethod == "chat" || phoneNumber.isNotEmpty);
  }

  // --------------------------
  // 11) BUILD JSON
  // --------------------------
  Map<String, dynamic> toJson() {
    return {
      "category": selectedCategory?.name,
      "jobTitle": jobTitle,
      "area": area,
      "description": description,
      "price": isNegotiable ? "Келісімді" : price,
      "materialBy": materialBy,
      "duration": duration,
      "address": address,
      "contactMethod": contactMethod,
      "phone": phoneNumber,
    };
  }
}
