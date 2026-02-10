class Task {
  final int? id;
  final int ownerId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final int isCompleted;

  Task({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      ownerId: (map['ownerId'] is int)
          ? map['ownerId'] as int
          : int.parse(map['ownerId'].toString()),
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: (map['isCompleted'] is int)
          ? map['isCompleted'] as int
          : int.parse(map['isCompleted'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId, // ✅ int saved to DB
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
