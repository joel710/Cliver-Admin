class DeliveryPriceUtils {
  static String formatPrice(double price) {
    if (price == 0) return '0 FCFA';
    final roundedPrice = (price * 100).round() / 100;
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedPrice = roundedPrice.toStringAsFixed(0);
    formattedPrice = formattedPrice.replaceAllMapped(formatter, (Match m) => '${m[1]} ');
    return '$formattedPrice FCFA';
  }

  static double calculateBasePrice(double distanceKm) {
    const double basePricePerKm = 500;
    const double minimumPrice = 1000;
    final calculatedPrice = distanceKm * basePricePerKm;
    return calculatedPrice < minimumPrice ? minimumPrice : calculatedPrice;
  }

  static double calculatePlatformCommission(double totalPrice) {
    return totalPrice * 0.15;
  }

  static double calculateLivreurAmount(double totalPrice) {
    return totalPrice * 0.85;
  }

  static double parsePrice(String priceString) {
    try {
      final cleanString = priceString
          .replaceAll('FCFA', '')
          .replaceAll(' ', '')
          .trim();
      return double.parse(cleanString);
    } catch (e) {
      return 0.0;
    }
  }

  static bool isValidPrice(double price) {
    return price > 0 && price.isFinite;
  }

  static String formatPercentage(double percentage) {
    return '${(percentage * 100).toStringAsFixed(1)}%';
  }
}
