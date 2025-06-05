class Category {
  final int? id;
  final String name;
  final String imagePath;

  Category({this.id, required this.name, required this.imagePath});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'imagePath': imagePath};
  }
}
