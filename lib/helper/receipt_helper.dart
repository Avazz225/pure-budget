final amountRegex = RegExp(
  r'(\d+[.,]\d{1,2})\s?(EUR|€|USD|\$|GBP|£|BRL|R\$|PLN|zł|RUB|₽|TRY|₺|JPY|¥|CNY|元|KRW|₩)',
  caseSensitive: false,
);
final merchantRegex = RegExp(
  r'^[\p{L}0-9 .,&-]{3,}$',
  multiLine: true,
  unicode: true,
);
const Map<String, double> defaultConversionRates = {
  'EUR': 1.05,   // euro
  'USD': 1.0,    // us dollar
  'BRL': 0.19,   // brasilian real
  'PLN': 0.23,   // ploish zloty
  'RUB': 0.013,  // russian rubel
  'TRY': 0.054,  // turkish lira
  'GBP': 1.22,   // british pound
  'JPY': 0.0072, // japanese yen
  'CNY': 0.14,   // chinese yuan
  'KRW': 0.00076 // south korean won
};

// Helperfunction: Curency symbol to ISO
String normalizeCurrency(String symbolOrCode) {
  switch (symbolOrCode) {
    case '€':
      return 'EUR';
    case '\$':
      return 'USD';
    case 'R\$':
      return 'BRL';
    case 'zł':
      return 'PLN';
    case '₽':
      return 'RUB';
    case '₺':
      return 'TRY';
    case '£':
      return 'GBP';
    case '¥':
      return 'JPY';
    case '元':
      return 'CNY';
    case '₩':
      return 'KRW';
    default:
      return symbolOrCode.toUpperCase(); // fallback to ISO-C´code
  }
}