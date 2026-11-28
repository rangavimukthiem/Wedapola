import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/app_mode_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobs/data/job_models.dart';
import '../../jobs/providers/active_job_provider.dart';

class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final leads = ref.watch(workerLeadsProvider);
    final activeJob = ref.watch(activeJobProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wedapola Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
            Text('Job Radar & Active Jobs', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(appModeProvider.notifier).toggleRole(),
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            label: const Text('Client Mode', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Availability & KYC Card
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(mode.workerAvailable ? 'Receiving nearby FCM & WhatsApp leads' : 'Paused — hidden from search'),
                    value: mode.workerAvailable,
                    onChanged: (v) => ref.read(appModeProvider.notifier).toggleWorkerAvailability(v),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 6),
                          Text('KYC: ${mode.workerKycStatus}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push('/worker-kyc'),
                        child: const Text('Upgrade KYC →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (activeJob != null) ...[
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFE3F2FD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const Icon(Icons.work_rounded, color: Color(0xFF0066FF)),
                title: Text('Active Job #${activeJob.id} • ${activeJob.status.label}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${activeJob.categoryName} • ${activeJob.locationLabel}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/active-job'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Nearby Job Radar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...leads.map((lead) => Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lead.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Chip(label: Text('${lead.distanceKm} km'), visualDensity: VisualDensity.compact),
                        ],
                      ),
                      Text(lead.areaName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(lead.description, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (lead.nearHazard)
                            const Chip(
                              backgroundColor: Color(0xFFFFEBEE),
                              label: Text('⚠️ Hazard Flag', style: TextStyle(fontSize: 11, color: Colors.red)),
                              visualDensity: VisualDensity.compact,
                            ),
                          Chip(
                            label: Text(lead.equipmentProvided ? '🧰 Tools on site' : 'Bring own tools', style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 42),
                          backgroundColor: lead.quoteSubmitted ? Colors.green : null,
                        ),
                        onPressed: lead.quoteSubmitted
                            ? null
                            : () => _openQuoteDialog(context, ref, lead),
                        child: Text(lead.quoteSubmitted ? '✓ Quote Sent' : 'Send Price Quote + ETA'),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _openQuoteDialog(BuildContext context, WidgetRef ref, OpenJobLead lead) {
    final priceCtrl = TextEditingController(text: '2500');
    final etaCtrl = TextEditingController(text: '30 mins');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quote for #${lead.requestId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimate (LKR)')),
            const SizedBox(height: 10),
            TextField(controller: etaCtrl, decoration: const InputDecoration(labelText: 'Arrival ETA')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
            onPressed: () {
              ref.read(workerLeadsProvider.notifier).markQuoted(lead.requestId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Quote LKR ${priceCtrl.text} sent!')),
              );
            },
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );
  }
}
