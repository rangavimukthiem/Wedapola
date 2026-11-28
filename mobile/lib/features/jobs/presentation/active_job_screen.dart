import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/app_mode_provider.dart';
import '../data/job_models.dart';
import '../providers/active_job_provider.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  final _pinCtrl = TextEditingController();
  int _selectedStars = 5;
  final Set<String> _selectedTags = {'⏱️ On Time • වේලාවට පැමිණියා'};

  static const List<String> _bilingualChips = [
    '⏱️ On Time • වේලාවට පැමිණියා',
    '💰 Fair Price • සාධාරණ මිල',
    '🧹 Neat Work • පිරිසිදු වැඩ',
    '🙏 Polite • විනීතයි',
    '🧰 Proper Tools • නිවැරදි උපකරණ',
  ];

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(activeJobProvider);
    final mode = ref.watch(appModeProvider);
    final isWorker = mode.role == AppRole.worker;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Job')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No active job right now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Job #${job.id} • ${isWorker ? "Worker" : "Client"}'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(appModeProvider.notifier).toggleRole(),
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            label: Text(
              isWorker ? 'Worker Mode' : 'Client Mode',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHeader(job),
          const SizedBox(height: 14),
          _buildDetailsCard(job, isWorker),
          const SizedBox(height: 14),
          _buildStageBody(context, job, isWorker),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ActiveJob job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF0284C7)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.status.label.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(job.categoryName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: const Text('Offline Cached', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ActiveJob job, bool isWorker) {
    final contactName = isWorker ? job.clientName : (job.workerName ?? 'Awaiting Worker');
    final contactPhone = isWorker ? job.clientPhone : (job.workerPhone ?? '');

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(avatar: const Icon(Icons.location_on_outlined, size: 16), label: Text(job.locationLabel)),
                if (job.equipmentProvided) const Chip(label: Text('🧰 Equipment Provided')),
                if (job.nearHazard)
                  const Chip(
                    backgroundColor: Color(0xFFFFEBEE),
                    label: Text('⚠️ Near Power/Roof Hazard', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            if (job.status.index >= JobStatus.accepted.index && contactPhone.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(contactPhone, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Copy Phone / Call',
                    icon: const Icon(Icons.call_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: contactPhone));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied $contactPhone')));
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    tooltip: 'WhatsApp',
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: 'https://wa.me/${contactPhone.replaceAll("+", "")}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp link copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageBody(BuildContext context, ActiveJob job, bool isWorker) {
    final notifier = ref.read(activeJobProvider.notifier);

    switch (job.status) {
      case JobStatus.openForQuotes:
        if (isWorker) {
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Client is comparing quotes for this job.', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => notifier.acceptQuote(job.quotes.first),
                    child: const Text('Simulate Client Accepting Quote'),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Incoming Quotes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...job.quotes.map((q) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(q.technicianName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('LKR ${q.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0066FF))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('★ ${q.rating} • ${q.kycBadge} • ETA: ${q.etaText}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text(q.notes, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 42)),
                          onPressed: () => notifier.acceptQuote(q),
                          child: const Text('Accept Quote'),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );

      case JobStatus.accepted:
      case JobStatus.onTheWay:
      case JobStatus.arrived:
        if (!isWorker) {
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Share this 4-Digit Start PIN when worker arrives', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.startPin,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF0066FF)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job.status == JobStatus.accepted)
                  ElevatedButton.icon(
                    onPressed: () => notifier.markOnTheWay(),
                    icon: const Icon(Icons.directions_run_rounded),
                    label: const Text('Tap "On My Way"'),
                  ),
                if (job.status == JobStatus.onTheWay)
                  ElevatedButton.icon(
                    onPressed: () => notifier.markArrived(),
                    icon: const Icon(Icons.place_rounded),
                    label: const Text('Tap "Arrived at Site"'),
                  ),
                if (job.status == JobStatus.arrived) ...[
                  const Text('Enter Client 4-Digit Start PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(hintText: '4-digit PIN (e.g. from Client screen)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await notifier.verifyPinAndStart(_pinCtrl.text);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid PIN. Ask client for 4-digit PIN (${job.startPin})')),
                        );
                      }
                    },
                    child: const Text('Verify PIN & Start Official Timer'),
                  ),
                ],
              ],
            ),
          ),
        );

      case JobStatus.inProgress:
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Work In Progress (Started ${job.startedAt != null ? "${job.startedAt!.hour}:${job.startedAt!.minute.toString().padLeft(2, "0")}" : "now"})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Agreed Base Quote: LKR ${job.baseQuoteTotal.toStringAsFixed(0)}'),
                Text('Approved Extras: LKR ${job.approvedExtraCost.toStringAsFixed(0)}'),
                if (job.pendingExtraCost > 0 && !isWorker) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extra Material Request: LKR ${job.pendingExtraCost.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(job.pendingExtraReason ?? 'Additional parts needed'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => notifier.approveExtraCost(false),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => notifier.approveExtraCost(true),
                                child: const Text('Approve Extra'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (isWorker) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => notifier.requestExtraCost(850, 'Replacement capacitor / wiring fuse'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Request Extra Parts Cost (+LKR 850)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => notifier.markAfterPhotoAndComplete(),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Upload After-Work Photo & Mark Completed'),
                  ),
                ],
              ],
            ),
          ),
        );

      case JobStatus.pendingPayment:
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Final Bill Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total Payable: LKR ${job.finalBillTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0066FF))),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => notifier.confirmPayment(),
                  icon: const Icon(Icons.payments_rounded),
                  label: Text(isWorker ? 'Confirm Cash / LankaQR Received' : 'Pay Cash or LankaQR & Confirm'),
                ),
              ],
            ),
          ),
        );

      case JobStatus.completed:
      case JobStatus.reviewed:
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWorker ? 'Rate Client (2-Way Feedback)' : '15-Second Rating & Behavior Tags',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setState(() => _selectedStars = i + 1),
                    ),
                  ),
                ),
                if (!isWorker) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _bilingualChips.map((chip) {
                      final active = _selectedTags.contains(chip);
                      return FilterChip(
                        label: Text(chip, style: const TextStyle(fontSize: 12)),
                        selected: active,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedTags.add(chip);
                          } else {
                            _selectedTags.remove(chip);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await notifier.submitReview(isClient: !isWorker);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Review saved.')),
                      );
                    }
                  },
                  child: const Text('Submit Rating'),
                ),
                if (job.status == JobStatus.reviewed) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await notifier.clearJob();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Done • Rebook / Back to Home'),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }
}
