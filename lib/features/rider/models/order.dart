/// Rider order model (MVP — UI only, no backend).
class Order {
  const Order({
    required this.id,
    required this.shopName,
    required this.distanceKm,
    required this.earnings,
    required this.customerName,
    required this.deliveryAddress,
    required this.items,
  });

  final String id;
  final String shopName;
  final double distanceKm;
  final double earnings;
  final String customerName;
  final String deliveryAddress;
  final List<String> items;

  /// Fake order for MVP demo.
  static Order get fakeOrder => Order(
        id: 'ORD-2847',
        shopName: 'FreshMart',
        distanceKm: 2.3,
        earnings: 45.0,
        customerName: 'John Doe',
        deliveryAddress: '12, Green Valley Apartments, Sector 5',
        items: ['Milk 1L', 'Bread', 'Eggs x6', 'Butter 200g'],
      );
}
