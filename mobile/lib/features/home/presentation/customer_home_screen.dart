import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/app_mode_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/data/job_models.dart';
import '../../jobs/providers/active_job_provider.dart';
import '../data/home_repository.dart';
import '../providers/home_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final techniciansAsync = ref.watch(availableTechniciansProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authStateProvider);
    final activeJob = ref.watch(activeJobProvider);
    final mode = ref.watch(appModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-job'),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Post Job'),
      ),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wedapola', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('වැඩකට කෙනෙක් • කෙනෙකුට වැඩක්', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate_rounded),
            initialValue: mode.language,
            onSelected: (lang) => ref.read(appModeProvider.notifier).setLanguage(lang),
            itemBuilder: (_) => AppLanguage.values
                .map((l) => PopupMenuItem(value: l, child: Text(l.label)))
                .toList(),
          ),
          TextButton.icon(
            onPressed: () => ref.read(appModeProvider.notifier).toggleRole(),
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            label: const Text('Worker Mode', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          IconButton(
            tooltip: authState is AuthAuthenticated ? 'Sign Out' : 'Sign In',
            icon: Icon(authState is AuthAuthenticated ? Icons.logout_rounded : Icons.login_rounded),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(availableTechniciansProvider);
        },
        child: CustomScrollView(
          slivers: [
            if (activeJob != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    color: const Color(0xFFE3F2FD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.engineering_rounded, color: Color(0xFF0066FF)),
                      title: Text('Active Job #${activeJob.id} • ${activeJob.status.label}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(activeJob.categoryName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/active-job'),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search plumber, electrician, AC repair...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).setQuery('');
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => setState(() {}),
                      onSubmitted: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: categoriesAsync.when(
                        data: (cats) => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cats.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected = selectedCat == null;
                              return ChoiceChip(
                                label: const Text('All Services'),
                                selected: isSelected,
                                onSelected: (_) => ref.read(selectedCategoryProvider.notifier).select(null),
                              );
                            }
                            final cat = cats[index - 1];
                            final isSelected = selectedCat == cat.id;
                            return ChoiceChip(
                              label: Text(cat.nameEn),
                              selected: isSelected,
                              onSelected: (_) {
                                ref.read(selectedCategoryProvider.notifier).select(isSelected ? null : cat.id);
                              },
                            );
                          },
                        ),
                        loading: () => const Center(child: LinearProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: techniciansAsync.when(
                data: (workers) {
                  if (workers.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.engineering_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No available workers found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Try clearing your search or selecting another category.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _WorkerCard(
                      worker: workers[index],
                      onInquire: () => _openInquirySheet(context, workers[index], selectedCat),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error loading workers: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInquirySheet(BuildContext context, TechnicianItem worker, int? categoryId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Quote from ${worker.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Your Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number (+94...)')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Describe the job')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }
                        setModalState(() => submitting = true);
                        try {
                          await ref.read(homeRepositoryProvider).submitInquiry(
                                customerName: nameCtrl.text.trim(),
                                customerPhone: phoneCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                technicianId: worker.id,
                                categoryId: categoryId,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Inquiry sent! The worker will contact you shortly.')),
                            );
                          }
                        } catch (e) {
                          setModalState(() => submitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to send inquiry: $e')),
                            );
                          }
                        }
                      },
                child: submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final TechnicianItem worker;
  final VoidCallback onInquire;

  const _WorkerCard({required this.worker, required this.onInquire});

  @override
  Widget build(BuildContext context) {
    final badgeColor = worker.verificationStatus == 'PRO'
        ? Colors.green
        : worker.verificationStatus == 'TRUSTED'
            ? const Color(0xFF0066FF)
            : Colors.orange;
    final badgeLabel = worker.verificationStatus == 'PRO'
        ? 'PRO VERIFIED'
        : worker.verificationStatus == 'TRUSTED'
            ? 'TRUSTED'
            : 'VERIFIED';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0066FF)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                          if (worker.distance != null)
                            Text('${worker.distance!.toStringAsFixed(1)} km away',
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 2),
                        Text(worker.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('${worker.completedJobsCount} jobs', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            if (worker.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(worker.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 13)),
            ],
            if (worker.categoryNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: worker.categoryNames
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text(c, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: worker.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied ${worker.phone} to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    label: Text(worker.phone.isNotEmpty ? worker.phone : 'Contact', overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 42)),
                    onPressed: onInquire,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Request Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
