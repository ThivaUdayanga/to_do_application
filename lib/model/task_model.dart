class Task {
  final int? id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final int isCompleted;

  Task({
    this.id,
    required this.ownerId,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.dueDate,
    this.isCompleted = 0,
  });

  factory Task.fromMap(Map<String, dynamic> json) => Task(
    id: json['id'] as int?,
    ownerId: json['ownerId'] as String,
    title: json['title'] as String,
    description: (json['description'] ?? '') as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    isCompleted: json['isCompleted'] as int,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
