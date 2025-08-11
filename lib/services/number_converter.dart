// lib/services/number_converter.dart

String convertPersianDigitsToEnglish(String input) {
  const persianDigits = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  const englishDigits = ['0','1','2','3','4','5','6','7','8','9'];

  for (int i = 0; i < persianDigits.length; i++) {
    input = input.replaceAll(persianDigits[i], englishDigits[i]);
  }
  return input;
}

String convertEnglishDigitsToPersian(String input) {
  const englishDigits = ['0','1','2','3','4','5','6','7','8','9'];
  const persianDigits = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];

  for (int i = 0; i < englishDigits.length; i++) {
    input = input.replaceAll(englishDigits[i], persianDigits[i]);
  }
  return input;
}
