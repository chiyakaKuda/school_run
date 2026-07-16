import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/student.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';

/// Manifest for a run. The driver marks each student on/off the vehicle.
class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key, this.tripId});

  final String? tripId;

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // TODO: load via ApiService.get(ApiConstants.students, query: {'tripId': ...}).
  final List<Student> _students = <Student>[];
  final bool _loading = false;

  Future<void> _cycleStatus(Student student) async {
    final next = switch (student.status) {
      StudentStatus.waiting => StudentStatus.onboard,
      StudentStatus.onboard => StudentStatus.droppedOff,
      StudentStatus.droppedOff || StudentStatus.absent => StudentStatus.waiting,
    };

    setState(() {
      final i = _students.indexOf(student);
      if (i != -1) _students[i] = student.copyWith(status: next);
    });
    // TODO: PATCH the new status so parents see it live.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.students)),
      body: switch ((_loading, _students.isEmpty)) {
        (true, _) => const LoadingWidget(message: AppStrings.loading),
        (false, true) => const EmptyState(
            icon: Icons.people_outline,
            message: 'No students on this run yet.',
          ),
        (false, false) => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _students.length,
            separatorBuilder: (_, _) => const Divider(indent: 72),
            itemBuilder: (context, i) => _StudentTile(
              student: _students[i],
              onTap: () => _cycleStatus(_students[i]),
            ),
          ),
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  Color get _statusColor => switch (student.status) {
        StudentStatus.onboard => AppColors.onboard,
        StudentStatus.waiting => AppColors.waiting,
        StudentStatus.droppedOff => AppColors.info,
        StudentStatus.absent => AppColors.absent,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(child: Text(student.name.initials)),
      title: Text(student.name),
      subtitle: Text(student.grade),
      trailing: Chip(
        label: Text(student.status.label),
        labelStyle: TextStyle(color: _statusColor, fontSize: 12),
        side: BorderSide(color: _statusColor.withValues(alpha: 0.4)),
        backgroundColor: _statusColor.withValues(alpha: 0.08),
        visualDensity: VisualDensity.compact,
      ),
      onTap: onTap,
    );
  }
}
