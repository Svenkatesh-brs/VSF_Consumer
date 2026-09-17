import 'storage_service.dart';

class LanguageSelectionService {
  final StorageService _storageService;

  LanguageSelectionService({
    required StorageService storageService,
  }) : _storageService = storageService;

  Future<String?> getSavedLanguageCode() {
    return _storageService.getLanguageCode();
  }

  Future<void> saveLanguageCode(String languageCode) {
    return _storageService.saveLanguageCode(languageCode);
  }
}