enum StudentStatus {
  waiting,
  onboard,
  droppedOff,
  absent;

  static StudentStatus fromString(String? value) =>
      StudentStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => StudentStatus.waiting,
      );

  String get label => switch (this) {
        StudentStatus.waiting => 'Waiting',
        StudentStatus.onboard => 'On board',
        StudentStatus.droppedOff => 'Dropped off',
        StudentStatus.absent => 'Absent',
      };
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.parentId,
    this.school,
    this.pickupAddress,
    this.photoUrl,
    this.status = StudentStatus.waiting,
  });

  final String id;
  final String name;
  final String grade;
  final String parentId;
  final String? school;
  final String? pickupAddress;
  final String? photoUrl;
  final StudentStatus status;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        parentId: json['parentId'].toString(),
        school: json['school'] as String?,
        pickupAddress: json['pickupAddress'] as String?,
        photoUrl: json['photoUrl'] as String?,
        status: StudentStatus.fromString(json['status'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'parentId': parentId,
        'school': school,
        'pickupAddress': pickupAddress,
        'photoUrl': photoUrl,
        'status': status.name,
      };

  Student copyWith({StudentStatus? status}) => Student(
        id: id,
        name: name,
        grade: grade,
        parentId: parentId,
        school: school,
        pickupAddress: pickupAddress,
        photoUrl: photoUrl,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Student && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
