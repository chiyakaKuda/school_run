import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/api_service.dart';
import '../../core/services/students_repository.dart';
import '../../models/student.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../utils/extensions.dart';

/// Manifest for a run. Tapping a student cycles them through the statuses.
class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key, this.tripId});

  final String? tripId;

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final StudentsRepository _repo = StudentsRepository.instance;

  List<Student> _students = const [];
  bool _loading = true;
  String? _error;

  int get _onboard =>
      _students.where((s) => s.status == StudentStatus.onboard).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Scoped to this run's manifest — without tripId this would return
      // every student across every trip this driver has ever run.
      final students = await _repo.list(tripId: widget.tripId);
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _cycleStatus(Student student) async {
    final tripId = widget.tripId;
    if (tripId == null) return;

    final next = switch (student.status) {
      StudentStatus.waiting => StudentStatus.onboard,
      StudentStatus.onboard => StudentStatus.droppedOff,
      StudentStatus.droppedOff || StudentStatus.absent => StudentStatus.waiting,
    };

    final i = _students.indexOf(student);
    if (i == -1) return;

    // Optimistic — a driver working down a manifest of twelve children needs
    // each tap to feel instant, not wait on a round trip.
    setState(() => _students[i] = student.copyWith(status: next));

    try {
      await _repo.updateStatus(
        studentId: student.id,
        status: next,
        tripId: tripId,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _students[i] = student);
      context.showSnack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const Text(AppStrings.students),
      ),
      body: switch ((_loading, _error, _students.isEmpty)) {
        (true, _, _) => const LoadingWidget(message: AppStrings.loading),
        (false, String message, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            message: message,
            onRetry: _load,
          ),
        (false, null, true) => const EmptyState(
            icon: Icons.people_outline_rounded,
            message: 'No students on this run yet.',
          ),
        (false, null, false) => RefreshIndicator(
            onRefresh: _load,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        '$_onboard of ${_students.length} on board',
                        style: context.text.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to update',
                        style: context.text.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _StudentTile(
                      student: _students[i],
                      onTap: () => _cycleStatus(_students[i]),
                    ),
                  ),
                ),
              ],
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
    final onboard = student.status == StudentStatus.onboard;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onboard ? AppColors.accentContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: onboard ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceVariant,
              child: Text(student.name.initials, style: context.text.labelLarge),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    student.grade,
                    style: context.text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                student.status.label,
                style: context.text.labelSmall?.copyWith(color: _statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
