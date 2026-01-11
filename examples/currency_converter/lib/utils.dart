String formatCurrency(String value) {
  if (value.isEmpty) return '0';

  // Handle decimal numbers
  final parts = value.split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

  // Add commas to integer part
  String formattedInteger = '';
  for (int i = 0; i < integerPart.length; i++) {
    if (i > 0 && (integerPart.length - i) % 3 == 0) {
      formattedInteger += ',';
    }
    formattedInteger += integerPart[i];
  }

  return formattedInteger + decimalPart;
}
