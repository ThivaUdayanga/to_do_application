class SettingsModel {
  final int? id;
  final int ownerId;
  final int deleteBlockTime;
  final int maxTasksPerDay;

  SettingsModel({
    this.id,
    required this.ownerId,
    required this.deleteBlockTime,
    required this.maxTasksPerDay,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      ownerId: map['ownerId'] as int,
      deleteBlockTime: map['deleteBlockTime'] as int,
      maxTasksPerDay: map['maxTasksPerDay'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'deleteBlockTime': deleteBlockTime,
      'maxTasksPerDay': maxTasksPerDay,
    };
  }
}
