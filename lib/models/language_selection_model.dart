
class LanguageSelectionModel {
  final String languageCode;
  final String languageName;
  final String nativeName;

  const LanguageSelectionModel({
    required this.languageCode,
    required this.languageName,
    required this.nativeName,
  });

  static const List<LanguageSelectionModel> supportedLanguages = [
    LanguageSelectionModel(
      languageCode: 'en',
      languageName: 'English',
      nativeName: 'English',
    ),
    LanguageSelectionModel(
      languageCode: 'te',
      languageName: 'Telugu',
      nativeName: 'తెలుగు',
    ),
    LanguageSelectionModel(
      languageCode: 'hi',
      languageName: 'Hindi',
      nativeName: 'हिन्दी',
    ),
  ];
}