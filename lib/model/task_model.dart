class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final int isCompleted;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.dueDate,
    this.isCompleted = 0,
  });

  // Database eken gaddi (String eka aye DateTime karanna oni)
  factory Task.fromMap(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: DateTime.parse(json['dueDate']),
    isCompleted: json['isCompleted'],
  );

  // Database ekata daddi (DateTime eka String karanna oni)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
