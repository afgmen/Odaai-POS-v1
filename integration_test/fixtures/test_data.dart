/// Test data fixtures for integration tests
class TestData {
  // Products
  static const String testSKU = 'TEST001';
  static const String testProductName = 'Test Potato Chips';
  static const String testBarcode = '4000386123457';
  static const double testPrice = 10000;
  static const double testCost = 7000;
  static const int testStock = 30;

  // Customers
  static const String testCustomerName = 'Test Customer';
  static const String testCustomerPhone = '0901234567';
  static const String testCustomerEmail = 'test@example.com';
  static const int testCustomerPoints = 1000;

  // Discounts
  static const double testDiscountPercent = 10.0;
  static const double testDiscountAmount = 5000;

  // Orders
  static const String testOrderCode = 'ORD-20260307-001';
  static const int testOrderQuantity = 5;

  // Search
  static const String searchKeyword = 'Potato';
  static const String searchCategory = 'Snacks';

  // Refund
  static const String refundReason = 'Test refund';
  static const double refundAmount = 10000;
}
