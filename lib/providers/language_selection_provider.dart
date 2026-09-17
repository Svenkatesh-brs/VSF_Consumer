
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/language_selection_model.dart';
import '../services/language_selection_service.dart';

class LanguageSelectionProvider extends GetxController {
  final LanguageSelectionService _languageService;

  LanguageSelectionProvider({
    required LanguageSelectionService languageService,
  }) : _languageService = languageService;

  final Rx<Locale> _locale = const Locale('en', 'US').obs;
  final RxBool isLoading = true.obs;

  Locale get locale => _locale.value;

  String get languageCode => _locale.value.languageCode;

  // Load the saved language during app startup.
  Future<void> loadSavedLanguage() async {
    isLoading.value = true;

    try {
      final savedCode =
          await _languageService.getSavedLanguageCode();

      final language = LanguageSelectionModel.supportedLanguages
          .where((item) => item.languageCode == savedCode)
          .firstOrNull;

      if (language != null) {
        _locale.value = _localeFor(language.languageCode);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Change language and save the selection.
  Future<void> changeLanguage(String languageCode) async {
    final isSupported = LanguageSelectionModel.supportedLanguages
        .any((item) => item.languageCode == languageCode);

    if (!isSupported) return;

    final newLocale = _localeFor(languageCode);

    _locale.value = newLocale;
    Get.updateLocale(newLocale);

    await _languageService.saveLanguageCode(languageCode);
  }

  Locale _localeFor(String code) {
    switch (code) {
      case 'te':
        return const Locale('te', 'IN');
      case 'hi':
        return const Locale('hi', 'IN');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
}