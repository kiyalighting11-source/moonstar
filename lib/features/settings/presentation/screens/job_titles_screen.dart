// lib/features/settings/presentation/screens/job_titles_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../employees/data/models/job_title_model.dart';
import '../../../employees/data/providers/employees_provider.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';

// =====================================================
// Providers
// =====================================================
final _jobTitlesControllerProvider =
    StateNotifierProvider<_JobTitlesController, AsyncValue<void>>((ref) {
  return _JobTitlesController(ref);
});

class _JobTitlesController extends StateNotifier<AsyncValue<void>> {
  _JobTitlesController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> createJobTitle(String name, String? description) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(employeesRepositoryProvider).createJobTitle(
            JobTitleModel(
              id: '',
              name: name,
              description: description,
            ),
          );
      state = const AsyncValue.data(null);
      _ref.invalidate(jobTitlesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// =====================================================
// Screen
// =====================================================
class JobTitlesScreen extends ConsumerWidget {
  const JobTitlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobTitlesAsync = ref.watch(jobTitlesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: DashboardAppBar(
        title: 'الوظائف',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(jobTitlesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('وظيفة جديدة'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: jobTitlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'خطأ: $e',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
          ),
        ),
        data: (jobTitles) {
          if (jobTitles.isEmpty) {
            return _buildEmpty(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobTitlesProvider);
              await ref.read(jobTitlesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: jobTitles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final job = jobTitles[i];
                return _jobTitleTile(context, ref, job, i + 1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _jobTitleTile(
    BuildContext context,
    WidgetRef ref,
    JobTitleModel job,
    int index,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A23) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor(context),
                  ),
                ),
                if (job.description != null && job.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    job.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'نشط',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_outline,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مفيش وظائف لسه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط + لإضافة وظيفة جديدة',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF151A23) : Colors.white,
        title: const Text('وظيفة جديدة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم الوظيفة *',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final success = await ref
                  .read(_jobTitlesControllerProvider.notifier)
                  .createJobTitle(
                    nameController.text.trim(),
                    descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (success) {
                Helpers.showSuccess(context, 'تمت الإضافة ✅');
              } else {
                Helpers.showError(context, 'فشل الإضافة');
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
