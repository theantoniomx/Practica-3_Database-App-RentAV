class Rent {
  final int? id;
  final String title;
  final String startDate;
  final String endDate;
  final String status;
  final String reminderDate;
  final int userId;

  Rent({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reminderDate,
    required this.userId,
  });

  factory Rent.fromMap(Map<String, dynamic> map) {
    return Rent(
      id: map['id'],
      title: map['title'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      status: map['status'],
      reminderDate: map['reminderDate'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'reminderDate': reminderDate,
      'userId': userId,
    };
  }
}
