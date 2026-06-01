
class EPricingHelper {
  // Method to calculate total price
  static double calculateTotalPrice(double itemPrice, int quantity, double shippingCost) {
    return (itemPrice * quantity) + shippingCost;
  }

  // Method to calculate shipping cost based on weight and distance
  static double calculateShippingCost(double weight, double distance) {
    const double baseRate = 5.0; // Base rate for shipping
    const double weightRate = 0.5; // Rate per kilogram
    const double distanceRate = 0.1; // Rate per kilometer

    return baseRate + (weightRate * weight) + (distanceRate * distance);
  }
}