import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthProvider extends GetxController {
  final mobileController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool validateMobileNumber() {
    final mobileNumber = mobileController.text.trim();

    if (mobileNumber.isEmpty) {
      errorMessage.value = 'Please enter your mobile number.';
      return false;
    }

    if (mobileNumber.length != 10) {
      errorMessage.value =
          'Please enter a valid 10-digit mobile number.';
      return false;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
      errorMessage.value =
          'Please enter a valid 10-digit mobile number.';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  void clearError() {
    errorMessage.value = null;
  }

  @override
  void onClose() {
    mobileController.dispose();
    super.onClose();
  }
}