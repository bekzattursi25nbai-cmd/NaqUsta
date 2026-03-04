// lib/features/request/controllers/request_controller.dart

import 'package:flutter/material.dart';
import 'request_form_state.dart';

class RequestController extends ChangeNotifier {
  final RequestFormState form;

  RequestController(this.form);

  bool isLoading = false;
  bool isSubmitted = false;

  // ---------------------------------------------------------
  // SUBMIT REQUEST
  // ---------------------------------------------------------
  Future<bool> submit() async {
    // 1) Validate
    if (!form.isValid()) {
      debugPrint("❌ FORM INVALID");
      return false;
    }

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // simulation

    // 2) Convert to JSON (backend-ready)
    final data = form.toJson();
    debugPrint("📤 REQUEST SUBMITTED: $data");

    // 3) Server response simulation
    isLoading = false;
    isSubmitted = true;
    notifyListeners();

    return true;
  }

  // ---------------------------------------------------------
  // RESET FORM AFTER SUCCESS
  // ---------------------------------------------------------
  void reset() {
    form.selectedCategory = null;
    form.jobTitle = "";
    form.area = "";
    form.description = "";
    form.price = "";
    form.isNegotiable = false;
    form.materialBy = "worker";
    form.duration = "";
    form.address = "";
    form.contactMethod = "call";
    form.phoneNumber = "";

    isSubmitted = false;
    notifyListeners();
  }
}

