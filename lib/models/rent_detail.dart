class RentDetail {
  final int? id;
  final int rentId;
  final int equipmentId;
  final int quantity;

  RentDetail({
    this.id,
    required this.rentId,
    required this.equipmentId,
    required this.quantity,
  });

  factory RentDetail.fromMap(Map<String, dynamic> map) {
    return RentDetail(
      id: map['id'],
      rentId: map['rentId'],
      equipmentId: map['equipmentId'],
      quantity: map['quantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rentId': rentId,
      'equipmentId': equipmentId,
      'quantity': quantity,
    };
  }
}
