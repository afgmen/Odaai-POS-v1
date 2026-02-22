import '../../domain/enums/delivery_platform.dart';
import '../../domain/enums/delivery_status.dart';

/// Unified delivery order model — mirrors the server-side DeliveryOrder model.
class DeliveryOrder {
  final String id;
  final String platformOrderId;
  final DeliveryPlatform platform;
  final DeliveryStatus status;
  final String customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final List<DeliveryOrderItem> items;
  final double totalAmount;
  final String? specialInstructions;
  final DateTime? estimatedPickupTime;
  final DeliveryDriverInfo? driverInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryOrder({
    required this.id,
    required this.platformOrderId,
    required this.platform,
    required this.status,
    required this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    this.specialInstructions,
    this.estimatedPickupTime,
    this.driverInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  DeliveryOrder copyWith({
    String? id,
    String? platformOrderId,
    DeliveryPlatform? platform,
    DeliveryStatus? status,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<DeliveryOrderItem>? items,
    double? totalAmount,
    String? specialInstructions,
    DateTime? estimatedPickupTime,
    DeliveryDriverInfo? driverInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      platformOrderId: platformOrderId ?? this.platformOrderId,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      driverInfo: driverInfo ?? this.driverInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    return DeliveryOrder(
      id: json['id'] as String,
      platformOrderId: json['platformOrderId'] as String? ?? '',
      platform: DeliveryPlatform.fromString(json['platform'] as String? ?? 'manual'),
      status: DeliveryStatus.fromString(json['status'] as String? ?? 'NEW'),
      customerName: json['customerName'] as String? ?? 'Unknown',
      customerPhone: json['customerPhone'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DeliveryOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      specialInstructions: json['specialInstructions'] as String?,
      estimatedPickupTime: json['estimatedPickupTime'] != null
          ? DateTime.tryParse(json['estimatedPickupTime'] as String)
          : null,
      driverInfo: json['driverInfo'] != null
          ? DeliveryDriverInfo.fromJson(json['driverInfo'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platformOrderId': platformOrderId,
        'platform': platform.value,
        'status': status.value,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'specialInstructions': specialInstructions,
        'estimatedPickupTime': estimatedPickupTime?.toIso8601String(),
        'driverInfo': driverInfo?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Total number of items in the order.
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Elapsed time since order was created.
  Duration get elapsed => DateTime.now().difference(createdAt);

  /// Elapsed time in minutes.
  int get elapsedMinutes => elapsed.inMinutes;
}

/// An item within a delivery order.
class DeliveryOrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  const DeliveryOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  factory DeliveryOrderItem.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'notes': notes,
      };
}

/// Driver info attached to a delivery order.
class DeliveryDriverInfo {
  final String name;
  final String phone;
  final String licensePlate;

  const DeliveryDriverInfo({
    required this.name,
    required this.phone,
    required this.licensePlate,
  });

  factory DeliveryDriverInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryDriverInfo(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'licensePlate': licensePlate,
      };
}
