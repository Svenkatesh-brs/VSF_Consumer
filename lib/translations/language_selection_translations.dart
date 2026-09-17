
import 'package:get/get.dart';

import 'language_selection_en.dart';
import 'language_selection_te.dart';
import 'language_selection_hi.dart';

class LanguageSelectionTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': languageSelectionEn,
        'te_IN': languageSelectionTe,
        'hi_IN': languageSelectionHi,
      };
}